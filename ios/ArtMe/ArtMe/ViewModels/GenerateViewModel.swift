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
    
    private func addPendingHistory(taskId: String, prompt: String, style: Style?) {
        let historyItem = GeneratedImageHistory(
            id: taskId,
            prompt: prompt,
            styleId: style?.id,
            styleName: style?.name,
            imageUrl: nil,
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
        
        isLoading = true
        errorMessage = nil
        generatedImages = []
        currentStatus = nil
        
        do {
            let request = GenerateImageWithUploadRequest(
                image: uploadedImage,
                category: promptStyle.category,
                subcategory: promptStyle.subcategory,
                userId: nil,
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
                addPendingHistory(taskId: response.taskId, prompt: response.prompt, style: nil)
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
    
    // MARK: - 任务完成处理（仅用于「立即完成」场景在本页展示结果）
    
    private func handleCompletedList(images: [GeneratedImage]) async {
        await MainActor.run {
            self.generatedImages = images
        }
    }
}

