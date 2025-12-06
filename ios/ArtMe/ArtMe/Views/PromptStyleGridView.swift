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
    @State private var targetCategory: String?
    private let onAccountTapped: (() -> Void)?
    
    // 任务状态提示（逻辑状态）
    @State private var pendingItem: GeneratedImageHistory?
    @State private var completedItem: GeneratedImageHistory?
    
    // 顶部 Toast 展示状态（UI）
    @State private var pendingToastItem: GeneratedImageHistory?
    @State private var completedToastQueue: [GeneratedImageHistory] = []
    @State private var currentCompletedToast: GeneratedImageHistory?
    @State private var isProcessingCompletedQueue = false
    @State private var shownPendingTaskIds: [String] = []
    @State private var shownCompletedTaskIds: [String] = []
    @State private var showPortfolio = false
    @State private var isPolling = false
    
    init(onAccountTapped: (() -> Void)? = nil) {
        self.onAccountTapped = onAccountTapped
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
                                        styles: viewModel.getStyles(forCategory: category)
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

            // 顶部轻量 Toast：1）生成开始时「正在制作」提示（2 秒自动消失）
            if let item = pendingToastItem {
                ToastBanner(
                    title: "正在制作",
                    message: item.prompt,
                    actionTitle: "查看",
                    onAction: {
                        pendingToastItem = nil
                        showPortfolio = true
                    },
                    onDismiss: { pendingToastItem = nil }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, 60)
                .padding(.horizontal, Spacing.lg)
            }
            // 2）制作完成时「制作完成」提示：多个任务顺序依次展示，每条约 2 秒
            else if let item = currentCompletedToast {
                ToastBanner(
                    title: "制作完成",
                    message: item.prompt,
                    actionTitle: "查看",
                    onAction: {
                        currentCompletedToast = nil
                        showPortfolio = true
                    },
                    onDismiss: { currentCompletedToast = nil }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, 60)
                .padding(.horizontal, Spacing.lg)
            }
        }
        .task {
            await viewModel.loadPromptStyles()
            await pollPendingTasksIfNeeded()
        }
        .onAppear {
            Task {
                await pollPendingTasksIfNeeded()
            }
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
            NavigationLink(destination: PromptStyleDetailView(style: targetStyle)) {
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

    // MARK: - 任务状态轮询

    private func pollPendingTasksIfNeeded() async {
        if isPolling { return }
        isPolling = true
        defer { isPolling = false }

        // 持续轮询，直到本地不再有「制作中」任务或任务被取消
        while true {
            let hasPending = await checkPendingTasksOnce()
            if !hasPending { break }
            
            // 任务仍在制作中，3 秒后继续查询
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if Task.isCancelled { break }
        }
    }

    /// 查询一次最近一条任务的状态
    /// - Returns: 是否仍然需要继续轮询（true 表示仍在制作中）
    private func checkPendingTasksOnce() async -> Bool {
        // 读取本地历史：最新的任务排在最前
        let historyManager = HistoryManager()

        // 没有任何历史记录：不需要轮询
        guard let latest = historyManager.history.first else {
            await MainActor.run {
                pendingItem = nil
            }
            return false
        }

        // 如果最新任务已经是「完成」或「失败」状态（本地历史里就已经是 completed/failed），
        // 说明不是本次会话中新完成的任务，此时只更新状态，不触发完成 Toast。
        if let status = latest.status {
            if status == "completed" {
                await MainActor.run {
                    pendingItem = nil
                    completedItem = latest
                }
                return false
            }
            if status == "failed" {
                await MainActor.run {
                    pendingItem = nil
                }
                return false
            }
        }

        // 最新任务仍是 pending / processing：向后端查询最新状态
        do {
            let statusResponse = try await APIService.shared.fetchTaskStatus(taskId: latest.id)

            switch statusResponse.status {
            case "completed":
                // 更新本地历史为完成状态
                historyManager.updateHistoryStatus(
                    id: latest.id,
                    status: "completed",
                    imageUrl: statusResponse.imageUrls.first,
                    error: nil
                )

                // 重新读取更新后的这条记录
                let updated = historyManager.history.first(where: { $0.id == latest.id }) ?? latest

                await MainActor.run {
                    pendingItem = nil
                    completedItem = updated
                    enqueueCompletedToastIfNeeded(for: updated)
                }
                return false

            case "failed":
                historyManager.updateHistoryStatus(
                    id: latest.id,
                    status: "failed",
                    imageUrl: nil,
                    error: statusResponse.error
                )
                await MainActor.run {
                    pendingItem = nil
                }
                return false

            case "pending", "processing":
                // 仍在制作中：更新本地状态并继续轮询，并触发一次「正在制作」Toast
                historyManager.updateHistoryStatus(
                    id: latest.id,
                    status: statusResponse.status,
                    imageUrl: statusResponse.imageUrls.first ?? latest.imageUrl,
                    error: statusResponse.error
                )
                let updated = historyManager.history.first(where: { $0.id == latest.id }) ?? latest
                await MainActor.run {
                    pendingItem = updated
                    showPendingToastIfNeeded(for: updated)
                }
                return true

            default:
                // 未知状态：保守处理为已完成，不再轮询
                await MainActor.run {
                    pendingItem = nil
                    completedItem = latest
                    enqueueCompletedToastIfNeeded(for: latest)
                }
                return false
            }

        } catch {
            // 查询失败时，保守认为任务仍在制作中，稍后重试，并确保至少展示一次「正在制作」提示
            await MainActor.run {
                pendingItem = latest
                showPendingToastIfNeeded(for: latest)
            }
            return true
        }
    }

    // MARK: - Toast 辅助方法

    /// 只在每个任务第一次进入「制作中」状态时，展示一次 2 秒的「正在制作」Toast
    @MainActor
    private func showPendingToastIfNeeded(for item: GeneratedImageHistory) {
        guard !shownPendingTaskIds.contains(item.id) else { return }
        shownPendingTaskIds.append(item.id)
        pendingToastItem = item

        Task {
            // 展示约 2 秒
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                if pendingToastItem?.id == item.id {
                    pendingToastItem = nil
                }
            }
        }
    }

    /// 每个任务完成时加入队列，只展示一次；多个任务顺序依次弹出，每条约 2 秒
    @MainActor
    private func enqueueCompletedToastIfNeeded(for item: GeneratedImageHistory) {
        guard !shownCompletedTaskIds.contains(item.id) else { return }
        shownCompletedTaskIds.append(item.id)
        completedToastQueue.append(item)

        Task {
            await processCompletedToastQueueIfNeeded()
        }
    }

    /// 依次展示队列中的「制作完成」Toast，每条约 2 秒
    @MainActor
    private func processCompletedToastQueueIfNeeded() async {
        guard !isProcessingCompletedQueue else { return }
        isProcessingCompletedQueue = true

        while !completedToastQueue.isEmpty {
            let next = completedToastQueue.removeFirst()

            withAnimation {
                currentCompletedToast = next
            }

            // 展示约 2 秒
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            withAnimation {
                if currentCompletedToast?.id == next.id {
                    currentCompletedToast = nil
                }
            }

            // 给一点点间隔，避免动画过于拥挤
            try? await Task.sleep(nanoseconds: 200_000_000)
        }

        isProcessingCompletedQueue = false
    }
}

// MARK: - 轻量内置通知 Banner

private struct ToastBanner: View {
    let title: String
    let message: String
    let actionTitle: String
    let onAction: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack {
            HStack(alignment: .top, spacing: Spacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title).textStyleHeadline()
                    Text(message).textStyleCaption().lineLimit(2)
                    HStack {
                        Button(actionTitle, action: onAction)
                            .font(.callout)
                            .fontWeight(.semibold)
                        Spacer()
                        Button("关闭", action: onDismiss)
                            .font(.callout)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.9))
            .cornerRadiusMD()
            .shadow(radius: 10)
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
