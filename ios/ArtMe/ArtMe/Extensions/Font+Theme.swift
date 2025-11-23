//
//  Font+Theme.swift
//  ArtMe
//
//  紫色主题字体系统
//

import SwiftUI

extension Font {
    // MARK: - Font Hierarchy
    
    /// 大标题 - 34pt, Bold
    /// 用于页面主标题
    static let themeLargeTitle = Font.system(size: 34, weight: .bold)
    
    /// 标题1 - 28pt, Bold
    /// 用于区块标题
    static let themeTitle1 = Font.system(size: 28, weight: .bold)
    
    /// 标题2 - 22pt, Semibold
    /// 用于卡片标题
    static let themeTitle2 = Font.system(size: 22, weight: .semibold)
    
    /// 标题3 - 20pt, Semibold
    /// 用于小节标题
    static let themeTitle3 = Font.system(size: 20, weight: .semibold)
    
    /// 标题 - 17pt, Semibold
    /// 用于列表标题
    static let themeHeadline = Font.system(size: 17, weight: .semibold)
    
    /// 正文 - 17pt, Regular
    /// 用于主要内容
    static let themeBody = Font.system(size: 17, weight: .regular)
    
    /// 强调文字 - 16pt, Regular
    /// 用于次要内容
    static let themeCallout = Font.system(size: 16, weight: .regular)
    
    /// 副标题 - 15pt, Regular
    /// 用于辅助信息
    static let themeSubheadline = Font.system(size: 15, weight: .regular)
    
    /// 脚注 - 13pt, Regular
    /// 用于说明文字
    static let themeFootnote = Font.system(size: 13, weight: .regular)
    
    /// 说明 - 12pt, Regular
    /// 用于图片说明、时间戳
    static let themeCaption = Font.system(size: 12, weight: .regular)
}

// MARK: - Dynamic Type Support

extension Font {
    /// 大标题（支持动态字体）
    static var themeLargeTitleDynamic: Font {
        .system(.largeTitle, design: .default, weight: .bold)
    }
    
    /// 标题1（支持动态字体）
    static var themeTitle1Dynamic: Font {
        .system(.title, design: .default, weight: .bold)
    }
    
    /// 标题2（支持动态字体）
    static var themeTitle2Dynamic: Font {
        .system(.title2, design: .default, weight: .semibold)
    }
    
    /// 标题3（支持动态字体）
    static var themeTitle3Dynamic: Font {
        .system(.title3, design: .default, weight: .semibold)
    }
    
    /// 标题（支持动态字体）
    static var themeHeadlineDynamic: Font {
        .system(.headline, design: .default, weight: .semibold)
    }
    
    /// 正文（支持动态字体）
    static var themeBodyDynamic: Font {
        .system(.body, design: .default, weight: .regular)
    }
    
    /// 强调文字（支持动态字体）
    static var themeCalloutDynamic: Font {
        .system(.callout, design: .default, weight: .regular)
    }
    
    /// 副标题（支持动态字体）
    static var themeSubheadlineDynamic: Font {
        .system(.subheadline, design: .default, weight: .regular)
    }
    
    /// 脚注（支持动态字体）
    static var themeFootnoteDynamic: Font {
        .system(.footnote, design: .default, weight: .regular)
    }
    
    /// 说明（支持动态字体）
    static var themeCaptionDynamic: Font {
        .system(.caption, design: .default, weight: .regular)
    }
}

// MARK: - Text Color Modifiers

extension View {
    /// 应用主要文本颜色
    func textColorPrimary() -> some View {
        self.foregroundColor(.adaptive(light: .gray900, dark: .gray100))
    }
    
    /// 应用次要文本颜色
    func textColorSecondary() -> some View {
        self.foregroundColor(.adaptive(light: .gray600, dark: .gray400))
    }
    
    /// 应用禁用文本颜色
    func textColorDisabled() -> some View {
        self.foregroundColor(.adaptive(light: .gray400, dark: .gray500))
    }
    
    /// 应用标题文本颜色
    func textColorTitle() -> some View {
        self.foregroundColor(.adaptive(light: .gray900, dark: .gray100))
    }
    
    /// 应用正文文本颜色
    func textColorBody() -> some View {
        self.foregroundColor(.adaptive(light: .gray700, dark: .gray300))
    }
    
    /// 应用说明文本颜色
    func textColorCaption() -> some View {
        self.foregroundColor(.adaptive(light: .gray500, dark: .gray500))
    }
}

// MARK: - Typography System

/// 字体系统配置
struct TypographySystem {
    // Fixed Size Fonts
    let largeTitle: Font = .themeLargeTitle
    let title1: Font = .themeTitle1
    let title2: Font = .themeTitle2
    let title3: Font = .themeTitle3
    let headline: Font = .themeHeadline
    let body: Font = .themeBody
    let callout: Font = .themeCallout
    let subheadline: Font = .themeSubheadline
    let footnote: Font = .themeFootnote
    let caption: Font = .themeCaption
    
    // Dynamic Type Fonts
    let largeTitleDynamic: Font = .themeLargeTitleDynamic
    let title1Dynamic: Font = .themeTitle1Dynamic
    let title2Dynamic: Font = .themeTitle2Dynamic
    let title3Dynamic: Font = .themeTitle3Dynamic
    let headlineDynamic: Font = .themeHeadlineDynamic
    let bodyDynamic: Font = .themeBodyDynamic
    let calloutDynamic: Font = .themeCalloutDynamic
    let subheadlineDynamic: Font = .themeSubheadlineDynamic
    let footnoteDynamic: Font = .themeFootnoteDynamic
    let captionDynamic: Font = .themeCaptionDynamic
    
    /// 单例实例
    static let shared = TypographySystem()
}

// MARK: - Text Style Modifiers

extension View {
    /// 应用大标题样式
    func textStyleLargeTitle(dynamic: Bool = true) -> some View {
        self
            .font(dynamic ? .themeLargeTitleDynamic : .themeLargeTitle)
            .textColorTitle()
    }
    
    /// 应用标题1样式
    func textStyleTitle1(dynamic: Bool = true) -> some View {
        self
            .font(dynamic ? .themeTitle1Dynamic : .themeTitle1)
            .textColorTitle()
    }
    
    /// 应用标题2样式
    func textStyleTitle2(dynamic: Bool = true) -> some View {
        self
            .font(dynamic ? .themeTitle2Dynamic : .themeTitle2)
            .foregroundColor(.adaptive(light: .gray800, dark: .gray200))
    }
    
    /// 应用标题3样式
    func textStyleTitle3(dynamic: Bool = true) -> some View {
        self
            .font(dynamic ? .themeTitle3Dynamic : .themeTitle3)
            .foregroundColor(.adaptive(light: .gray800, dark: .gray200))
    }
    
    /// 应用标题样式
    func textStyleHeadline(dynamic: Bool = true) -> some View {
        self
            .font(dynamic ? .themeHeadlineDynamic : .themeHeadline)
            .textColorTitle()
    }
    
    /// 应用正文样式
    func textStyleBody(dynamic: Bool = true) -> some View {
        self
            .font(dynamic ? .themeBodyDynamic : .themeBody)
            .textColorBody()
    }
    
    /// 应用强调文字样式
    func textStyleCallout(dynamic: Bool = true) -> some View {
        self
            .font(dynamic ? .themeCalloutDynamic : .themeCallout)
            .textColorSecondary()
    }
    
    /// 应用副标题样式
    func textStyleSubheadline(dynamic: Bool = true) -> some View {
        self
            .font(dynamic ? .themeSubheadlineDynamic : .themeSubheadline)
            .textColorSecondary()
    }
    
    /// 应用脚注样式
    func textStyleFootnote(dynamic: Bool = true) -> some View {
        self
            .font(dynamic ? .themeFootnoteDynamic : .themeFootnote)
            .textColorCaption()
    }
    
    /// 应用说明样式
    func textStyleCaption(dynamic: Bool = true) -> some View {
        self
            .font(dynamic ? .themeCaptionDynamic : .themeCaption)
            .textColorCaption()
    }
}

// MARK: - Font Weight Helpers

extension Font {
    /// 创建指定大小和字重的字体
    static func themeFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
    
    /// 创建支持动态字体的指定样式和字重的字体
    static func themeFontDynamic(style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .default, weight: weight)
    }
}

// MARK: - Line Height and Spacing

extension View {
    /// 应用标准行间距
    func lineSpacingStandard() -> some View {
        self.lineSpacing(4)
    }
    
    /// 应用紧凑行间距
    func lineSpacingCompact() -> some View {
        self.lineSpacing(2)
    }
    
    /// 应用宽松行间距
    func lineSpacingRelaxed() -> some View {
        self.lineSpacing(8)
    }
}
