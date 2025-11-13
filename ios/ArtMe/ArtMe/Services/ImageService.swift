//
//  ImageService.swift
//  ArtMe
//
//  图像服务（下载、缓存、存储）
//

import Foundation
import UIKit
import Photos

class ImageService {
    static let shared = ImageService()
    
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    
    private init() {
        // 配置缓存
        cache.countLimit = 50
        cache.totalCostLimit = Constants.imageCacheSize
        
        // 获取文档目录
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ArtMe", isDirectory: true)
        
        // 创建目录
        try? fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - 下载图像
    
    func downloadImage(from urlString: String) async throws -> UIImage {
        // 检查缓存
        if let cachedImage = cache.object(forKey: urlString as NSString) {
            return cachedImage
        }
        
        // 检查本地文件
        if let localImage = loadLocalImage(urlString: urlString) {
            cache.setObject(localImage, forKey: urlString as NSString)
            return localImage
        }
        
        // 下载图像
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "ImageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let image = UIImage(data: data) else {
            throw NSError(domain: "ImageService", code: -2, userInfo: [NSLocalizedDescriptionKey: "无法解析图像数据"])
        }
        
        // 保存到缓存和本地
        cache.setObject(image, forKey: urlString as NSString)
        saveLocalImage(image: image, urlString: urlString)
        
        return image
    }
    
    // MARK: - 本地存储
    
    private func saveLocalImage(image: UIImage, urlString: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let fileName = urlString.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        try? data.write(to: fileURL)
    }
    
    private func loadLocalImage(urlString: String) -> UIImage? {
        let fileName = urlString.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    // MARK: - 保存到相册
    
    func saveToPhotoLibrary(_ image: UIImage) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
}

