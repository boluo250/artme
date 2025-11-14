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
    @Published var prompt = ""
    @Published var selectedStyle: Style?
    @Published var generatedImage: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var taskId: String?
    
    // 图片上传相关属性
    @Published var selectedPromptStyle: PromptStyle?
    @Published var uploadedImage: UIImage?
    @Published var generatedImages: [GeneratedImage] = []
    
    private let apiService = APIService.shared
    private let imageService = ImageService.shared
    
    func generateImage() async {
        guard !prompt.isEmpty else {
            errorMessage = "请输入描述文本"
            return
        }
        
        isLoading = true
        errorMessage = nil
        generatedImage = nil
        
        do {
            let request = GenerateImageRequest(
                prompt: prompt,
                styleId: selectedStyle?.id,
                width: 512,
                height: 512
            )
            
            let response = try await apiService.generateImage(request: request)
            taskId = response.taskId
            
            // 构建完整URL
            let fullImageURL = Constants.apiBaseURL + response.imageUrl
            
            // 下载图像
            let image = try await imageService.downloadImage(from: fullImageURL)
            generatedImage = image
            
            // 保存到历史记录
            saveToHistory(response: response, image: image)
            
        } catch {
            errorMessage = "生成失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func saveToHistory(response: GenerateImageResponse, image: UIImage) {
        let historyItem = GeneratedImageHistory(
            id: response.taskId,
            prompt: prompt,
            styleId: selectedStyle?.id,
            styleName: selectedStyle?.name,
            imageUrl: response.imageUrl,
            createdAt: Date()
        )
        
        let historyManager = HistoryManager()
        historyManager.addHistory(historyItem)
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
        
        do {
            let request = GenerateImageWithUploadRequest(
                image: uploadedImage,
                category: promptStyle.category,
                subcategory: promptStyle.subcategory
            )
            
            let response = try await apiService.generateImageWithUpload(request: request)
            
            if response.success {
                generatedImages = response.images
                taskId = response.taskId
            } else {
                errorMessage = response.error ?? "生成失败"
            }
        } catch {
            errorMessage = "生成失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

