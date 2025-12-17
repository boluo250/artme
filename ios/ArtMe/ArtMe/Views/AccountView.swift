import SwiftUI

/// 个人中心（重设计）：参考“我的积分”页的分组列表风格
struct AccountView: View {
    @StateObject private var viewModel = AccountViewModel()
    @State private var showPaymentView = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // 自定义顶部栏：返回 + 标题（黑色背景，标题白色，返回仅显示“<”）
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(width: 44, height: 5)
                .foregroundColor(.white)
                .contentShape(Rectangle())
                Spacer()
                Text("个人中心")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                // 占位，确保标题居中
                Color.clear.frame(width: 44, height: 5)
            }
            .padding(.horizontal, Spacing.lg)
            // 缩小顶部栏高度：垂直内边距从 8 降到 2
            .padding(.vertical, 2)
            .background(Color.black)
            .overlay(Divider(), alignment: .bottom)

            List {
                // 顶部概要区：可用积分 + 购买按钮
                Section {
                    VStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill").foregroundColor(.pink500)
                            Text("可用积分").font(.subheadline).foregroundColor(.secondary)
                            Spacer()
                        }

                        Text(viewModel.pointsText)
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(.purple600)

                        Button(action: { showPaymentView = true }) {
                            Text("购买更多积分")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(colors: [.pink500, .violet500], startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(12)
                        }

                        if let err = viewModel.errorMessage {
                            Text(err).font(.footnote).foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 2)
                }

                // 我的：积分、作品集、会员
                Section {
                    // 我的积分
                    NavigationLink {
                        PointsView()
                    } label: {
                        HStack(spacing: 12) {
                            IconCircleGradient(
                                systemName: "star.fill",
                                gradient: LinearGradient(colors: [.pink500, .violet500], startPoint: .topLeading, endPoint: .bottomTrailing),
                                iconColor: .white
                            )
                            Text("我的积分")
                                .font(.body)
                                .foregroundColor(.primary)
                            Spacer()
                            Text(viewModel.pointsText)
                                .foregroundColor(.purple600)
                                .font(.themeHeadline)
                        }
                    }

                    // 我的作品集
                    NavigationLink {
                        PortfolioView()
                    } label: {
                        HStack(spacing: 12) {
                            IconCircleGradient(
                                systemName: "photo.on.rectangle",
                                gradient: LinearGradient(colors: [.pink500, .violet500], startPoint: .topLeading, endPoint: .bottomTrailing),
                                iconColor: .white
                            )
                            Text("我的作品集")
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                    }

                    // 立即开通会员
                    HStack(spacing: 12) {
                        IconCircleGradient(
                            systemName: "crown.fill",
                            gradient: LinearGradient(colors: [.pink500, .violet500], startPoint: .topLeading, endPoint: .bottomTrailing),
                            iconColor: .white
                        )
                        VStack(alignment: .leading, spacing: 2) {
                            Text("立即开通会员")
                                .font(.body)
                                .foregroundColor(.primary)
                            Text("即将上线")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundColor(.gray.opacity(0.5))
                    }
                    .contentShape(Rectangle())
                    .padding(.vertical, 2)
                }

                // 当前订阅
                if let subscription = viewModel.subscription {
                    Section("当前订阅") {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.seal")
                                .font(.system(size: 22))
                                .foregroundColor(.purple600)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(subscription.subscriptionType)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Text("到期时间：\(subscription.expiresAt.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // 更多
                Section {
                    actionRow(icon: "heart", title: "欢迎评分")
                    actionRow(icon: "paperplane", title: "分享给好友")
                    actionRow(icon: "message", title: "联系客服")
                    actionRow(icon: "gearshape", title: "设置")
                }
            }
            //.listStyle(.insetGrouped)
            
            // 吃掉系统在首段顶部的默认留白，缩短与“个人中心”标题之间的距离
            .padding(.top,-4)
            .refreshable {
                await viewModel.loadAccountInfo()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            // 确保游客账号存在，再加载账户信息（与积分页保持一致逻辑）
            do { _ = try await SessionManager.ensureGuestUser() } catch { }
            await viewModel.loadAccountInfo()
        }
        .sheet(isPresented: $showPaymentView) {
            PaymentView()
        }
    }

    // 简单动作行：仅展示样式，不做跳转
    private func actionRow(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(.gray)
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundColor(.gray.opacity(0.5))
        }
        .contentShape(Rectangle())
    }

    // 圆形彩色背景 + 粗重图标（渐变版）
    private struct IconCircleGradient: View {
        let systemName: String
        let gradient: LinearGradient
        let iconColor: Color

        var body: some View {
            ZStack {
                Circle()
                    .fill(gradient)
                Image(systemName: systemName)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(iconColor)
            }
            .frame(width: 40, height: 40)
        }
    }

    // 圆形纯色背景 + 粗重图标（纯色版）
    private struct IconCircle: View {
        let systemName: String
        let iconColor: Color
        let backgroundColor: Color

        var body: some View {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                Image(systemName: systemName)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(iconColor)
            }
            .frame(width: 40, height: 40)
        }
    }
}
