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
            error: nil
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
                notifyOnComplete: false
            )
            
            let response = try await apiService.generateImageWithUpload(request: request)
            
            if response.success {
                taskId = response.taskId
                addPendingHistory(taskId: response.taskId, prompt: response.prompt, style: nil)
                currentStatus = response.status

                if response.status == "completed", !response.images.isEmpty {
                    await handleCompletedList(images: response.images)
                    HistoryManager().updateHistoryStatus(
                        id: response.taskId,
                        status: "completed",
                        imageUrl: response.images.first?.url,
                        error: nil
                    )
                } else {
                    await pollTaskStatus(taskId: response.taskId)
                }
            } else {
                errorMessage = response.error ?? "生成失败"
            }
        } catch {
            errorMessage = "生成失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }

    // MARK: - 任务轮询与完成处理

    private func pollTaskStatus(taskId: String) async {
        currentStatus = "processing"
        while true {
            do {
                let status = try await apiService.fetchTaskStatus(taskId: taskId)
                await MainActor.run {
                    self.currentStatus = status.status
                }
                if status.status == "completed" {
                    // 区分两种模式：
                    // 1）文本生成头像（单图）：使用 generatedImage
                    // 2）上传图片生成（多图）：使用 generatedImages
                    if uploadedImage != nil && selectedPromptStyle != nil {
                        // 上传生成场景：将返回的 URL 数组转换为 GeneratedImage 列表
                        let images: [GeneratedImage] = status.imageUrls.enumerated().map { index, url in
                            GeneratedImage(
                                id: "\(taskId)-\(index)",
                                url: url
                            )
                        }
                        if !images.isEmpty {
                            await handleCompletedList(images: images)
                        } else {
                            // 兜底：如果没有返回列表，仍然尝试按单图处理
                            await handleCompletedTask(imageUrls: status.imageUrls)
                        }
                    } else {
                        // 文本生成头像：保持原有单图逻辑
                        await handleCompletedTask(imageUrls: status.imageUrls)
                    }
                    HistoryManager().updateHistoryStatus(
                        id: taskId,
                        status: "completed",
                        imageUrl: status.imageUrls.first,
                        error: nil
                    )
                    break
                } else if status.status == "failed" {
                    await MainActor.run {
                        self.errorMessage = status.error ?? "生成失败"
                    }
                    HistoryManager().updateHistoryStatus(
                        id: taskId,
                        status: "failed",
                        imageUrl: nil,
                        error: status.error
                    )
                    break
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "查询任务状态失败: \(error.localizedDescription)"
                }
                break
            }

            // 间隔 2s 再查
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }
    }

    private func handleCompletedTask(imageUrls: [String]) async {
        guard let first = imageUrls.first else { return }
        let fullImageURL = first.hasPrefix("http") ? first : Constants.apiBaseURL + first
        do {
            let image = try await imageService.downloadImage(from: fullImageURL)
            await MainActor.run {
                self.generatedImage = image
            }
            HistoryManager().updateHistoryStatus(
                id: taskId ?? UUID().uuidString,
                status: "completed",
                imageUrl: first,
                error: nil
            )
        } catch {
            await MainActor.run {
                self.errorMessage = "下载生成结果失败: \(error.localizedDescription)"
            }
        }
    }

    private func handleCompletedList(images: [GeneratedImage]) async {
        await MainActor.run {
            self.generatedImages = images
        }
    }
}

