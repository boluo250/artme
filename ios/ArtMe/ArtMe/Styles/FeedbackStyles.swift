//
//  FeedbackStyles.swift
//  ArtMe
//
//  紫色主题反馈组件样式
//

import SwiftUI

// MARK: - Progress Indicator Modifier

/// 进度指示器修饰器
struct ProgressIndicatorModifier: ViewModifier {
    let tint: Color
    
    func body(content: Content) -> some View {
        content
            .progressViewStyle(CircularProgressViewStyle(tint: tint))
    }
}

extension View {
    /// 应用紫色进度指示器
    func purpleProgressIndicator() -> some View {
        self.modifier(ProgressIndicatorModifier(tint: .purple600))
    }
}

// MARK: - Alert Type

enum AlertType {
    case success, error, warning, info
    
    var color: Color {
        switch self {
        case .success: return .success
        case .error: return .error
        case .warning: return .warning
        case .info: return .purple600
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .success: return Color.success.opacity(0.1)
        case .error: return Color.error.opacity(0.1)
        case .warning: return Color.warning.opacity(0.1)
        case .info: return Color.purple600.opacity(0.1)
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

// MARK: - Alert Banner

/// 提示横幅
struct AlertBanner: View {
    let type: AlertType
    let message: String
    let onDismiss: (() -> Void)?
    @Environment(\.colorScheme) var colorScheme
    
    init(type: AlertType, message: String, onDismiss: (() -> Void)? = nil) {
        self.type = type
        self.message = message
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
                .font(.system(size: 20))
            
            Text(message)
                .font(.themeBody)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let dismiss = onDismiss {
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray500)
                        .font(.system(size: 14))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(Spacing.md)
        .background(type.backgroundColor)
        .cornerRadius(CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .stroke(type.color, lineWidth: 1)
        )
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .gray100 : .gray900
    }
}

// MARK: - Toast

/// Toast 提示
struct Toast: View {
    let type: AlertType
    let message: String
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack {
            if isShowing {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: type.icon)
                        .foregroundColor(type.color)
                        .font(.system(size: 18))
                    
                    Text(message)
                        .font(.themeBody)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .background(Color.gray900.opacity(0.9))
                .cornerRadius(CornerRadius.md)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            isShowing = false
                        }
                    }
                }
            }
        }
        .animation(.spring(), value: isShowing)
    }
}

// MARK: - Empty State

/// 空状态视图
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String?
    let action: (() -> Void)?
    let actionTitle: String?
    
    init(
        icon: String,
        title: String,
        message: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.gray300)
            
            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.themeHeadline)
                    .foregroundColor(.gray500)
                
                if let message = message {
                    Text(message)
                        .font(.themeBody)
                        .foregroundColor(.gray400)
                        .multilineTextAlignment(.center)
                }
            }
            
            if let action = action, let actionTitle = actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                }
                .primaryButtonStyle()
                .padding(.top, Spacing.sm)
            }
        }
        .padding(Spacing.xl)
    }
}

// MARK: - Loading View

/// 加载视图
struct LoadingView: View {
    let message: String?
    
    init(message: String? = "加载中...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .purple600))
                .scaleEffect(1.5)
            
            if let message = message {
                Text(message)
                    .font(.themeBody)
                    .foregroundColor(.gray500)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Loading Overlay

/// 加载遮罩
struct LoadingOverlay: View {
    let isShowing: Bool
    let message: String?
    
    init(isShowing: Bool, message: String? = nil) {
        self.isShowing = isShowing
        self.message = message
    }
    
    var body: some View {
        ZStack {
            if isShowing {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                VStack(spacing: Spacing.lg) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    if let message = message {
                        Text(message)
                            .font(.themeBody)
                            .foregroundColor(.white)
                    }
                }
                .padding(Spacing.xl)
                .background(Color.gray900.opacity(0.9))
                .cornerRadius(CornerRadius.lg)
            }
        }
    }
}

// MARK: - Skeleton Loader

/// 骨架屏加载器
struct SkeletonView: View {
    @State private var isAnimating = false
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(height: CGFloat = 20, cornerRadius: CGFloat = CornerRadius.sm) {
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.gray200,
                        Color.gray100,
                        Color.gray200
                    ]),
                    startPoint: isAnimating ? .leading : .trailing,
                    endPoint: isAnimating ? .trailing : .leading
                )
            )
            .frame(height: height)
            .cornerRadius(cornerRadius)
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Badge

/// 徽章
struct Badge: View {
    let text: String
    let color: Color
    
    init(text: String, color: Color = .purple600) {
        self.text = text
        self.color = color
    }
    
    var body: some View {
        Text(text)
            .font(.themeCaption.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(color)
            .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Notification Dot

/// 通知小红点
struct NotificationDot: View {
    let count: Int?
    
    init(count: Int? = nil) {
        self.count = count
    }
    
    var body: some View {
        ZStack {
            if let count = count, count > 0 {
                Text(count > 99 ? "99+" : "\(count)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, count > 9 ? 4 : 0)
                    .frame(minWidth: 16, minHeight: 16)
                    .background(Color.error)
                    .cornerRadius(8)
            } else {
                Circle()
                    .fill(Color.error)
                    .frame(width: 8, height: 8)
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    /// 显示加载遮罩
    func loadingOverlay(isShowing: Bool, message: String? = nil) -> some View {
        ZStack {
            self
            LoadingOverlay(isShowing: isShowing, message: message)
        }
    }
    
    /// 显示 Toast
    func toast(type: AlertType, message: String, isShowing: Binding<Bool>) -> some View {
        ZStack(alignment: .top) {
            self
            Toast(type: type, message: message, isShowing: isShowing)
                .padding(.top, Spacing.lg)
        }
    }
}

// MARK: - Pull to Refresh Indicator

/// 下拉刷新指示器
struct PullToRefreshIndicator: View {
    let isRefreshing: Bool
    
    var body: some View {
        HStack {
            Spacer()
            if isRefreshing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .purple600))
            }
            Spacer()
        }
        .padding(.vertical, Spacing.sm)
    }
}
