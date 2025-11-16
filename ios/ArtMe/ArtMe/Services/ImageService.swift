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
    // 当服务端数据版本更新时用于图片缓存失效的版本号
    private var cacheBuster: String?
    
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
    
    // 设置图片缓存版本（用于强制刷新缩略图等资源）
    func setCacheBuster(_ version: String?) {
        // 如果版本变化，清空内存缓存，避免旧图占用内存
        if cacheBuster != version {
            cache.removeAllObjects()
        }
        cacheBuster = version
    }
    
    // MARK: - 下载图像
    
    func downloadImage(from urlString: String) async throws -> UIImage {
        // 仅用于本地缓存键（内存/磁盘）；实际网络请求仍使用原始 URL，避免后端 404
        let cacheKey: String = {
            guard let v = cacheBuster, !v.isEmpty else { return urlString }
            let encoded = v.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? v
            let sep = urlString.contains("?") ? "&" : "?"
            return urlString + "\(sep)v=\(encoded)"
        }()
        let requestURLString = urlString
        
        // 检查缓存（内存）
        if let cachedImage = cache.object(forKey: cacheKey as NSString) {
            return cachedImage
        }
        
        // 检查本地文件
        if let localImage = loadLocalImage(urlString: cacheKey) {
            cache.setObject(localImage, forKey: cacheKey as NSString)
            return localImage
        }
        
        // 下载图像（忽略 URLCache，避免拿到旧图）
        guard let url = URL(string: requestURLString) else {
            throw NSError(domain: "ImageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])
        }
        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: Constants.requestTimeout)
        req.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw NSError(domain: "ImageService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"])
        }
        
        guard let image = UIImage(data: data) else {
            throw NSError(domain: "ImageService", code: -2, userInfo: [NSLocalizedDescriptionKey: "无法解析图像数据"])
        }
        
        // 保存到缓存和本地
        cache.setObject(image, forKey: cacheKey as NSString)
        saveLocalImage(image: image, urlString: cacheKey)
        
        return image
    }
    
    // MARK: - 本地存储
    
    private func saveLocalImage(image: UIImage, urlString: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let fileName = urlString
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "?", with: "_")
            .replacingOccurrences(of: "&", with: "_")
            .replacingOccurrences(of: "=", with: "_")
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        try? data.write(to: fileURL)
    }
    
    private func loadLocalImage(urlString: String) -> UIImage? {
        let fileName = urlString
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "?", with: "_")
            .replacingOccurrences(of: "&", with: "_")
            .replacingOccurrences(of: "=", with: "_")
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
