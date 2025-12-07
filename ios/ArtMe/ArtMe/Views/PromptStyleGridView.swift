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
    @State private var targetCategory: String?
    private let onAccountTapped: (() -> Void)?
    private let onSelectStyle: ((PromptStyle) -> Void)?
    @EnvironmentObject private var taskStatusManager: TaskStatusManager
    @State private var showPortfolio = false
    
    init(
        onAccountTapped: (() -> Void)? = nil,
        onSelectStyle: ((PromptStyle) -> Void)? = nil
    ) {
        self.onAccountTapped = onAccountTapped
        self.onSelectStyle = onSelectStyle
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollViewReader { proxy in
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
                                // 顶部：Banner 始终展示（任务状态改为使用顶部 Toast 提示）
                                if let banner = viewModel.appConfig?.homeBanner,
                                   (banner.enable ?? true) {
                                    
                                    bannerSection(for: banner)
                                    .padding(.horizontal, Spacing.lg)
                                    
                                }
                                
                                ForEach(viewModel.categories, id: \.self) { category in
                                    CategorySection(
                                        category: category,
                                        styles: viewModel.getStyles(forCategory: category),
                                        onSelectStyle: { style in
                                            onSelectStyle?(style)
                                        }
                                    )
                                    .id(category)
                                }
                            }
                            .padding(.bottom, Spacing.lg)
                        }
                        .refreshable {
                            await viewModel.refreshIfNeeded()
                        }
                        .onChange(of: targetCategory) { category in
                            guard let category = category else { return }
                            withAnimation {
                                proxy.scrollTo(category, anchor: .top)
                            }
                            // 滚动完成后清空，避免重复触发
                            DispatchQueue.main.async {
                                targetCategory = nil
                            }
                        }
                    }
                }
            }
            
            if let onAccountTapped = onAccountTapped {
                accountButton(action: onAccountTapped)
                    .padding(.trailing, Spacing.lg)
                    .padding(.top, Spacing.md)
            }

            // Toast 展示已由全局 GlobalToastContainer 统一处理
        }
        .task {
            print(">>> [Homepage] preheat start")
            PickerCache.shared.prepare()                   // 预热并缓存 PHPicker 实例
            PhotoPreheater.shared.preheatIfNeeded()        // 预热 PhotoKit / TCC
            await viewModel.loadPromptStyles()
            taskStatusManager.startPollingIfNeeded()
        }
        .onAppear {
            taskStatusManager.startPollingIfNeeded()
        }
        .background(
            NavigationLink(
                destination: PortfolioView(),
                isActive: $showPortfolio
            ) { EmptyView() }
        )
    }
    
    private func handleBannerAction(_ banner: BannerConfig) {        
        guard let action = banner.action else { return }
        let prefix = "open_category_"
        let lowercasedAction = action.lowercased()
        
        guard lowercasedAction.hasPrefix(prefix) else { return }
        let categoryKey = String(lowercasedAction.dropFirst(prefix.count))
        
        if let matched = viewModel.categories.first(where: { $0.lowercased() == categoryKey }) {
            targetCategory = matched
        }
    }
    
    private func targetStyle(for banner: BannerConfig) -> PromptStyle? {
        guard let categoryId = banner.categoryId,
              let subcategoryId = banner.subcategoryId else {
            return nil
        }
        return viewModel.getStyle(categoryId: categoryId, subcategoryId: subcategoryId)
    }
    
    @ViewBuilder
    private func bannerSection(
        for banner: BannerConfig
    ) -> some View {
        if let targetStyle = targetStyle(for: banner) {
            Button {
                onSelectStyle?(targetStyle)
            } label: {
                HomeBannerView(banner: banner)
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            HomeBannerView(banner: banner) {
                handleBannerAction(banner)
            }
        }
    }
    
    private func accountButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                Text("我的")
                    .font(.callout)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.75), in: Capsule())
        .accessibilityLabel("个人页面")
    }
}

// MARK: - 轻量内置通知 Banner

struct ToastBanner: View {
    let title: String
    let message: String
    let actionTitle: String
    let onAction: () -> Void
    let onDismiss: () -> Void
    /// 完成时展示的缩略图 URL（相对或绝对），pending 状态可以传 nil
    let thumbnailUrl: String?

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            // 左侧缩略图：优先展示任务关联的图片（制作中 = 本次上传图片，制作完成 = 最终成品）
            if let thumbnailUrl = thumbnailUrl,
               let url = URL(string: thumbnailUrl.hasPrefix("http") ? thumbnailUrl : Constants.apiBaseURL + thumbnailUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.gray400)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 32, height: 32)
                .clipped()
                .cornerRadiusSM()
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }

            // 右侧文案区域
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(.gray400)
                    .lineLimit(2)
                
                HStack {
                    Button(actionTitle, action: onAction)
                        .font(.callout)
                        .fontWeight(.semibold)
                
                    Spacer(minLength: Spacing.sm)
                
                    Button("关闭", action: onDismiss)
                        .font(.callout)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
        )
        .shadow(radius: 8, y: 4)
        .frame(maxWidth: 280, alignment: .leading)
    }
}

// MARK: - 分类区域

struct CategorySection: View {
    let category: String
    let styles: [PromptStyle]
    let onSelectStyle: ((PromptStyle) -> Void)?
    
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
                        Button {
                            onSelectStyle?(style)
                        } label: {
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
        if let localized = styles.first?.categoryCn, !localized.isEmpty {
            return localized
        }
        // 兼容旧数据：保持已有映射
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
        if let localized = style.subcategoryCn, !localized.isEmpty {
            return localized
        }
        // 兼容旧数据：保持已有映射
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

// MARK: - 首页 Banner

struct HomeBannerView: View {
    let banner: BannerConfig
    var onTap: (() -> Void)?
    
    @State private var bannerImage: UIImage?
    @State private var isLoading = false
    private let bannerAspectRatio: CGFloat = 4.0 / 3.0
    
    var body: some View {
        interactiveBanner
            .task {
                await loadImageIfNeeded()
            }
    }
    
    @ViewBuilder
    private var interactiveBanner: some View {
        let content = bannerContent
            .contentShape(Rectangle())
        
        if let onTap = onTap {
            content.onTapGesture {
                onTap()
            }
        } else {
            content
        }
    }
    
    private var bannerContent: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let image = bannerImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if isLoading {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .overlay {
                            ProgressView()
                                .purpleProgressIndicator()
                        }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(.gray400)
                        }
                }
            }
            .aspectRatio(bannerAspectRatio, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .clipShapeLG()
            .cardShadow()
        }
    }
    
    private func loadImageIfNeeded() async {
        guard bannerImage == nil else { return }
        isLoading = true
        let imagePath = banner.image
        let fullURL = imagePath.hasPrefix("http") ? imagePath : Constants.apiBaseURL + imagePath
        
        do {
            let image = try await ImageService.shared.downloadImage(from: fullURL)
            bannerImage = image
        } catch {
            print("Banner: 图片加载失败 \(error.localizedDescription)")
        }
        
        isLoading = false
    }
}

#Preview {
    PromptStyleGridView()
}
