//
//  PromptStyle.swift
//  ArtMe
//
//  Prompt 风格模型
//

import Foundation
import UIKit

struct PromptStyle: Codable, Identifiable {
    let id: String
    let category: String
    let categoryId: Int
    let subcategory: String
    let subcategoryId: Int
    let prompt: String
    let thumbnailUrl: String
    let originalUrl: String
}

struct PromptStyleListResponse: Codable {
    let prompts: [PromptStyle]
    let total: Int
    let version: String?  // 数据版本号
}

struct PromptStyleVersionResponse: Codable {
    let version: String
}

// MARK: - 图片上传生成请求

struct GenerateImageWithUploadRequest {
    let image: UIImage
    let category: String
    let subcategory: String
    let userId: String?
    let size: String?
    let watermark: Bool?
    let maxImages: Int?
    
    init(
        image: UIImage,
        category: String,
        subcategory: String,
        userId: String? = nil,
        size: String? = "2K",
        watermark: Bool? = true,
        maxImages: Int? = 5
    ) {
        self.image = image
        self.category = category
        self.subcategory = subcategory
        self.userId = userId
        self.size = size
        self.watermark = watermark
        self.maxImages = maxImages
    }
}

// MARK: - 图片上传生成响应

struct GenerateImageWithUploadResponse: Codable {
    let success: Bool
    let images: [GeneratedImage]
    let taskId: String
    let prompt: String
    let usage: Usage?
    let error: String?
}

struct GeneratedImage: Codable, Identifiable {
    let id: String
    let url: String
}

struct Usage: Codable {
    // 根据豆包 API 的实际返回结构定义
    // 这里暂时留空，根据实际 API 响应添加字段
}

