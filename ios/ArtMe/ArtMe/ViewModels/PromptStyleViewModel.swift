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
    @Published var appConfig: AppConfig?
    // 当前数据版本（用于触发视图刷新与图片缓存失效）
    @Published var dataVersion: String?
    
    private let apiService = APIService.shared
    
    // 缓存键
    private let cacheKey = "PromptStylesCache"
    private let versionKey = "PromptStylesVersion"
    
    // 用于跟踪当前正在进行的任务，防止重复请求
    private var currentTask: Task<Void, Never>?
    
    // 按 Category 分组的样式（按 categoryId 排序）
    var groupedStyles: [String: [PromptStyle]] {
        Dictionary(grouping: promptStyles) { $0.category }
    }
    
    // 所有 Category 列表（按 categoryId 排序）
    var categories: [String] {
        var categoryMap: [String: Int] = [:]
        for style in promptStyles {
            if categoryMap[style.category] == nil {
                categoryMap[style.category] = style.categoryId
            }
        }
        return categoryMap.sorted { $0.value < $1.value }.map { $0.key }
    }
    
    init() {
        // 从缓存加载数据
        loadCachedData()
    }
    
    // 从缓存加载数据
    private func loadCachedData() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cachedResponse = try? JSONDecoder().decode(PromptStyleListResponse.self, from: data) {
            Log.info("📦 从缓存加载数据，共 \(cachedResponse.prompts.count) 个样式")
            promptStyles = cachedResponse.prompts
            dataVersion = cachedResponse.version
            appConfig = cachedResponse.appConfig
            ImageService.shared.setCacheBuster(cachedResponse.version)
        }
    }
    
    // 保存数据到缓存
    private func saveToCache(_ response: PromptStyleListResponse) {
        if let data = try? JSONEncoder().encode(response) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            if let version = response.version {
                UserDefaults.standard.set(version, forKey: versionKey)
            }
            Log.info("💾 数据已缓存，版本: \(response.version ?? "未知")")
            dataVersion = response.version
            appConfig = response.appConfig
            ImageService.shared.setCacheBuster(response.version)
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
            
            Log.debug("🔍 版本检查: 缓存版本=\(cachedVersion ?? "无"), 服务器版本=\(serverVersion)")
            
            // 如果没有缓存版本，说明需要加载
            guard let cached = cachedVersion else {
                Log.info("📝 没有缓存版本，需要加载数据")
                return true
            }
            
            // 如果缓存版本和服务器版本不同，说明有更新
            if cached == serverVersion {
                Log.info("✅ 数据是最新的，无需更新 (版本: \(cached))")
                return false
            } else {
                Log.info("🔄 检测到更新！缓存版本=\(cached), 服务器版本=\(serverVersion)")
                return true
            }
        } catch {
            Log.warn("⚠️ 版本检查失败: \(error.localizedDescription)")
            Log.info("⚠️ 版本检查失败，将尝试重新加载数据")
            // 如果版本检查失败，默认返回 true 以尝试加载数据
            return true
        }
    }
    
    // 加载数据（会检查版本，有更新才重新加载）
    // forceRefresh: 强制刷新，跳过版本检查
    func loadPromptStyles(forceRefresh: Bool = false) async {
        Log.info("🚀 开始加载图片列表... (forceRefresh: \(forceRefresh))")
        
        // 如果已有缓存数据且不强制刷新，先检查版本
        if !promptStyles.isEmpty && !forceRefresh {
            let hasUpdate = await checkForUpdates()
            
            // 如果没有更新，直接返回，使用缓存数据
            if !hasUpdate {
                Log.info("✅ 使用缓存数据，无需重新加载")
                return
            }
        }
        
        // 如果有更新或没有缓存或强制刷新，重新加载
        isLoading = true
        errorMessage = nil
        
        Log.debug("📡 API Base URL: \(apiService.baseURL)")
        Log.debug("📡 Full URL: \(apiService.baseURL)/api/v1/prompts/list")
        
        do {
            let response = try await apiService.fetchPromptStyles()
            Log.info("✅ 加载成功，共 \(response.prompts.count) 个样式")
            Log.debug("📦 服务器版本: \(response.version ?? "未知")")
            Log.debug("💾 缓存版本: \(getCachedVersion() ?? "无")")
            
            promptStyles = response.prompts
            appConfig = response.appConfig
            
            // 保存到缓存
            saveToCache(response)
            
            Log.info("✅ 数据已更新，当前版本: \(response.version ?? "未知")")
        } catch let error as APIError {
            // 检查是否是取消错误（这是正常的，不需要处理）
            if case .networkError(let networkError) = error,
               let urlError = networkError as? URLError,
               urlError.code == .cancelled {
                Log.debug("⚠️ 请求被取消（可能因为刷新操作），忽略此错误")
                // 取消错误通常是正常的（比如用户快速下拉刷新），不需要显示错误
                isLoading = false
                return
            }
            
            // 使用 APIError 的友好错误描述
            let errorDesc = error.localizedDescription ?? "未知错误"
            Log.error("❌ 加载失败: \(errorDesc)")
            
            // 如果加载失败，但有缓存数据，使用缓存数据
            if promptStyles.isEmpty {
                errorMessage = "加载图片列表失败: \(errorDesc)"
            } else {
                Log.warn("⚠️ 加载失败，但使用缓存数据")
                // 不设置错误信息，使用缓存数据
            }
        } catch let urlError as URLError where urlError.code == .cancelled {
            // 处理 URLSession 取消错误
            Log.debug("⚠️ 请求被取消（可能因为刷新操作），忽略此错误")
            isLoading = false
            return
        } catch {
            // 处理其他类型的错误
            Log.error("❌ 加载失败: \(error.localizedDescription)")
            
            // 如果加载失败，但有缓存数据，使用缓存数据
            if promptStyles.isEmpty {
                errorMessage = "加载图片列表失败: \(error.localizedDescription)"
            } else {
                Log.warn("⚠️ 加载失败，但使用缓存数据")
                // 不设置错误信息，使用缓存数据
            }
        }
        
        isLoading = false
        Log.info("🏁 加载完成")
    }
    
    // 强制刷新数据（清除缓存并重新加载）
    func forceRefresh() async {
        Log.info("🔄 强制刷新数据...")
        
        // 取消之前的任务（如果有）
        currentTask?.cancel()
        
        // 清除缓存
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: versionKey)
        dataVersion = nil
        appConfig = nil
        ImageService.shared.setCacheBuster(nil)
        
        // 强制重新加载
        await loadPromptStyles(forceRefresh: true)
    }

    // 下拉刷新：先检查版本，有更新再加载；日志与首次加载保持一致风格
    func refreshIfNeeded() async {
        Log.info("🔄 下拉刷新：检查版本更新中…")
        Log.debug("📡 API Base URL: \(apiService.baseURL)")
        Log.debug("📡 Version URL: \(apiService.baseURL)\(Constants.API.prompts)/version")

        let cached = getCachedVersion()
        let hasUpdate = await checkForUpdates()

        if hasUpdate {
            Log.info("🆕 发现新版本，缓存版本=\(cached ?? "无")，准备拉取列表…")
            // 使用独立任务执行加载，避免被 refreshable 的任务取消导致 -999
            currentTask?.cancel()
            currentTask = Task { [weak self] in
                guard let self = self else { return }
                await self.loadPromptStyles(forceRefresh: true)
            }
        } else {
            Log.info("✅ 数据已是最新，无需刷新 (版本: \(cached ?? "无"))")
        }
        Log.info("🏁 刷新结束")
    }
    
    // 按 Category 分组
    func groupByCategory() -> [String: [PromptStyle]] {
        return groupedStyles
    }
    
    // 获取指定 Category 的样式列表（按 subcategoryId 排序）
    func getStyles(forCategory category: String) -> [PromptStyle] {
        return promptStyles
            .filter { $0.category == category }
            .sorted { $0.subcategoryId < $1.subcategoryId }
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
    
    // 根据 categoryId 和 subcategoryId 查找样式
    func getStyle(categoryId: Int, subcategoryId: Int) -> PromptStyle? {
        return promptStyles.first {
            $0.categoryId == categoryId && $0.subcategoryId == subcategoryId
        }
    }
}
