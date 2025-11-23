//
//  Shadow+Theme.swift
//  ArtMe
//
//  紫色主题阴影系统
//

import SwiftUI

// MARK: - Shadow System

/// 阴影系统
struct ThemeShadow {
    /// 小阴影
    static let sm = ShadowStyle(
        color: Color.black.opacity(0.1),
        radius: 2,
        x: 0,
        y: 1
    )
    
    /// 中阴影
    static let md = ShadowStyle(
        color: Color.black.opacity(0.1),
        radius: 4,
        x: 0,
        y: 2
    )
    
    /// 大阴影
    static let lg = ShadowStyle(
        color: Color.black.opacity(0.15),
        radius: 8,
        x: 0,
        y: 4
    )
    
    /// 超大阴影
    static let xl = ShadowStyle(
        color: Color.black.opacity(0.2),
        radius: 12,
        x: 0,
        y: 6
    )
    
    /// 紫色阴影（用于主要操作按钮）
    static let purple = ShadowStyle(
        color: Color.purple600.opacity(0.3),
        radius: 8,
        x: 0,
        y: 2
    )
    
    /// 深色模式小阴影
    static let smDark = ShadowStyle(
        color: Color.black.opacity(0.3),
        radius: 2,
        x: 0,
        y: 1
    )
    
    /// 深色模式中阴影
    static let mdDark = ShadowStyle(
        color: Color.black.opacity(0.3),
        radius: 4,
        x: 0,
        y: 2
    )
    
    /// 深色模式大阴影
    static let lgDark = ShadowStyle(
        color: Color.black.opacity(0.4),
        radius: 8,
        x: 0,
        y: 4
    )
}

/// 阴影样式
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Shadow View Modifiers

extension View {
    /// 应用小阴影
    func shadowSM(dark: Bool = false) -> some View {
        let shadow = dark ? ThemeShadow.smDark : ThemeShadow.sm
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
    
    /// 应用中阴影
    func shadowMD(dark: Bool = false) -> some View {
        let shadow = dark ? ThemeShadow.mdDark : ThemeShadow.md
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
    
    /// 应用大阴影
    func shadowLG(dark: Bool = false) -> some View {
        let shadow = dark ? ThemeShadow.lgDark : ThemeShadow.lg
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
    
    /// 应用超大阴影
    func shadowXL() -> some View {
        let shadow = ThemeShadow.xl
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
    
    /// 应用紫色阴影
    func shadowPurple() -> some View {
        let shadow = ThemeShadow.purple
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
    
    /// 根据颜色方案应用自适应阴影
    func shadowAdaptive(size: ShadowSize = .md) -> some View {
        self.modifier(AdaptiveShadowModifier(size: size))
    }
}

// MARK: - Shadow Size Enum

enum ShadowSize {
    case sm, md, lg, xl
}

// MARK: - Adaptive Shadow Modifier

struct AdaptiveShadowModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let size: ShadowSize
    
    func body(content: Content) -> some View {
        let isDark = colorScheme == .dark
        
        switch size {
        case .sm:
            return AnyView(content.shadowSM(dark: isDark))
        case .md:
            return AnyView(content.shadowMD(dark: isDark))
        case .lg:
            return AnyView(content.shadowLG(dark: isDark))
        case .xl:
            return AnyView(content.shadowXL())
        }
    }
}

// MARK: - Card Shadow Helpers

extension View {
    /// 应用卡片阴影（标准）
    func cardShadow() -> some View {
        self.shadowAdaptive(size: .md)
    }
    
    /// 应用卡片阴影（选中状态）
    func cardShadowSelected() -> some View {
        self.shadowPurple()
    }
    
    /// 应用按钮阴影
    func buttonShadow() -> some View {
        self.shadowPurple()
    }
}
