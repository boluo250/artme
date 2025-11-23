//
//  PurpleBackgroundReadabilityTests.swift
//  ArtMeTests
//
//  紫色背景文本可读性测试
//  Feature: ios-purple-theme-design, Property 2: Purple Background Text Readability
//  Validates: Requirements 2.5
//

import XCTest
@testable import ArtMe
import SwiftUI

class PurpleBackgroundReadabilityTests: XCTestCase {
    
    // MARK: - Helper Functions
    
    /// 计算两个颜色之间的对比度比率
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
    
    // MARK: - Purple Background Colors
    
    let purpleBackgrounds: [(String, Color)] = [
        ("purple50", Color.purple50),
        ("purple100", Color.purple100),
        ("purple200", Color.purple200),
        ("purple300", Color.purple300),
        ("purple400", Color.purple400),
        ("purple500", Color.purple500),
        ("purple600", Color.purple600),
        ("purple700", Color.purple700),
        ("purple800", Color.purple800),
        ("purple900", Color.purple900)
    ]
    
    // MARK: - Text Colors from Typography System
    
    let textColors: [(String, Color)] = [
        ("white", Color.white),
        ("gray100", Color.gray100),
        ("gray200", Color.gray200),
        ("gray300", Color.gray300),
        ("gray400", Color.gray400),
        ("gray500", Color.gray500),
        ("gray600", Color.gray600),
        ("gray700", Color.gray700),
        ("gray800", Color.gray800),
        ("gray900", Color.gray900)
    ]
    
    // MARK: - Test Cases
    
    /// 测试白色文字在所有紫色背景上的可读性
    func testWhiteTextOnPurpleBackgrounds() {
        let textColor = uiColor(from: Color.white)
        
        for (name, backgroundColor) in purpleBackgrounds {
            let bgColor = uiColor(from: backgroundColor)
            let ratio = contrastRatio(between: textColor, and: bgColor)
            
            // 深色紫色背景（purple500及以上）应该与白色文字有足够对比度
            if name >= "purple500" {
                XCTAssertGreaterThanOrEqual(
                    ratio,
                    normalTextMinimumRatio,
                    "白色文字在 \(name) 背景上的对比度应满足 WCAG AA 标准，实际: \(String(format: "%.2f", ratio)):1"
                )
            }
        }
    }
    
    /// 测试深色文字在浅紫色背景上的可读性
    func testDarkTextOnLightPurpleBackgrounds() {
        let lightPurples = purpleBackgrounds.filter { $0.0 <= "purple300" }
        let darkTexts = textColors.filter { $0.0 >= "gray700" }
        
        for (bgName, bgColor) in lightPurples {
            for (textName, textColor) in darkTexts {
                let bg = uiColor(from: bgColor)
                let text = uiColor(from: textColor)
                let ratio = contrastRatio(between: text, and: bg)
                
                XCTAssertGreaterThanOrEqual(
                    ratio,
                    normalTextMinimumRatio,
                    "\(textName) 文字在 \(bgName) 背景上的对比度应满足 WCAG AA 标准，实际: \(String(format: "%.2f", ratio)):1"
                )
            }
        }
    }
    
    /// 测试浅色文字在深紫色背景上的可读性
    func testLightTextOnDarkPurpleBackgrounds() {
        let darkPurples = purpleBackgrounds.filter { $0.0 >= "purple600" }
        let lightTexts = textColors.filter { $0.0 <= "gray300" || $0.0 == "white" }
        
        for (bgName, bgColor) in darkPurples {
            for (textName, textColor) in lightTexts {
                let bg = uiColor(from: bgColor)
                let text = uiColor(from: textColor)
                let ratio = contrastRatio(between: text, and: bg)
                
                XCTAssertGreaterThanOrEqual(
                    ratio,
                    normalTextMinimumRatio,
                    "\(textName) 文字在 \(bgName) 背景上的对比度应满足 WCAG AA 标准，实际: \(String(format: "%.2f", ratio)):1"
                )
            }
        }
    }
    
    /// 测试主要按钮（purple600背景 + 白色文字）
    func testPrimaryButtonReadability() {
        let background = uiColor(from: Color.purple600)
        let text = uiColor(from: Color.white)
        
        let ratio = contrastRatio(between: text, and: background)
        
        XCTAssertGreaterThanOrEqual(
            ratio,
            normalTextMinimumRatio,
            "主要按钮（purple600 + 白色）的对比度应满足 WCAG AA 标准，实际: \(String(format: "%.2f", ratio)):1"
        )
    }
    
    /// 测试次要按钮（purple100背景 + purple600文字）
    func testSecondaryButtonReadability() {
        let background = uiColor(from: Color.purple100)
        let text = uiColor(from: Color.purple600)
        
        let ratio = contrastRatio(between: text, and: background)
        
        XCTAssertGreaterThanOrEqual(
            ratio,
            normalTextMinimumRatio,
            "次要按钮（purple100 + purple600）的对比度应满足 WCAG AA 标准，实际: \(String(format: "%.2f", ratio)):1"
        )
    }
    
    /// 测试选中的分类标签（purple600背景 + 白色文字）
    func testSelectedCategoryChipReadability() {
        let background = uiColor(from: Color.purple600)
        let text = uiColor(from: Color.white)
        
        let ratio = contrastRatio(between: text, and: background)
        
        XCTAssertGreaterThanOrEqual(
            ratio,
            normalTextMinimumRatio,
            "选中分类标签的对比度应满足 WCAG AA 标准，实际: \(String(format: "%.2f", ratio)):1"
        )
    }
    
    /// 测试紫色链接文字在白色背景上的可读性
    func testPurpleLinkOnWhiteBackground() {
        let background = uiColor(from: Color.white)
        let link = uiColor(from: Color.purple600)
        
        let ratio = contrastRatio(between: link, and: background)
        
        XCTAssertGreaterThanOrEqual(
            ratio,
            normalTextMinimumRatio,
            "紫色链接在白色背景上的对比度应满足 WCAG AA 标准，实际: \(String(format: "%.2f", ratio)):1"
        )
    }
    
    /// 测试紫色价格文字在白色背景上的可读性
    func testPurplePriceOnWhiteBackground() {
        let background = uiColor(from: Color.white)
        let price = uiColor(from: Color.purple600)
        
        let ratio = contrastRatio(between: price, and: background)
        
        XCTAssertGreaterThanOrEqual(
            ratio,
            normalTextMinimumRatio,
            "紫色价格文字在白色背景上的对比度应满足 WCAG AA 标准，实际: \(String(format: "%.2f", ratio)):1"
        )
    }
    
    // MARK: - Property-Based Test Simulation
    
    /// 属性测试：对于任意紫色背景和文本颜色组合，验证对比度
    func testAllPurpleBackgroundTextCombinations() {
        var passedCombinations = 0
        var totalCombinations = 0
        var failedCombinations: [(String, String, CGFloat)] = []
        
        for (bgName, bgColor) in purpleBackgrounds {
            for (textName, textColor) in textColors {
                totalCombinations += 1
                
                let bg = uiColor(from: bgColor)
                let text = uiColor(from: textColor)
                let ratio = contrastRatio(between: text, and: bg)
                
                if ratio >= normalTextMinimumRatio {
                    passedCombinations += 1
                } else {
                    failedCombinations.append((textName, bgName, ratio))
                }
            }
        }
        
        // 打印统计信息
        print("✅ 通过的组合: \(passedCombinations)/\(totalCombinations)")
        print("❌ 未通过的组合: \(failedCombinations.count)")
        
        if !failedCombinations.isEmpty {
            print("\n未通过对比度标准的组合:")
            for (text, bg, ratio) in failedCombinations {
                print("  - \(text) on \(bg): \(String(format: "%.2f", ratio)):1")
            }
        }
        
        // 至少70%的组合应该通过（这是一个合理的阈值）
        let passRate = Double(passedCombinations) / Double(totalCombinations)
        XCTAssertGreaterThanOrEqual(
            passRate,
            0.7,
            "至少70%的紫色背景和文本组合应满足对比度标准，实际: \(String(format: "%.1f", passRate * 100))%"
        )
    }
    
    /// 测试推荐的紫色背景和文本组合
    func testRecommendedPurpleTextCombinations() {
        // 推荐的组合（基于设计系统）
        let recommendedCombinations: [(String, Color, String, Color)] = [
            ("white", Color.white, "purple600", Color.purple600),
            ("white", Color.white, "purple700", Color.purple700),
            ("white", Color.white, "purple800", Color.purple800),
            ("white", Color.white, "purple900", Color.purple900),
            ("gray900", Color.gray900, "purple50", Color.purple50),
            ("gray900", Color.gray900, "purple100", Color.purple100),
            ("gray900", Color.gray900, "purple200", Color.purple200),
            ("purple600", Color.purple600, "purple100", Color.purple100),
            ("purple700", Color.purple700, "purple50", Color.purple50)
        ]
        
        for (textName, textColor, bgName, bgColor) in recommendedCombinations {
            let text = uiColor(from: textColor)
            let bg = uiColor(from: bgColor)
            let ratio = contrastRatio(between: text, and: bg)
            
            XCTAssertGreaterThanOrEqual(
                ratio,
                normalTextMinimumRatio,
                "推荐组合 \(textName) on \(bgName) 的对比度应满足 WCAG AA 标准，实际: \(String(format: "%.2f", ratio)):1"
            )
        }
    }
    
    /// 测试大文本在紫色背景上的可读性（3:1标准）
    func testLargeTextOnPurpleBackgrounds() {
        // 大文本（18pt+或14pt粗体+）可以使用较低的对比度标准
        let background = uiColor(from: Color.purple500)
        let text = uiColor(from: Color.white)
        
        let ratio = contrastRatio(between: text, and: background)
        
        XCTAssertGreaterThanOrEqual(
            ratio,
            largeTextMinimumRatio,
            "大文本在 purple500 背景上的对比度应满足 WCAG AA 标准（3:1），实际: \(String(format: "%.2f", ratio)):1"
        )
    }
}
