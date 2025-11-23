//
//  ButtonStyles.swift
//  ArtMe
//
//  紫色主题按钮样式
//

import SwiftUI

// MARK: - Primary Button Style

/// 主要按钮样式 - 紫色背景，白色文字
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.themeHeadline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .padding(.horizontal, Spacing.xl)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .cornerRadius(CornerRadius.md)
            .shadowPurple()
            .opacity(isEnabled ? 1.0 : 0.6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private func backgroundColor(isPressed: Bool) -> Color {
        if !isEnabled {
            return .gray300
        }
        return isPressed ? .purple700 : .purple600
    }
}

// MARK: - Secondary Button Style

/// 次要按钮样式 - 浅紫色背景，紫色文字
struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.themeHeadline)
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .padding(.horizontal, Spacing.xl)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .cornerRadius(CornerRadius.md)
            .opacity(isEnabled ? 1.0 : 0.6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private var foregroundColor: Color {
        if !isEnabled {
            return .gray400
        }
        return colorScheme == .dark ? .purple300 : .purple600
    }
    
    private func backgroundColor(isPressed: Bool) -> Color {
        if !isEnabled {
            return colorScheme == .dark ? .gray800 : .gray200
        }
        
        if colorScheme == .dark {
            return isPressed ? .purple800 : .purple900
        } else {
            return isPressed ? .purple200 : .purple100
        }
    }
}

// MARK: - Outline Button Style

/// 描边按钮样式 - 透明背景，紫色边框
struct OutlineButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.themeHeadline)
            .foregroundColor(foregroundColor(isPressed: configuration.isPressed))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .padding(.horizontal, Spacing.xl)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(borderColor, lineWidth: 2)
            )
            .opacity(isEnabled ? 1.0 : 0.6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private func foregroundColor(isPressed: Bool) -> Color {
        if !isEnabled {
            return .gray400
        }
        return isPressed ? .purple700 : .purple600
    }
    
    private func backgroundColor(isPressed: Bool) -> Color {
        if isPressed && isEnabled {
            return .purple50
        }
        return .clear
    }
    
    private var borderColor: Color {
        isEnabled ? .purple600 : .gray300
    }
}

// MARK: - Text Button Style

/// 文本按钮样式 - 透明背景，紫色文字
struct TextButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.themeBody.weight(.semibold))
            .foregroundColor(foregroundColor(isPressed: configuration.isPressed))
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.md)
            .background(Color.clear)
            .opacity(isEnabled ? 1.0 : 0.6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private func foregroundColor(isPressed: Bool) -> Color {
        if !isEnabled {
            return .gray400
        }
        return isPressed ? .purple700 : .purple600
    }
}

// MARK: - Loading Button Style

/// 带加载状态的按钮修饰器
struct LoadingButtonModifier: ViewModifier {
    let isLoading: Bool
    let loadingText: String?
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .opacity(isLoading ? 0 : 1)
            
            if isLoading {
                HStack(spacing: Spacing.sm) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                    
                    if let text = loadingText {
                        Text(text)
                            .font(.themeHeadline)
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

extension View {
    /// 添加加载状态
    func loading(_ isLoading: Bool, text: String? = nil) -> some View {
        self.modifier(LoadingButtonModifier(isLoading: isLoading, loadingText: text))
    }
}

// MARK: - Icon Button Style

/// 图标按钮样式 - 圆形或方形图标按钮
struct IconButtonStyle: ButtonStyle {
    let size: IconButtonSize
    let variant: IconButtonVariant
    @Environment(\.isEnabled) var isEnabled
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size.iconSize))
            .foregroundColor(foregroundColor(isPressed: configuration.isPressed))
            .frame(width: size.frameSize, height: size.frameSize)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .cornerRadius(variant == .circle ? size.frameSize / 2 : CornerRadius.sm)
            .opacity(isEnabled ? 1.0 : 0.6)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private func foregroundColor(isPressed: Bool) -> Color {
        if !isEnabled {
            return .gray400
        }
        
        switch variant {
        case .primary:
            return .white
        case .secondary, .circle:
            return isPressed ? .purple700 : .purple600
        }
    }
    
    private func backgroundColor(isPressed: Bool) -> Color {
        if !isEnabled {
            return .gray200
        }
        
        switch variant {
        case .primary:
            return isPressed ? .purple700 : .purple600
        case .secondary:
            return colorScheme == .dark ?
                (isPressed ? .purple800 : .purple900) :
                (isPressed ? .purple200 : .purple100)
        case .circle:
            return isPressed ? .purple50 : .clear
        }
    }
}

enum IconButtonSize {
    case small, medium, large
    
    var frameSize: CGFloat {
        switch self {
        case .small: return 32
        case .medium: return 40
        case .large: return 48
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .small: return 16
        case .medium: return 20
        case .large: return 24
        }
    }
}

enum IconButtonVariant {
    case primary, secondary, circle
}

// MARK: - Button Style Extensions

extension View {
    /// 应用主要按钮样式
    func primaryButtonStyle() -> some View {
        self.buttonStyle(PrimaryButtonStyle())
    }
    
    /// 应用次要按钮样式
    func secondaryButtonStyle() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
    
    /// 应用描边按钮样式
    func outlineButtonStyle() -> some View {
        self.buttonStyle(OutlineButtonStyle())
    }
    
    /// 应用文本按钮样式
    func textButtonStyle() -> some View {
        self.buttonStyle(TextButtonStyle())
    }
    
    /// 应用图标按钮样式
    func iconButtonStyle(size: IconButtonSize = .medium, variant: IconButtonVariant = .secondary) -> some View {
        self.buttonStyle(IconButtonStyle(size: size, variant: variant))
    }
}
