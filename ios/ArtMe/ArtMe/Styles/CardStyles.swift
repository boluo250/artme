//
//  CardStyles.swift
//  ArtMe
//
//  紫色主题卡片样式
//

import SwiftUI

// MARK: - Standard Card Modifier

/// 标准卡片修饰器
struct StandardCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .cornerRadius(CornerRadius.md)
            .shadowAdaptive(size: .md)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? .gray800 : .white
    }
}

// MARK: - Selected Card Modifier

/// 选中状态卡片修饰器
struct SelectedCardModifier: ViewModifier {
    let isSelected: Bool
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isSelected ? Color.purple600 : .clear, lineWidth: 3)
            )
            .shadow(
                color: isSelected ? Color.purple600.opacity(0.3) : shadowColor,
                radius: isSelected ? 12 : 5,
                x: 0,
                y: isSelected ? 4 : 2
            )
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? .gray800 : .white
    }
    
    private var shadowColor: Color {
        Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1)
    }
}

// MARK: - Image Card Modifier

/// 图片卡片修饰器
struct ImageCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .cornerRadius(CornerRadius.md)
            .shadowAdaptive(size: .md)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? .gray800 : .white
    }
}

// MARK: - Elevated Card Modifier

/// 悬浮卡片修饰器（更强的阴影效果）
struct ElevatedCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .cornerRadius(CornerRadius.md)
            .shadowAdaptive(size: .lg)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? .gray800 : .white
    }
}

// MARK: - Compact Card Modifier

/// 紧凑卡片修饰器（较小的圆角和阴影）
struct CompactCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .cornerRadius(CornerRadius.sm)
            .shadowAdaptive(size: .sm)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? .gray800 : .white
    }
}

// MARK: - Card Content Padding

extension View {
    /// 应用标准卡片内边距
    func cardPadding() -> some View {
        self.padding(Spacing.lg)
    }
    
    /// 应用紧凑卡片内边距
    func cardPaddingCompact() -> some View {
        self.padding(Spacing.md)
    }
    
    /// 应用宽松卡片内边距
    func cardPaddingRelaxed() -> some View {
        self.padding(Spacing.xl)
    }
}

// MARK: - Card Style Extensions

extension View {
    /// 应用标准卡片样式
    func standardCard() -> some View {
        self.modifier(StandardCardModifier())
    }
    
    /// 应用选中状态卡片样式
    func selectedCard(isSelected: Bool) -> some View {
        self.modifier(SelectedCardModifier(isSelected: isSelected))
    }
    
    /// 应用图片卡片样式
    func imageCard() -> some View {
        self.modifier(ImageCardModifier())
    }
    
    /// 应用悬浮卡片样式
    func elevatedCard() -> some View {
        self.modifier(ElevatedCardModifier())
    }
    
    /// 应用紧凑卡片样式
    func compactCard() -> some View {
        self.modifier(CompactCardModifier())
    }
}

// MARK: - Card Container Views

/// 标准卡片容器
struct CardContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .cardPadding()
            .standardCard()
    }
}

/// 图片卡片容器
struct ImageCardContainer<Content: View>: View {
    let image: Image
    let content: Content
    let imageHeight: CGFloat
    
    init(image: Image, imageHeight: CGFloat = 150, @ViewBuilder content: () -> Content) {
        self.image = image
        self.imageHeight = imageHeight
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: imageHeight)
                .clipped()
                .cornerRadius(CornerRadius.md, corners: [.topLeft, .topRight])
            
            content
                .padding(Spacing.md)
        }
        .imageCard()
    }
}

// MARK: - Corner Radius Helper

extension View {
    /// 应用指定角的圆角
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - List Card Style

/// 列表项卡片样式
struct ListCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding(Spacing.md)
            .background(backgroundColor)
            .cornerRadius(CornerRadius.sm)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? .gray800 : .gray50
    }
}

extension View {
    /// 应用列表项卡片样式
    func listCard() -> some View {
        self.modifier(ListCardModifier())
    }
}

// MARK: - Interactive Card

/// 可交互卡片修饰器（带按压效果）
struct InteractiveCardModifier: ViewModifier {
    @State private var isPressed = false
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .standardCard()
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onTapGesture {
                action()
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

extension View {
    /// 应用可交互卡片样式
    func interactiveCard(action: @escaping () -> Void) -> some View {
        self.modifier(InteractiveCardModifier(action: action))
    }
}
