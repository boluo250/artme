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
        let t0 = Date()
        StartupProfiler.mark("ImageService.init 开始（图片缓存服务初始化）")
        // 配置缓存
        cache.countLimit = 50
        cache.totalCostLimit = Constants.imageCacheSize
        
        // 获取文档目录
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ArtMe", isDirectory: true)
        
        // 创建目录
        try? fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
        let t1 = Date()
        let cost = String(format: "%.3f", t1.timeIntervalSince(t0))
        Log.info("⏱ [Startup] ImageService.init 磁盘目录准备耗时 \(cost)s，目录 = \(documentsDirectory.path)")
        StartupProfiler.mark("ImageService.init 完成（图片缓存服务就绪）")
    }
    
    // 设置图片缓存版本（用于强制刷新缩略图等资源）
    func setCacheBuster(_ version: String?) {
        // 如果版本变化，清空内存缓存，避免旧图占用内存
        if cacheBuster != version {
            cache.removeAllObjects()
            // 强制清理旧的磁盘缓存（简单策略：直接清空目录，或者根据版本号迁移）
            // 这里为了解决 GIF 切换问题，我们暂时在版本变化时清理所有缓存文件
            try? fileManager.removeItem(at: documentsDirectory)
            try? fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
        }
        cacheBuster = version
    }
    
    // MARK: - 下载图像
    
    private func getCacheKey(_ urlString: String) -> String {
        guard let v = cacheBuster, !v.isEmpty else { return urlString }
        let encoded = v.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? v
        let sep = urlString.contains("?") ? "&" : "?"
        return urlString + "\(sep)v=\(encoded)"
    }
    
    func downloadImage(from urlString: String) async throws -> UIImage {
        let cacheKey = getCacheKey(urlString)
        let requestURLString = urlString
        
        // 检查缓存（内存）
        if let cachedImage = cache.object(forKey: cacheKey as NSString) {
            return cachedImage
        }
        
        // 检查本地文件
        if let localData = loadLocalData(urlString: cacheKey), let localImage = UIImage(data: localData) {
            cache.setObject(localImage, forKey: cacheKey as NSString)
            return localImage
        }
        
        // 下载图像（忽略 URLCache，避免拿到旧图）
        let data = try await downloadData(url: requestURLString)
        
        guard let image = UIImage(data: data) else {
            throw NSError(domain: "ImageService", code: -2, userInfo: [NSLocalizedDescriptionKey: "无法解析图像数据"])
        }
        
        // 保存到缓存和本地（保存原始数据）
        cache.setObject(image, forKey: cacheKey as NSString)
        saveLocalData(data: data, urlString: cacheKey)
        
        return image
    }
    
    func downloadImageData(from urlString: String) async throws -> Data {
        let cacheKey = getCacheKey(urlString)
        
        // 检查本地文件
        if let localData = loadLocalData(urlString: cacheKey) {
            return localData
        }
        
        // 下载
        let data = try await downloadData(url: urlString)
        
        // 保存
        saveLocalData(data: data, urlString: cacheKey)
        
        return data
    }
    
    private func downloadData(url urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "ImageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])
        }
        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: Constants.requestTimeout)
        req.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw NSError(domain: "ImageService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"])
        }
        return data
    }
    
    // MARK: - 本地存储
    
    private func getFileName(_ urlString: String) -> String {
        return urlString
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "?", with: "_")
            .replacingOccurrences(of: "&", with: "_")
            .replacingOccurrences(of: "=", with: "_")
    }
    
    private func saveLocalData(data: Data, urlString: String) {
        let fileName = getFileName(urlString)
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        try? data.write(to: fileURL)
    }
    
    private func loadLocalData(urlString: String) -> Data? {
        let fileName = getFileName(urlString)
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        return try? Data(contentsOf: fileURL)
    }
    
    private func saveLocalImage(image: UIImage, urlString: String) {
        // 保留此方法以兼容旧代码（虽然不再建议使用）
        if let data = image.jpegData(compressionQuality: 0.8) {
            saveLocalData(data: data, urlString: urlString)
        }
    }
    
    private func loadLocalImage(urlString: String) -> UIImage? {
        guard let data = loadLocalData(urlString: urlString) else { return nil }
        return UIImage(data: data)
    }
    
    // MARK: - 保存到相册
    
    func saveToPhotoLibrary(_ image: UIImage) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
}
