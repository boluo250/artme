//
//  ThemeShowcaseView.swift
//  ArtMe
//
//  主题展示视图 - 用于演示所有设计系统组件
//

import SwiftUI

struct ThemeShowcaseView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                ColorShowcaseView()
                    .tabItem {
                        Label("颜色", systemImage: "paintpalette")
                    }
                    .tag(0)
                
                TypographyShowcaseView()
                    .tabItem {
                        Label("字体", systemImage: "textformat")
                    }
                    .tag(1)
                
                ButtonShowcaseView()
                    .tabItem {
                        Label("按钮", systemImage: "button.programmable")
                    }
                    .tag(2)
                
                ComponentShowcaseView()
                    .tabItem {
                        Label("组件", systemImage: "square.stack.3d.up")
                    }
                    .tag(3)
            }
            .navigationTitle("主题展示")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Color Showcase

struct ColorShowcaseView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                // 主紫色调色板
                ColorSection(title: "主紫色调色板") {
                    ColorRow(name: "purple50", color: .purple50)
                    ColorRow(name: "purple100", color: .purple100)
                    ColorRow(name: "purple200", color: .purple200)
                    ColorRow(name: "purple300", color: .purple300)
                    ColorRow(name: "purple400", color: .purple400)
                    ColorRow(name: "purple500", color: .purple500)
                    ColorRow(name: "purple600", color: .purple600)
                    ColorRow(name: "purple700", color: .purple700)
                    ColorRow(name: "purple800", color: .purple800)
                    ColorRow(name: "purple900", color: .purple900)
                }
                
                // 辅助色
                ColorSection(title: "辅助色") {
                    ColorRow(name: "pink500", color: .pink500)
                    ColorRow(name: "indigo500", color: .indigo500)
                    ColorRow(name: "violet500", color: .violet500)
                }
                
                // 中性色
                ColorSection(title: "中性色") {
                    ColorRow(name: "gray50", color: .gray50)
                    ColorRow(name: "gray100", color: .gray100)
                    ColorRow(name: "gray200", color: .gray200)
                    ColorRow(name: "gray300", color: .gray300)
                    ColorRow(name: "gray400", color: .gray400)
                    ColorRow(name: "gray500", color: .gray500)
                    ColorRow(name: "gray600", color: .gray600)
                    ColorRow(name: "gray700", color: .gray700)
                    ColorRow(name: "gray800", color: .gray800)
                    ColorRow(name: "gray900", color: .gray900)
                }
                
                // 语义色
                ColorSection(title: "语义色") {
                    ColorRow(name: "success", color: .success)
                    ColorRow(name: "warning", color: .warning)
                    ColorRow(name: "error", color: .error)
                    ColorRow(name: "info", color: .info)
                }
            }
            .pagePadding()
        }
    }
}

struct ColorSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .textStyleTitle2()
            
            VStack(spacing: Spacing.sm) {
                content
            }
        }
    }
}

struct ColorRow: View {
    let name: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(color)
                .frame(width: 60, height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .stroke(Color.gray200, lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(name)
                    .textStyleHeadline()
                Text("Color.\(name)")
                    .textStyleCaption()
                    .foregroundColor(.gray500)
            }
            
            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.adaptive(light: .gray50, dark: .gray800))
        .cornerRadiusSM()
    }
}

// MARK: - Typography Showcase

struct TypographyShowcaseView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                TypographySection(title: "标题层级") {
                    TypographyRow(name: "Large Title", font: .themeLargeTitle, text: "大标题样式")
                    TypographyRow(name: "Title 1", font: .themeTitle1, text: "标题1样式")
                    TypographyRow(name: "Title 2", font: .themeTitle2, text: "标题2样式")
                    TypographyRow(name: "Title 3", font: .themeTitle3, text: "标题3样式")
                    TypographyRow(name: "Headline", font: .themeHeadline, text: "标题样式")
                }
                
                TypographySection(title: "正文层级") {
                    TypographyRow(name: "Body", font: .themeBody, text: "正文样式")
                    TypographyRow(name: "Callout", font: .themeCallout, text: "强调文字样式")
                    TypographyRow(name: "Subheadline", font: .themeSubheadline, text: "副标题样式")
                    TypographyRow(name: "Footnote", font: .themeFootnote, text: "脚注样式")
                    TypographyRow(name: "Caption", font: .themeCaption, text: "说明样式")
                }
            }
            .pagePadding()
        }
    }
}

struct TypographySection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .textStyleTitle2()
            
            VStack(spacing: Spacing.md) {
                content
            }
        }
    }
}

struct TypographyRow: View {
    let name: String
    let font: Font
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(name)
                .textStyleCaption()
                .foregroundColor(.gray500)
            
            Text(text)
                .font(font)
                .textColorPrimary()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Color.adaptive(light: .gray50, dark: .gray800))
        .cornerRadiusSM()
    }
}

// MARK: - Button Showcase

struct ButtonShowcaseView: View {
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                ButtonSection(title: "主要按钮") {
                    Button("主要按钮") {}
                        .primaryButtonStyle()
                    
                    Button("加载中") {}
                        .primaryButtonStyle()
                        .loading(true)
                    
                    Button("禁用状态") {}
                        .primaryButtonStyle()
                        .disabled(true)
                }
                
                ButtonSection(title: "次要按钮") {
                    Button("次要按钮") {}
                        .secondaryButtonStyle()
                    
                    Button("禁用状态") {}
                        .secondaryButtonStyle()
                        .disabled(true)
                }
                
                ButtonSection(title: "描边按钮") {
                    Button("描边按钮") {}
                        .outlineButtonStyle()
                    
                    Button("禁用状态") {}
                        .outlineButtonStyle()
                        .disabled(true)
                }
                
                ButtonSection(title: "文本按钮") {
                    Button("文本按钮") {}
                        .textButtonStyle()
                    
                    Button("禁用状态") {}
                        .textButtonStyle()
                        .disabled(true)
                }
                
                ButtonSection(title: "图标按钮") {
                    HStack(spacing: Spacing.lg) {
                        Button {
                        } label: {
                            Image(systemName: "heart.fill")
                        }
                        .iconButtonStyle(size: .small, variant: .primary)
                        
                        Button {
                        } label: {
                            Image(systemName: "star.fill")
                        }
                        .iconButtonStyle(size: .medium, variant: .secondary)
                        
                        Button {
                        } label: {
                            Image(systemName: "plus")
                        }
                        .iconButtonStyle(size: .large, variant: .circle)
                    }
                }
            }
            .pagePadding()
        }
    }
}

struct ButtonSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .textStyleTitle3()
            
            VStack(spacing: Spacing.md) {
                content
            }
        }
    }
}

// MARK: - Component Showcase

struct ComponentShowcaseView: View {
    @State private var showToast = false
    @State private var textInput = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                ComponentSection(title: "卡片") {
                    VStack(spacing: Spacing.md) {
                        Text("标准卡片")
                            .textStyleBody()
                    }
                    .styledCard()
                    
                    VStack(spacing: Spacing.md) {
                        Text("选中卡片")
                            .textStyleBody()
                    }
                    .styledSelectedCard(isSelected: true)
                }
                
                ComponentSection(title: "输入框") {
                    TextField("标准输入框", text: $textInput)
                        .themeTextField()
                    
                    TextField("描边输入框", text: $textInput)
                        .outlinedTextField()
                    
                    TextField("搜索框", text: $textInput)
                        .searchField()
                }
                
                ComponentSection(title: "提示横幅") {
                    AlertBanner(type: .success, message: "操作成功！")
                    AlertBanner(type: .error, message: "发生错误")
                    AlertBanner(type: .warning, message: "警告信息")
                    AlertBanner(type: .info, message: "提示信息")
                }
                
                ComponentSection(title: "空状态") {
                    EmptyStateView(
                        icon: "photo",
                        title: "暂无内容",
                        message: "这里还没有任何内容",
                        actionTitle: "添加内容"
                    ) {
                        print("添加内容")
                    }
                }
                
                ComponentSection(title: "徽章") {
                    HStack(spacing: Spacing.md) {
                        Badge(text: "新")
                        Badge(text: "热门", color: .error)
                        Badge(text: "推荐", color: .success)
                    }
                }
                
                ComponentSection(title: "通知点") {
                    HStack(spacing: Spacing.xl) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.purple600)
                            NotificationDot(count: 5)
                                .offset(x: 8, y: -8)
                        }
                        
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.purple600)
                            NotificationDot(count: 99)
                                .offset(x: 8, y: -8)
                        }
                    }
                }
            }
            .pagePadding()
        }
    }
}

struct ComponentSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .textStyleTitle3()
            
            VStack(spacing: Spacing.md) {
                content
            }
        }
    }
}

#Preview {
    ThemeShowcaseView()
}
