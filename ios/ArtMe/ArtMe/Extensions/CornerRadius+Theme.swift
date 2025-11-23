//
//  CornerRadius+Theme.swift
//  ArtMe
//
//  紫色主题圆角系统
//

import SwiftUI

// MARK: - Corner Radius System

/// 圆角系统
struct CornerRadius {
    /// 小圆角 - 8pt
    static let sm: CGFloat = 8
    
    /// 中圆角 - 12pt
    static let md: CGFloat = 12
    
    /// 大圆角 - 16pt
    static let lg: CGFloat = 16
    
    /// 超大圆角 - 20pt
    static let xl: CGFloat = 20
    
    /// 圆形 - 9999pt
    static let full: CGFloat = 9999
}

// MARK: - Corner Radius View Modifiers

extension View {
    /// 应用小圆角（8pt）
    func cornerRadiusSM() -> some View {
        self.cornerRadius(CornerRadius.sm)
    }
    
    /// 应用中圆角（12pt）
    func cornerRadiusMD() -> some View {
        self.cornerRadius(CornerRadius.md)
    }
    
    /// 应用大圆角（16pt）
    func cornerRadiusLG() -> some View {
        self.cornerRadius(CornerRadius.lg)
    }
    
    /// 应用超大圆角（20pt）
    func cornerRadiusXL() -> some View {
        self.cornerRadius(CornerRadius.xl)
    }
    
    /// 应用圆形圆角
    func cornerRadiusFull() -> some View {
        self.cornerRadius(CornerRadius.full)
    }
}

// MARK: - Rounded Rectangle Helpers

extension View {
    /// 应用圆角矩形裁剪（小）
    func clipShapeSM() -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
    }
    
    /// 应用圆角矩形裁剪（中）
    func clipShapeMD() -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }
    
    /// 应用圆角矩形裁剪（大）
    func clipShapeLG() -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
    }
    
    /// 应用圆角矩形裁剪（超大）
    func clipShapeXL() -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
    }
    
    /// 应用圆形裁剪
    func clipShapeCircle() -> some View {
        self.clipShape(Circle())
    }
}
