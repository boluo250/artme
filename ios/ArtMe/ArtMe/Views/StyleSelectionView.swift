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
                        .purpleProgressIndicator()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredStyles.isEmpty {
                    EmptyStateView(
                        icon: "photo.on.rectangle.angled",
                        title: "暂无风格",
                        message: "尝试搜索其他关键词"
                    )
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
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // 示例图片
                ZStack {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color.gray300.opacity(0.3))
                            .overlay {
                                ProgressView()
                                    .purpleProgressIndicator()
                            }
                    }
                }
                .frame(height: 150)
                .clipped()
                .cornerRadiusMD()
                
                // 风格信息
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(style.name)
                        .textStyleHeadline()
                    
                    Text(style.description)
                        .textStyleCaption()
                        .lineLimit(2)
                }
            }
            .cardPaddingCompact()
            .selectedCard(isSelected: isSelected)
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
            Log.error("加载图片失败: \(error)")
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.themeSubheadline)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .background(backgroundColor)
                .foregroundColor(foregroundColor)
                .cornerRadius(CornerRadius.xl)
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .purple600
        }
        return colorScheme == .dark ? .gray700 : .gray100
    }
    
    private var foregroundColor: Color {
        if isSelected {
            return .white
        }
        return colorScheme == .dark ? .gray100 : .gray900
    }
}

struct SearchBar: View {
    @Binding var text: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray500)
                .font(.system(size: 16))
            
            TextField("搜索风格...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray400)
                        .font(.system(size: 16))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(Spacing.md)
        .background(backgroundColor)
        .cornerRadiusMD()
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? .gray700 : .gray100
    }
}

