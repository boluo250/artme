//
//  ThemeManager.swift
//  ArtMe
//
//  紫色主题管理器
//

import SwiftUI
import Combine

// MARK: - Theme Configuration

/// 主题配置
struct ThemeConfiguration {
    let colors: ThemeColors
    let typography: TypographySystem
    let spacing: SpacingSystem
    let cornerRadius: CornerRadiusSystem
    let shadows: ShadowSystem
    
    /// 默认主题配置
    static let `default` = ThemeConfiguration(
        colors: .shared,
        typography: .shared,
        spacing: SpacingSystem(),
        cornerRadius: CornerRadiusSystem(),
        shadows: ShadowSystem()
    )
}

// MARK: - Spacing System

/// 间距系统配置
struct SpacingSystem {
    let xs: CGFloat = Spacing.xs
    let sm: CGFloat = Spacing.sm
    let md: CGFloat = Spacing.md
    let lg: CGFloat = Spacing.lg
    let xl: CGFloat = Spacing.xl
    let xxl: CGFloat = Spacing.xxl
}

// MARK: - Corner Radius System

/// 圆角系统配置
struct CornerRadiusSystem {
    let sm: CGFloat = CornerRadius.sm
    let md: CGFloat = CornerRadius.md
    let lg: CGFloat = CornerRadius.lg
    let xl: CGFloat = CornerRadius.xl
    let full: CGFloat = CornerRadius.full
}

// MARK: - Shadow System

/// 阴影系统配置
struct ShadowSystem {
    let sm: ShadowStyle = ThemeShadow.sm
    let md: ShadowStyle = ThemeShadow.md
    let lg: ShadowStyle = ThemeShadow.lg
    let xl: ShadowStyle = ThemeShadow.xl
    let purple: ShadowStyle = ThemeShadow.purple
}

// MARK: - Theme Manager

/// 主题管理器
class ThemeManager: ObservableObject {
    /// 单例实例
    static let shared = ThemeManager()
    
    /// 当前主题配置
    @Published var configuration: ThemeConfiguration
    
    private init() {
        self.configuration = .default
    }
    
    /// 初始化主题
    func initialize() {
        // 配置导航栏
        NavigationBarConfiguration.configure()
        
        // 配置标签栏
        TabBarConfiguration.configure()
    }
    
    /// 更新主题配置
    func updateConfiguration(_ configuration: ThemeConfiguration) {
        self.configuration = configuration
    }
}

// MARK: - Theme Environment Key

/// 主题环境键
struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: ThemeConfiguration = .default
}

extension EnvironmentValues {
    var theme: ThemeConfiguration {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// MARK: - Theme Modifier

/// 主题修饰器
struct ThemeModifier: ViewModifier {
    @ObservedObject var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .environment(\.theme, themeManager.configuration)
    }
}

extension View {
    /// 应用主题
    func withTheme() -> some View {
        self.modifier(ThemeModifier())
    }
}

// MARK: - Theme Initialization

/// 主题初始化器
struct ThemeInitializer: ViewModifier {
    init() {
        ThemeManager.shared.initialize()
    }
    
    func body(content: Content) -> some View {
        content
    }
}

extension View {
    /// 初始化主题（在应用启动时调用）
    func initializeTheme() -> some View {
        self.modifier(ThemeInitializer())
    }
}
