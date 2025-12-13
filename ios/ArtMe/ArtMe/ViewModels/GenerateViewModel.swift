//
//  GenerateViewModel.swift
//  ArtMe
//
//  图像生成视图模型
//

import Foundation
import SwiftUI
import Combine

@MainActor
class GenerateViewModel: ObservableObject {
    @Published var selectedStyle: Style?
    @Published var generatedImage: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var taskId: String?
    /// 当前任务是否需要在完成时通知用户
    @Published var notifyOnComplete: Bool = false
    @Published var currentStatus: String?
    
    // 图片上传相关属性
    @Published var selectedPromptStyle: PromptStyle?
    @Published var uploadedImage: UIImage?
    @Published var generatedImages: [GeneratedImage] = []
    
    private let apiService = APIService.shared
    private let imageService = ImageService.shared

    /// 当前登录用户 ID（用于扣积分）
    private var currentUserId: String? {
        UserDefaults.standard.string(forKey: "userId")
    }
    
    /// 写入一条「制作中」历史记录
    /// - Parameters:
    ///   - taskId: 任务 ID
    ///   - prompt: 文案
    ///   - style: 选择的风格（目前未使用）
    ///   - imageUrl: 关联的缩略图 URL（优先使用服务端返回的上传预览图）
    private func addPendingHistory(taskId: String, prompt: String, style: Style?, imageUrl: String?) {
        let historyItem = GeneratedImageHistory(
            id: taskId,
            prompt: prompt,
            styleId: style?.id,
            styleName: style?.name,
            imageUrl: imageUrl,
            status: "pending",
            createdAt: Date(),
            error: nil,
            notifyOnComplete: notifyOnComplete
        )
        HistoryManager().upsertHistory(historyItem)
    }
    
    func saveImage() async {
        guard let image = generatedImage else { return }
        
        do {
            try await imageService.saveToPhotoLibrary(image)
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
        }
    }
    
    func shareImage() {
        // 分享功能在视图中实现
    }
    
    // MARK: - 图片上传生成
    
    func selectImage(_ image: UIImage) {
        uploadedImage = image
    }
    
    func generateImageWithUpload() async {
        guard let uploadedImage = uploadedImage else {
            errorMessage = "请先选择图片"
            return
        }
        
        guard let promptStyle = selectedPromptStyle else {
            errorMessage = "请先选择风格"
            return
        }

        // 未登录时自动创建游客账号，避免“无入口登录导致主功能不可用”
        let userId: String
        do {
            userId = try await SessionManager.ensureGuestUser()
        } catch {
            errorMessage = "创建游客账号失败: \(error.localizedDescription)"
            return
        }
        
        isLoading = true
        errorMessage = nil
        generatedImages = []
        currentStatus = nil
        
        do {
            let request = GenerateImageWithUploadRequest(
                image: uploadedImage,
                category: promptStyle.category,
                subcategory: promptStyle.subcategory,
                userId: userId,
                size: "2K",
                watermark: true,
                maxImages: 5,
                notifyOnComplete: notifyOnComplete
            )
            
            let response = try await apiService.generateImageWithUpload(request: request)
            
            if response.success {
                taskId = response.taskId
                // 统一由 TaskStatusManager 负责后续轮询与状态更新，这里只负责写入一条「pending」历史记录，
                // 并记录当前接口返回的初始状态，供当前页面展示「制作中」文案。
                // 此处优先使用服务端返回的 images.first?.url 作为「制作中」阶段的缩略图，
                // 这样全局顶部 Toast 在 pending 状态时就能展示用户上传的预览图，而不是默认对号图标。
                let pendingThumbnailUrl = response.images.first?.url
                addPendingHistory(taskId: response.taskId, prompt: response.prompt, style: nil, imageUrl: pendingThumbnailUrl)
                currentStatus = response.status
            
                if response.status == "completed", !response.images.isEmpty {
                    // 极短任务：服务端已直接返回完成结果，仍在本页直接展示生成列表，并同步更新历史为 completed。
                    await handleCompletedList(images: response.images)
                    HistoryManager().updateHistoryStatus(
                        id: response.taskId,
                        status: "completed",
                        imageUrl: response.images.first?.url,
                        error: nil
                    )
                }
                // 其他情况（pending / processing）：不再在本地单独轮询，
                // 由 TaskStatusManager 统一轮询所有 pending 任务并触发 Toast。
            } else {
                errorMessage = response.error ?? "生成失败"
            }
        } catch {
            errorMessage = "生成失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// 当外部（例如全局 TaskStatusManager）检测到某个任务已完成时，
    /// 如果该任务正好是当前页面创建的任务，则在本页刷新展示生成结果。
    func refreshResultIfNeeded(for taskId: String) async {
        // 只处理当前页面发起的任务
        guard taskId == self.taskId else {
            return
        }
        
        do {
            let statusResponse = try await apiService.fetchTaskStatus(taskId: taskId)
            self.currentStatus = statusResponse.status
            
            // 只有在任务真正完成且返回了图片列表时，才在本页展示结果
            guard statusResponse.status == "completed",
                  !statusResponse.imageUrls.isEmpty else {
                return
            }
            
            // 将任务状态接口返回的图片 URL 列表，转换为用于当前视图展示的 GeneratedImage 列表
            let images: [GeneratedImage] = statusResponse.imageUrls.enumerated().map { index, url in
                GeneratedImage(id: "\(taskId)_\(index)", url: url)
            }
            
            await handleCompletedList(images: images)
        } catch {
            // 如果拉取结果失败，不覆盖已有错误信息，避免打扰正在生成的流程
            if self.errorMessage == nil {
                self.errorMessage = "获取任务结果失败: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - 任务完成处理（仅用于「立即完成」场景在本页展示结果）
    
    private func handleCompletedList(images: [GeneratedImage]) async {
        await MainActor.run {
            self.generatedImages = images
        }
    }
}

