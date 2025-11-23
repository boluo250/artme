//
//  Spacing+Theme.swift
//  ArtMe
//
//  紫色主题间距系统
//

import SwiftUI

// MARK: - Spacing System

/// 间距系统
struct Spacing {
    /// 超小间距 - 4pt
    static let xs: CGFloat = 4
    
    /// 小间距 - 8pt
    static let sm: CGFloat = 8
    
    /// 中间距 - 12pt
    static let md: CGFloat = 12
    
    /// 大间距 - 16pt
    static let lg: CGFloat = 16
    
    /// 超大间距 - 24pt
    static let xl: CGFloat = 24
    
    /// 特大间距 - 32pt
    static let xxl: CGFloat = 32
    
    /// 巨大间距 - 48pt
    static let xxxl: CGFloat = 48
}

// MARK: - Spacing View Modifiers

extension View {
    /// 应用超小内边距（4pt）
    func paddingXS() -> some View {
        self.padding(Spacing.xs)
    }
    
    /// 应用小内边距（8pt）
    func paddingSM() -> some View {
        self.padding(Spacing.sm)
    }
    
    /// 应用中内边距（12pt）
    func paddingMD() -> some View {
        self.padding(Spacing.md)
    }
    
    /// 应用大内边距（16pt）
    func paddingLG() -> some View {
        self.padding(Spacing.lg)
    }
    
    /// 应用超大内边距（24pt）
    func paddingXL() -> some View {
        self.padding(Spacing.xl)
    }
    
    /// 应用特大内边距（32pt）
    func paddingXXL() -> some View {
        self.padding(Spacing.xxl)
    }
    
    /// 应用水平内边距
    func paddingHorizontal(_ value: CGFloat) -> some View {
        self.padding(.horizontal, value)
    }
    
    /// 应用垂直内边距
    func paddingVertical(_ value: CGFloat) -> some View {
        self.padding(.vertical, value)
    }
}

// MARK: - Spacing Helpers

extension View {
    /// 创建垂直间隔
    static func verticalSpacer(_ height: CGFloat) -> some View {
        Spacer()
            .frame(height: height)
    }
    
    /// 创建水平间隔
    static func horizontalSpacer(_ width: CGFloat) -> some View {
        Spacer()
            .frame(width: width)
    }
}

// MARK: - Standard Spacers

extension Spacer {
    /// 超小垂直间隔（4pt）
    static var xs: some View {
        Spacer().frame(height: Spacing.xs)
    }
    
    /// 小垂直间隔（8pt）
    static var sm: some View {
        Spacer().frame(height: Spacing.sm)
    }
    
    /// 中垂直间隔（12pt）
    static var md: some View {
        Spacer().frame(height: Spacing.md)
    }
    
    /// 大垂直间隔（16pt）
    static var lg: some View {
        Spacer().frame(height: Spacing.lg)
    }
    
    /// 超大垂直间隔（24pt）
    static var xl: some View {
        Spacer().frame(height: Spacing.xl)
    }
    
    /// 特大垂直间隔（32pt）
    static var xxl: some View {
        Spacer().frame(height: Spacing.xxl)
    }
}
