//
//  View+Theme.swift
//  ArtMe
//
//  视图主题扩展
//

import SwiftUI

// MARK: - Common View Combinations

extension View {
    /// 应用标准卡片样式（带内边距）
    func styledCard() -> some View {
        self
            .cardPadding()
            .standardCard()
    }
    
    /// 应用选中卡片样式（带内边距）
    func styledSelectedCard(isSelected: Bool) -> some View {
        self
            .cardPadding()
            .selectedCard(isSelected: isSelected)
    }
    
    /// 应用主要按钮样式（全宽）
    func primaryButton() -> some View {
        self
            .frame(maxWidth: .infinity)
            .primaryButtonStyle()
    }
    
    /// 应用次要按钮样式（全宽）
    func secondaryButton() -> some View {
        self
            .frame(maxWidth: .infinity)
            .secondaryButtonStyle()
    }
}

// MARK: - Layout Helpers

extension View {
    /// 应用标准页面内边距
    func pagePadding() -> some View {
        self.padding(Spacing.lg)
    }
    
    /// 应用标准区块间距
    func sectionSpacing() -> some View {
        self.padding(.vertical, Spacing.xl)
    }
    
    /// 应用水平填充
    func fillHorizontally() -> some View {
        self.frame(maxWidth: .infinity)
    }
    
    /// 应用垂直填充
    func fillVertically() -> some View {
        self.frame(maxHeight: .infinity)
    }
    
    /// 应用全屏填充
    func fillScreen() -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Conditional Modifiers

extension View {
    /// 条件应用修饰器
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// 条件应用修饰器（带 else 分支）
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
}

// MARK: - Tap Gesture Helpers

extension View {
    /// 添加点击手势（带反馈）
    func onTapWithFeedback(perform action: @escaping () -> Void) -> some View {
        self.onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }
    }
}

// MARK: - Keyboard Helpers

extension View {
    /// 点击隐藏键盘
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    }
}

// MARK: - Safe Area Helpers

extension View {
    /// 忽略顶部安全区域
    func ignoreTopSafeArea() -> some View {
        self.ignoresSafeArea(edges: .top)
    }
    
    /// 忽略底部安全区域
    func ignoreBottomSafeArea() -> some View {
        self.ignoresSafeArea(edges: .bottom)
    }
    
    /// 忽略水平安全区域
    func ignoreHorizontalSafeArea() -> some View {
        self.ignoresSafeArea(edges: .horizontal)
    }
}

// MARK: - Divider Helpers

extension View {
    /// 添加顶部分隔线
    func topDivider() -> some View {
        VStack(spacing: 0) {
            Divider()
            self
        }
    }
    
    /// 添加底部分隔线
    func bottomDivider() -> some View {
        VStack(spacing: 0) {
            self
            Divider()
        }
    }
}

// MARK: - Scroll View Helpers

extension View {
    /// 禁用滚动指示器
    func hideScrollIndicators() -> some View {
        self.onAppear {
            UIScrollView.appearance().showsVerticalScrollIndicator = false
            UIScrollView.appearance().showsHorizontalScrollIndicator = false
        }
    }
}

// MARK: - Animation Helpers

extension View {
    /// 应用弹簧动画
    func springAnimation() -> some View {
        self.animation(.spring(), value: UUID())
    }
    
    /// 应用缓入缓出动画
    func easeInOutAnimation(duration: Double = 0.3) -> some View {
        self.animation(.easeInOut(duration: duration), value: UUID())
    }
}

// MARK: - Debug Helpers

extension View {
    /// 添加边框（用于调试布局）
    func debugBorder(_ color: Color = .red, width: CGFloat = 1) -> some View {
        self.border(color, width: width)
    }
    
    /// 添加背景色（用于调试布局）
    func debugBackground(_ color: Color = .red.opacity(0.2)) -> some View {
        self.background(color)
    }
}

// MARK: - Placeholder Modifier

/// 占位符修饰器
struct PlaceholderModifier: ViewModifier {
    let placeholder: String
    let text: String
    
    func body(content: Content) -> some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray400)
            }
            content
        }
    }
}

extension View {
    /// 添加占位符
    func placeholder(_ placeholder: String, when text: String) -> some View {
        self.modifier(PlaceholderModifier(placeholder: placeholder, text: text))
    }
}

// MARK: - Shimmer Effect

/// 闪烁效果修饰器
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 300
                }
            }
    }
}

extension View {
    /// 应用闪烁效果
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}
