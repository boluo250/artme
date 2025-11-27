//
//  PromptStyleGridView.swift
//  ArtMe
//
//  Prompt 风格网格视图（首页）
//
//

import SwiftUI

struct PromptStyleGridView: View {
    @StateObject private var viewModel = PromptStyleViewModel()
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.promptStyles.isEmpty {
                    // 首次加载时显示加载指示器
                    VStack {
                        ProgressView()
                            .purpleProgressIndicator()
                        Text("加载中...")
                            .textStyleCaption()
                            .padding(.top, Spacing.md)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage, viewModel.promptStyles.isEmpty {
                    // 只在没有缓存数据时显示错误
                    EmptyStateView(
                        icon: "exclamationmark.triangle",
                        title: "加载失败",
                        message: errorMessage
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 显示内容
                    ScrollView {
                        VStack(spacing: Spacing.xl) {
                            ForEach(viewModel.categories, id: \.self) { category in
                                CategorySection(
                                    category: category,
                                    styles: viewModel.getStyles(forCategory: category)
                                )
                            }
                        }
                        .padding(.vertical, Spacing.lg)
                    }
                    .refreshable {
                        await viewModel.refreshIfNeeded()
                    }
                }
            }
            .navigationTitle("艺术风格")
            .navigationBarTitleDisplayMode(.large)
            .toolbar(.visible, for: .tabBar)
        }
        .task {
            await viewModel.loadPromptStyles()
        }
    }
}

// MARK: - 分类区域

struct CategorySection: View {
    let category: String
    let styles: [PromptStyle]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // 分类标题
            Text(categoryDisplayName)
                .textStyleTitle2()
                .padding(.horizontal, Spacing.lg)
            
            // 风格卡片列表
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(styles) { style in
                        NavigationLink(destination: PromptStyleDetailView(style: style)) {
                            PromptStyleCard(style: style)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
        }
    }
    
    private var categoryDisplayName: String {
        // 可以根据需要添加中文映射
        let categoryMap: [String: String] = [
            "cartoon": "卡通动漫",
            "figure": "手办模型",
            "illustration": "手绘插画",
            "anime": "动漫风格",
            "gorillaz": "街头艺术"
        ]
        return categoryMap[category] ?? category.capitalized
    }
}

// MARK: - 风格卡片

struct PromptStyleCard: View {
    let style: PromptStyle
    @State private var imageData: Data?
    @State private var staticImage: UIImage?
    @State private var isLoading = true
    @State private var isGif = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // 缩略图
            ZStack {
                if isLoading {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay {
                            ProgressView()
                                .purpleProgressIndicator()
                        }
                } else if let imageData = imageData, isGif {
                    // 显示 GIF 动画
                    GifImage(data: imageData)
                        .allowsHitTesting(false) // 防止 GIF 视图拦截点击事件
                } else if let image = staticImage {
                    // 显示静态图片
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    // 加载失败
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay {
                            Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                        }
                }
            }
            .frame(width: 105, height: 132)
            .clipped()
            .cornerRadiusMD()
            
            // 风格名称
            Text(subcategoryDisplayName)
                .textStyleSubheadline()
                .lineLimit(1)
                .frame(width: 105, alignment: .leading)
        }
        .contentShape(Rectangle()) // 确保整个卡片区域都可以点击
        .task {
            await loadThumbnail()
        }
    }
    
    private var subcategoryDisplayName: String {
        // 可以根据需要添加中文映射
        let subcategoryMap: [String: String] = [
            "3D_figurine": "3D手办",
            "chibi_style": "Q版风格",
            "capsule_toy": "扭蛋玩具",
            "wooden_figurine": "木质手办",
            "3D_cartoon_keychain": "3D钥匙扣",
            "dreamy_watercolor": "梦幻水彩",
            "comic_book_illustration": "漫画插画",
            "streeturchin": "街头艺术",
            "1920s_fairy_tale_illustration_Arthur_Rackham": "童话插画"
        ]
        return subcategoryMap[style.subcategory] ?? style.subcategory.replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    private func loadThumbnail() async {
        isLoading = true
        let fullURL = Constants.apiBaseURL + style.thumbnailUrl
        
        // 调试日志：开始加载
        print("Card: 开始加载缩略图: \(style.subcategory), URL: \(style.thumbnailUrl)")
        
        do {
            // 先下载数据
            let data = try await ImageService.shared.downloadImageData(from: fullURL)
            print("Card: 下载完成，数据大小: \(data.count) bytes")
            
            // 检查是否是 GIF（通过文件头判断）
            if isGifData(data) {
                // 是 GIF，保存数据用于动画播放
                print("Card: 检测到 GIF 格式！")
                imageData = data
                isGif = true
            } else {
                // 不是 GIF，转换为 UIImage
                print("Card: 不是 GIF，尝试转换为 UIImage")
                if let image = UIImage(data: data) {
                    staticImage = image
                    isGif = false
                    print("Card: 转换为 UIImage 成功")
                } else {
                     print("Card: 转换为 UIImage 失败")
                }
            }
        } catch {
            print("Card Error: 加载缩略图失败: \(error)")
        }
        
        isLoading = false
    }
    
    // 检查数据是否是 GIF 格式（通过文件头判断）
    private func isGifData(_ data: Data) -> Bool {
        // GIF 文件头：GIF89a 或 GIF87a
        guard data.count >= 6 else { return false }
        let header = data.prefix(6)
        let gif89a = Data([0x47, 0x49, 0x46, 0x38, 0x39, 0x61]) // "GIF89a"
        let gif87a = Data([0x47, 0x49, 0x46, 0x38, 0x37, 0x61]) // "GIF87a"
        
        // 调试：打印头几个字节
        // let headerString = header.map { String(format: "%02x", $0) }.joined()
        // print("Card: 文件头: \(headerString)")
        
        return header == gif89a || header == gif87a
    }
}

#Preview {
    PromptStyleGridView()
}
