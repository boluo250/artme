//
//  StyleSelectionView.swift
//  ArtMe
//
//  风格选择视图
//

import SwiftUI

struct StyleSelectionView: View {
    @StateObject private var viewModel = StyleViewModel()
    @Binding var selectedStyle: Style?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                SearchBar(text: $viewModel.searchText)
                    .onChange(of: viewModel.searchText) { newValue in
                        Task {
                            if newValue.isEmpty {
                                await viewModel.loadStyles()
                            } else {
                                await viewModel.searchStyles(query: newValue)
                            }
                        }
                    }
                    .padding()
                
                // 分类筛选
                if !viewModel.categories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryChip(
                                title: "全部",
                                isSelected: viewModel.selectedCategory == nil
                            ) {
                                viewModel.selectedCategory = nil
                                viewModel.applyFilters()
                            }
                            
                            ForEach(viewModel.categories, id: \.self) { category in
                                CategoryChip(
                                    title: category,
                                    isSelected: viewModel.selectedCategory == category
                                ) {
                                    viewModel.selectedCategory = category
                                    viewModel.applyFilters()
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }
                
                // 风格网格
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredStyles.isEmpty {
                    VStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("暂无风格")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(viewModel.filteredStyles) { style in
                                StyleCard(
                                    style: style,
                                    isSelected: selectedStyle?.id == style.id
                                ) {
                                    selectedStyle = style
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("选择风格")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await viewModel.loadStyles()
        }
    }
}

struct StyleCard: View {
    let style: Style
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var image: UIImage?
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // 示例图片
                ZStack {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay {
                                ProgressView()
                            }
                    }
                }
                .frame(height: 150)
                .clipped()
                .cornerRadius(12)
                
                // 风格信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(style.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(style.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(8)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 3)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        let fullURL = Constants.apiBaseURL + style.exampleImageUrl
        do {
            image = try await ImageService.shared.downloadImage(from: fullURL)
        } catch {
            print("加载图片失败: \(error)")
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("搜索风格...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

