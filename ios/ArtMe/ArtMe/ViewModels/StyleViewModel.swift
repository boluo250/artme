//
//  StyleViewModel.swift
//  ArtMe
//
//  风格视图模型
//

import Foundation
import SwiftUI
import Combine

@MainActor
class StyleViewModel: ObservableObject {
    @Published var styles: [Style] = []
    @Published var filteredStyles: [Style] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedCategory: String?
    
    private let apiService = APIService.shared
    private var allCategories: [String] = []
    
    var categories: [String] {
        Array(Set(styles.map { $0.category })).sorted()
    }
    
    init() {
        // 不在 init 中加载数据，由视图的 .task 修饰符触发
    }
    
    func loadStyles() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.listStyles()
            styles = response.styles
            filteredStyles = styles
            applyFilters()
        } catch {
            errorMessage = "加载风格失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func searchStyles(query: String) async {
        guard !query.isEmpty else {
            filteredStyles = styles
            applyFilters()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.searchStyles(query: query)
            filteredStyles = response.styles
            applyFilters()
        } catch {
            errorMessage = "搜索失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func applyFilters() {
        var result = styles
        
        // 应用搜索过滤
        if !searchText.isEmpty {
            result = result.filter { style in
                style.name.localizedCaseInsensitiveContains(searchText) ||
                style.description.localizedCaseInsensitiveContains(searchText) ||
                style.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // 应用分类过滤
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        filteredStyles = result
    }
}

