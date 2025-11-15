//
//  PromptStyleViewModel.swift
//  ArtMe
//
//  Prompt 风格视图模型
//

import Foundation
import SwiftUI
import Combine

@MainActor
class PromptStyleViewModel: ObservableObject {
    @Published var promptStyles: [PromptStyle] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    // 缓存键
    private let cacheKey = "PromptStylesCache"
    private let versionKey = "PromptStylesVersion"
    
    // 按 Category 分组的样式
    var groupedStyles: [String: [PromptStyle]] {
        Dictionary(grouping: promptStyles) { $0.category }
    }
    
    // 所有 Category 列表
    var categories: [String] {
        Array(Set(promptStyles.map { $0.category })).sorted()
    }
    
    init() {
        // 从缓存加载数据
        loadCachedData()
    }
    
    // 从缓存加载数据
    private func loadCachedData() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cachedResponse = try? JSONDecoder().decode(PromptStyleListResponse.self, from: data) {
            print("📦 从缓存加载数据，共 \(cachedResponse.prompts.count) 个样式")
            promptStyles = cachedResponse.prompts
        }
    }
    
    // 保存数据到缓存
    private func saveToCache(_ response: PromptStyleListResponse) {
        if let data = try? JSONEncoder().encode(response) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            if let version = response.version {
                UserDefaults.standard.set(version, forKey: versionKey)
            }
            print("💾 数据已缓存，版本: \(response.version ?? "未知")")
        }
    }
    
    // 获取缓存的版本号
    private func getCachedVersion() -> String? {
        return UserDefaults.standard.string(forKey: versionKey)
    }
    
    // 检查是否有更新
    func checkForUpdates() async -> Bool {
        do {
            let versionResponse = try await apiService.fetchPromptStylesVersion()
            let serverVersion = versionResponse.version
            let cachedVersion = getCachedVersion()
            
            print("🔍 版本检查: 缓存版本=\(cachedVersion ?? "无"), 服务器版本=\(serverVersion)")
            
            // 如果缓存版本和服务器版本不同，说明有更新
            if let cached = cachedVersion, cached == serverVersion {
                print("✅ 数据是最新的，无需更新")
                return false
            } else {
                print("🔄 检测到更新，需要重新加载")
                return true
            }
        } catch {
            print("⚠️ 版本检查失败: \(error.localizedDescription)")
            // 如果版本检查失败，默认返回 true 以尝试加载数据
            return true
        }
    }
    
    // 加载数据（会检查版本，有更新才重新加载）
    func loadPromptStyles() async {
        print("🚀 开始加载图片列表...")
        
        // 如果已有缓存数据，先检查版本
        if !promptStyles.isEmpty {
            let hasUpdate = await checkForUpdates()
            
            // 如果没有更新，直接返回，使用缓存数据
            if !hasUpdate {
                print("✅ 使用缓存数据，无需重新加载")
                return
            }
        }
        
        // 如果有更新或没有缓存，重新加载
        isLoading = true
        errorMessage = nil
        
        print("📡 API Base URL: \(apiService.baseURL)")
        print("📡 Full URL: \(apiService.baseURL)/api/v1/prompts/list")
        
        do {
            let response = try await apiService.fetchPromptStyles()
            print("✅ 加载成功，共 \(response.prompts.count) 个样式")
            promptStyles = response.prompts
            
            // 保存到缓存
            saveToCache(response)
        } catch let error as APIError {
            // 使用 APIError 的友好错误描述
            let errorDesc = error.localizedDescription ?? "未知错误"
            print("❌ 加载失败: \(errorDesc)")
            
            // 如果加载失败，但有缓存数据，使用缓存数据
            if promptStyles.isEmpty {
                errorMessage = "加载图片列表失败: \(errorDesc)"
            } else {
                print("⚠️ 加载失败，但使用缓存数据")
                // 不设置错误信息，使用缓存数据
            }
        } catch {
            // 处理其他类型的错误
            print("❌ 加载失败: \(error.localizedDescription)")
            
            // 如果加载失败，但有缓存数据，使用缓存数据
            if promptStyles.isEmpty {
                errorMessage = "加载图片列表失败: \(error.localizedDescription)"
            } else {
                print("⚠️ 加载失败，但使用缓存数据")
                // 不设置错误信息，使用缓存数据
            }
        }
        
        isLoading = false
        print("🏁 加载完成")
    }
    
    // 按 Category 分组
    func groupByCategory() -> [String: [PromptStyle]] {
        return groupedStyles
    }
    
    // 获取指定 Category 的样式列表
    func getStyles(forCategory category: String) -> [PromptStyle] {
        return promptStyles.filter { $0.category == category }
    }
    
    // 根据 ID 查找样式
    func getStyle(byId id: String) -> PromptStyle? {
        return promptStyles.first { $0.id == id }
    }
    
    // 根据 category 和 subcategory 查找样式
    func getStyle(category: String, subcategory: String) -> PromptStyle? {
        return promptStyles.first { 
            $0.category == category && $0.subcategory == subcategory 
        }
    }
}

