//
//  PromptStyleGridView.swift
//  ArtMe
//
//  Prompt 风格网格展示视图
//

import SwiftUI

struct PromptStyleGridView: View {
    @StateObject private var viewModel = PromptStyleViewModel()
    @State private var selectedStyle: PromptStyle?
    
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.promptStyles.isEmpty {
                    ProgressView()
                        .purpleProgressIndicator()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.promptStyles.isEmpty {
                    emptyStateView
                } else {
                    scrollViewContent
                }
            }
            .navigationTitle("图片风格")
            .navigationBarTitleDisplayMode(.large)
            .toolbar(.visible, for: .tabBar)
            .task {
                await viewModel.loadPromptStyles()
            }
            .alert("错误", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("确定", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    private var scrollViewContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(viewModel.categories, id: \.self) { category in
                    VStack(alignment: .leading, spacing: 12) {
                        // 分类标题
                        Text(formatCategoryName(category))
                            .textStyleHeadline()
                            .padding(.horizontal, Spacing.lg)
                        
                        // 该分类下的所有图片，横向滚动
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.getStyles(forCategory: category)) { style in
                                    NavigationLink(destination: PromptStyleDetailView(style: style)) {
                                        // 将数据版本传入，版本变化时触发缩略图刷新
                                        PromptStyleCard(style: style, cacheBuster: viewModel.dataVersion)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            // 下拉刷新：先检查版本，有更新才重新拉取
            await viewModel.refreshIfNeeded()
        }
    }
    
    // 格式化分类名称（首字母大写）
    private func formatCategoryName(_ category: String) -> String {
        return category.prefix(1).uppercased() + category.dropFirst()
    }
    
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "photo.on.rectangle.angled",
            title: "暂无图片",
            message: viewModel.errorMessage ?? "请稍后重试",
            actionTitle: "重试"
        ) {
            Task {
                await viewModel.forceRefresh()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PromptStyleCard: View {
    let style: PromptStyle
    // 用于控制图片缓存失效（服务端版本变更时刷新缩略图）
    let cacheBuster: String?
    
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        // 只显示图片，不显示文字信息
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.gray300.opacity(0.3))
                    .overlay {
                        if isLoading {
                            ProgressView()
                                .purpleProgressIndicator()
                        } else {
                            Image(systemName: "photo")
                                .foregroundColor(.gray400)
                        }
                    }
            }
        }
        .frame(width: 150, height: 150)
        .clipped()
        .cornerRadiusMD()
        .cardShadow()
        .task {
            await loadImage()
        }
        .onChange(of: cacheBuster) { _ in
            // 先清空旧图并显示加载占位，再拉取新缩略图
            image = nil
            isLoading = true
            Task { await loadImage() }
        }
    }
    
    private func loadImage() async {
        isLoading = true
        // 将 thumbnailUrl 转换为缩略图URL（添加 _abbreviated 后缀）
        let thumbnailURL = convertToThumbnailURL(style.thumbnailUrl)
        let fullURL = Constants.apiBaseURL + thumbnailURL
        do {
            image = try await ImageService.shared.downloadImage(from: fullURL)
        } catch {
            print("加载图片失败: \(error)")
        }
        isLoading = false
    }
    
    /// 将原始URL转换为缩略图URL
    /// 例如：/api/v1/prompts/cartoon/3D_figurine/image -> /api/v1/prompts/cartoon/3D_figurine_abbreviated/image
    private func convertToThumbnailURL(_ url: String) -> String {
        // URL格式：/api/v1/prompts/{category}/{subcategory}/image
        // 目标格式：/api/v1/prompts/{category}/{subcategory}_abbreviated/image
        
        // 检查是否已经是缩略图URL（避免重复添加）
        if url.contains("_abbreviated") {
            return url
        }
        
        // 将 /image 替换为 _abbreviated/image
        if url.hasSuffix("/image") {
            return url.replacingOccurrences(of: "/image", with: "_abbreviated/image")
        }
        
        // 如果格式不符合预期，返回原URL
        return url
    }
}

#Preview {
    PromptStyleGridView()
}
