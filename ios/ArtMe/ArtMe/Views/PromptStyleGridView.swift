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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.promptStyles.isEmpty {
                    emptyStateView
                } else {
                    scrollViewContent
                }
            }
            .navigationTitle("图片风格")
            .navigationBarTitleDisplayMode(.large)
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
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        // 该分类下的所有图片，横向滚动
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.getStyles(forCategory: category)) { style in
                                    NavigationLink(destination: PromptStyleDetailView(style: style)) {
                                        PromptStyleCard(style: style)
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
    }
    
    // 格式化分类名称（首字母大写）
    private func formatCategoryName(_ category: String) -> String {
        return category.prefix(1).uppercased() + category.dropFirst()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("暂无图片")
                .font(.headline)
                .foregroundColor(.gray)
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("请稍后重试")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Button("重试") {
                Task {
                    await viewModel.loadPromptStyles()
                }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PromptStyleCard: View {
    let style: PromptStyle
    
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
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        if isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        }
                    }
            }
        }
        .frame(width: 150, height: 150)
        .clipped()
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        isLoading = true
        let fullURL = Constants.apiBaseURL + style.thumbnailUrl
        do {
            image = try await ImageService.shared.downloadImage(from: fullURL)
        } catch {
            print("加载图片失败: \(error)")
        }
        isLoading = false
    }
}

#Preview {
    PromptStyleGridView()
}

