//
//  GenerateImage.swift
//  ArtMe
//
//  图像生成相关模型
//

import Foundation

// MARK: - 生成请求

struct GenerateImageRequest: Codable {
    let prompt: String
    let styleId: String?
    let userId: String?
    let width: Int
    let height: Int
    let model: String
    
    init(
        prompt: String,
        styleId: String? = nil,
        userId: String? = nil,
        width: Int = 512,
        height: Int = 512,
        model: String = "dall-e-3"
    ) {
        self.prompt = prompt
        self.styleId = styleId
        self.userId = userId
        self.width = width
        self.height = height
        self.model = model
    }
}

// MARK: - 生成响应

struct GenerateImageResponse: Codable {
    let imageUrl: String
    let taskId: String
    let status: String
    let prompt: String
}

// MARK: - 模型列表

struct ModelListResponse: Codable {
    let models: [AIModel]
}

struct AIModel: Codable, Identifiable {
    let id: String
    let name: String
    let status: String
}

