//
//  NavigationStyles.swift
//  ArtMe
//
//  紫色主题导航样式
//

import SwiftUI

// MARK: - Navigation Bar Configuration

/// 导航栏配置
struct NavigationBarConfiguration {
    /// 配置导航栏外观
    static func configure() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // 背景色
        appearance.backgroundColor = UIColor(ThemeColors.shared.background)
        
        // 标题颜色
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(ThemeColors.shared.textPrimary),
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        
        // 大标题颜色
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(ThemeColors.shared.textPrimary),
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        // 阴影
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
        
        // 应用配置
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // Tint color (按钮颜色)
        UINavigationBar.appearance().tintColor = UIColor(Color.purple600)
    }
}

// MARK: - Tab Bar Configuration

/// 标签栏配置
struct TabBarConfiguration {
    /// 配置标签栏外观
    static func configure() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // 背景色
        appearance.backgroundColor = UIColor(ThemeColors.shared.background)
        
        // 阴影
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
        
        // 选中项颜色
        let selectedColor = UIColor(Color.purple600)
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor
        ]
        
        // 未选中项颜色
        let unselectedColor = UIColor(Color.gray400)
        appearance.stackedLayoutAppearance.normal.iconColor = unselectedColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: unselectedColor
        ]
        
        // 应用配置
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Navigation View Modifier

/// 导航视图修饰器
struct ThemeNavigationModifier: ViewModifier {
    let title: String
    let displayMode: NavigationBarItem.TitleDisplayMode
    
    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(displayMode)
    }
}

extension View {
    /// 应用主题导航样式
    func themeNavigation(title: String, displayMode: NavigationBarItem.TitleDisplayMode = .large) -> some View {
        self.modifier(ThemeNavigationModifier(title: title, displayMode: displayMode))
    }
}

// MARK: - Custom Navigation Bar

/// 自定义导航栏
struct CustomNavigationBar<Leading: View, Trailing: View>: View {
    let title: String
    let leading: Leading
    let trailing: Trailing
    @Environment(\.colorScheme) var colorScheme
    
    init(
        title: String,
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.leading = leading()
        self.trailing = trailing()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                leading
                    .frame(width: 44, height: 44)
                
                Spacer()
                
                Text(title)
                    .textStyleHeadline()
                
                Spacer()
                
                trailing
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(backgroundColor)
            
            Divider()
        }
    }
    
    private var backgroundColor: Color {
        ThemeColors.shared.background
    }
}

// MARK: - Back Button

/// 自定义返回按钮
struct BackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                Text("返回")
                    .font(.themeBody)
            }
            .foregroundColor(.purple600)
        }
    }
}

// MARK: - Tab Bar Item

/// 自定义标签栏项
struct CustomTabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                
                Text(title)
                    .font(.themeCaption)
            }
            .foregroundColor(isSelected ? .purple600 : .gray400)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Custom Tab Bar

/// 自定义标签栏
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let items: [(icon: String, title: String)]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 0) {
                ForEach(0..<items.count, id: \.self) { index in
                    CustomTabBarItem(
                        icon: items[index].icon,
                        title: items[index].title,
                        isSelected: selectedTab == index
                    ) {
                        selectedTab = index
                    }
                }
            }
            .padding(.vertical, Spacing.sm)
            .background(backgroundColor)
        }
    }
    
    private var backgroundColor: Color {
        ThemeColors.shared.background
    }
}

// MARK: - Navigation Link Style

/// 导航链接样式
struct ThemeNavigationLinkModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.purple600)
    }
}

extension View {
    /// 应用主题导航链接样式
    func themeNavigationLink() -> some View {
        self.modifier(ThemeNavigationLinkModifier())
    }
}
