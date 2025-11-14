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
    
    // 按 Category 分组的样式
    var groupedStyles: [String: [PromptStyle]] {
        Dictionary(grouping: promptStyles) { $0.category }
    }
    
    // 所有 Category 列表
    var categories: [String] {
        Array(Set(promptStyles.map { $0.category })).sorted()
    }
    
    init() {
        // 不在 init 中加载数据，由视图的 .task 修饰符触发
    }
    
    func loadPromptStyles() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.fetchPromptStyles()
            promptStyles = response.prompts
        } catch {
            errorMessage = "加载图片列表失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func refresh() async {
        await loadPromptStyles()
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

