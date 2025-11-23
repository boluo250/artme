//
//  ThemeColorContrastTests.swift
//  ArtMeTests
//
//  颜色对比度测试
//  Feature: ios-purple-theme-design, Property 1: Color Contrast Compliance
//  Validates: Requirements 1.5
//

import XCTest
@testable import ArtMe
import SwiftUI

class ThemeColorContrastTests: XCTestCase {
    
    // MARK: - Helper Functions
    
    /// 计算两个颜色之间的对比度比率
    /// - Parameters:
    ///   - color1: 前景色
    ///   - color2: 背景色
    /// - Returns: 对比度比率
    func contrastRatio(between color1: UIColor, and color2: UIColor) -> CGFloat {
        let luminance1 = relativeLuminance(of: color1)
        let luminance2 = relativeLuminance(of: color2)
        
        let lighter = max(luminance1, luminance2)
        let darker = min(luminance1, luminance2)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    /// 计算颜色的相对亮度
    func relativeLuminance(of color: UIColor) -> CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let r = red <= 0.03928 ? red / 12.92 : pow((red + 0.055) / 1.055, 2.4)
        let g = green <= 0.03928 ? green / 12.92 : pow((green + 0.055) / 1.055, 2.4)
        let b = blue <= 0.03928 ? blue / 12.92 : pow((blue + 0.055) / 1.055, 2.4)
        
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
    
    /// 将SwiftUI Color转换为UIColor
    func uiColor(from color: Color) -> UIColor {
        return UIColor(color)
    }
    
    // MARK: - WCAG 2.1 AA Standards
    
    let normalTextMinimumRatio: CGFloat = 4.5  // 正文文字最小对比度
    let largeTextMinimumRatio: CGFloat = 3.0   // 大文字最小对比度
    
    // MARK: - Test Cases
    
    /// 测试主要按钮的颜色对比度
    func testPrimaryButtonContrast() {
        // 主要按钮：紫色背景 + 白色文字
        let background = uiColor(from: Color.purple600)
        let foreground = uiColor(from: Color.white)
        
        let ratio = contrastRatio(between: foreground, and: background)
        
        XCTAssertGreaterThanOrEqual(
            ratio,
            normalTextMinimumRatio,
            "主要按钮的文字对比度应满足 WCAG AA 标准 (4.5:1)，实际: \(String(format: "%.2f", ratio)):1"
        )
    }
    
    /// 测试次要按钮的颜色对比度（浅色模式）
    func testSecondaryButtonContrastLight() {
        // 次要按钮：浅紫色背景 + 深紫色文字
        let background = uiColor(from: Color.purple100)
        let foreground = uiColor(from: Color.purple600)
        
        let ratio = contrastRatio(between: foreground, and: background)
        
        XCTAssertGreaterThanOrEqual(
            ratio,
            normalTextMinimumRatio,
            "次要按钮（浅色模式）的文字对比度应满足 WCAG AA 标准，实际: \(String(format: "%.2f", ratio)):1"
        )
    }
    
    /// 测试主要文本颜色对比度（浅色模式）
    func testPrimaryTextContrastLight() {
        // 浅色模式：白色背景 + 深灰色文字
        let background = uiColor(from: Color.white)
        let foreground = uiColor(from: Color.gray900)
        
        let ratio = contrastRatio(between: foreground, and: background)
        
        XCTAssertGreaterThanOrEqual(
            ratio,
            normalTextMinimumRatio,
            "主要文本（浅色模式）的对比度应满足 WCAG AA 标准，实际: \(String(format: "%.2f", ratio)):1"
        )
    }
    
    /// 测试次要文本颜色对比度（浅色模式）
    func testSecondaryTextContrastLight() {
        // 浅色模式：白色背景 + 中灰色文字
        let background = uiColor(from: Color.white)
        let foreground = uiColor(from: Color.gray600)
        
        let ratio = contrastRatio(between: foreground, and: background)
        
        XCTAssertGreaterThanOrEqual(
            ratio,
            normalTextMinimumRatio,
            "次要文本（浅色模式）的对比度应满足 WCAG AA 标准，实际: \(String(format: "%.2f", ratio)):1"
        )
    }
    
    /// 测试主要文本颜色对比度（深色模式）
    func testPrimaryTextContrastDark() {
        // 深色模式：深灰色背景 + 浅灰色文字
        let background = uiColor(from: Color.gray900)
        let foreground = uiColor(from: Color.gray100)
        
        let ratio = contrastRatio(between: foreground, and: background)
        
        XCTAssertGreaterThanOrEqual(
            ratio,
            normalTextMinimumRatio,
            "主要文本（深色模式）的对比度应满足 WCAG AA 标准，实际: \(String(format: "%.2f", ratio)):1"
        )
    }
    
    /// 测试语义色对比度 - 成功
    func testSuccessColorContrast() {
        let background = uiColor(from: Color.white)
        let foreground = uiColor(from: Color.success)
        
        let ratio = contrastRatio(between: foreground, and: background)
        
        XCTAssertGreaterThanOrEqual(
            ratio,
            normalTextMinimumRatio,
            "成功色的对比度应满足 WCAG AA 标准，实际: \(String(format: "%.2f", ratio)):1"
        )
    }
    
    /// 测试语义色对比度 - 错误
    func testErrorColorContrast() {
        let background = uiColor(from: Color.white)
        let foreground = uiColor(from: Color.error)
        
        let ratio = contrastRatio(between: foreground, and: background)
        
        XCTAssertGreaterThanOrEqual(
            ratio,
            normalTextMinimumRatio,
            "错误色的对比度应满足 WCAG AA 标准，实际: \(String(format: "%.2f", ratio)):1"
        )
    }
    
    /// 测试语义色对比度 - 警告
    func testWarningColorContrast() {
        let background = uiColor(from: Color.white)
        let foreground = uiColor(from: Color.warning)
        
        let ratio = contrastRatio(between: foreground, and: background)
        
        XCTAssertGreaterThanOrEqual(
            ratio,
            normalTextMinimumRatio,
            "警告色的对比度应满足 WCAG AA 标准，实际: \(String(format: "%.2f", ratio)):1"
        )
    }
    
    /// 测试紫色主色调在白色背景上的对比度
    func testPurplePrimaryOnWhiteContrast() {
        let background = uiColor(from: Color.white)
        let foreground = uiColor(from: Color.purple600)
        
        let ratio = contrastRatio(between: foreground, and: background)
        
        XCTAssertGreaterThanOrEqual(
            ratio,
            normalTextMinimumRatio,
            "紫色主色调在白色背景上的对比度应满足 WCAG AA 标准，实际: \(String(format: "%.2f", ratio)):1"
        )
    }
    
    /// 测试卡片选中状态的边框对比度
    func testSelectedCardBorderContrast() {
        // 选中卡片：白色背景 + 紫色边框
        let background = uiColor(from: Color.white)
        let border = uiColor(from: Color.purple600)
        
        let ratio = contrastRatio(between: border, and: background)
        
        XCTAssertGreaterThanOrEqual(
            ratio,
            largeTextMinimumRatio,
            "选中卡片边框的对比度应满足 WCAG AA 标准（大元素），实际: \(String(format: "%.2f", ratio)):1"
        )
    }
    
    // MARK: - Property-Based Test Simulation
    
    /// 模拟属性测试：测试所有紫色变体在白色背景上的对比度
    func testAllPurpleVariantsOnWhiteBackground() {
        let background = uiColor(from: Color.white)
        let purpleColors: [(String, Color)] = [
            ("purple300", Color.purple300),
            ("purple400", Color.purple400),
            ("purple500", Color.purple500),
            ("purple600", Color.purple600),
            ("purple700", Color.purple700),
            ("purple800", Color.purple800),
            ("purple900", Color.purple900)
        ]
        
        for (name, color) in purpleColors {
            let foreground = uiColor(from: color)
            let ratio = contrastRatio(between: foreground, and: background)
            
            // 深色紫色应该满足对比度要求
            if name >= "purple600" {
                XCTAssertGreaterThanOrEqual(
                    ratio,
                    normalTextMinimumRatio,
                    "\(name) 在白色背景上的对比度应满足 WCAG AA 标准，实际: \(String(format: "%.2f", ratio)):1"
                )
            }
        }
    }
    
    /// 模拟属性测试：测试所有灰色变体的对比度
    func testAllGrayVariantsContrast() {
        let lightBackground = uiColor(from: Color.white)
        let darkBackground = uiColor(from: Color.gray900)
        
        // 测试深色灰度在浅色背景上
        let darkGrays: [(String, Color)] = [
            ("gray600", Color.gray600),
            ("gray700", Color.gray700),
            ("gray800", Color.gray800),
            ("gray900", Color.gray900)
        ]
        
        for (name, color) in darkGrays {
            let foreground = uiColor(from: color)
            let ratio = contrastRatio(between: foreground, and: lightBackground)
            
            XCTAssertGreaterThanOrEqual(
                ratio,
                normalTextMinimumRatio,
                "\(name) 在白色背景上的对比度应满足 WCAG AA 标准，实际: \(String(format: "%.2f", ratio)):1"
            )
        }
        
        // 测试浅色灰度在深色背景上
        let lightGrays: [(String, Color)] = [
            ("gray100", Color.gray100),
            ("gray200", Color.gray200),
            ("gray300", Color.gray300)
        ]
        
        for (name, color) in lightGrays {
            let foreground = uiColor(from: color)
            let ratio = contrastRatio(between: foreground, and: darkBackground)
            
            XCTAssertGreaterThanOrEqual(
                ratio,
                normalTextMinimumRatio,
                "\(name) 在深色背景上的对比度应满足 WCAG AA 标准，实际: \(String(format: "%.2f", ratio)):1"
            )
        }
    }
}
