//
//  TextFieldStyles.swift
//  ArtMe
//
//  紫色主题输入框样式
//

import SwiftUI

// MARK: - Theme Text Field Style

/// 主题输入框样式
struct ThemeTextFieldStyle: TextFieldStyle {
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isFocused: Bool
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(Spacing.md)
            .background(backgroundColor)
            .cornerRadius(CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(borderColor, lineWidth: isFocused ? 2 : 0)
            )
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? .gray700 : .gray100
    }
    
    private var borderColor: Color {
        isFocused ? .purple600 : .clear
    }
}

// MARK: - Focused Text Field Modifier

/// 带焦点状态的输入框修饰器
struct FocusedTextFieldModifier: ViewModifier {
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding(Spacing.md)
            .background(backgroundColor)
            .cornerRadius(CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(borderColor, lineWidth: isFocused ? 2 : 0)
            )
            .focused($isFocused)
    }
    
    private var backgroundColor: Color {
        if isFocused {
            return colorScheme == .dark ? .gray800 : .white
        }
        return colorScheme == .dark ? .gray700 : .gray100
    }
    
    private var borderColor: Color {
        isFocused ? .purple600 : .clear
    }
}

// MARK: - Outlined Text Field Modifier

/// 描边输入框修饰器
struct OutlinedTextFieldModifier: ViewModifier {
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding(Spacing.md)
            .background(backgroundColor)
            .cornerRadius(CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(borderColor, lineWidth: 1)
            )
            .focused($isFocused)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? .gray800 : .white
    }
    
    private var borderColor: Color {
        if isFocused {
            return .purple600
        }
        return colorScheme == .dark ? .gray600 : .gray300
    }
}

// MARK: - Search Field Modifier

/// 搜索框修饰器
struct SearchFieldModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray500)
                .font(.system(size: 16))
            
            content
            
            Spacer(minLength: 0)
        }
        .padding(Spacing.md)
        .background(backgroundColor)
        .cornerRadius(CornerRadius.md)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? .gray700 : .gray100
    }
}

// MARK: - Text Editor Modifier

/// 文本编辑器修饰器
struct ThemeTextEditorModifier: ViewModifier {
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    let minHeight: CGFloat
    
    init(minHeight: CGFloat = 100) {
        self.minHeight = minHeight
    }
    
    func body(content: Content) -> some View {
        content
            .frame(minHeight: minHeight)
            .padding(Spacing.sm)
            .background(backgroundColor)
            .cornerRadius(CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(borderColor, lineWidth: isFocused ? 2 : 0)
            )
            .focused($isFocused)
    }
    
    private var backgroundColor: Color {
        if isFocused {
            return colorScheme == .dark ? .gray800 : .white
        }
        return colorScheme == .dark ? .gray700 : .gray100
    }
    
    private var borderColor: Color {
        isFocused ? .purple600 : .clear
    }
}

// MARK: - Text Field Extensions

extension View {
    /// 应用主题输入框样式
    func themeTextField() -> some View {
        self.modifier(FocusedTextFieldModifier())
    }
    
    /// 应用描边输入框样式
    func outlinedTextField() -> some View {
        self.modifier(OutlinedTextFieldModifier())
    }
    
    /// 应用搜索框样式
    func searchField() -> some View {
        self.modifier(SearchFieldModifier())
    }
    
    /// 应用文本编辑器样式
    func themeTextEditor(minHeight: CGFloat = 100) -> some View {
        self.modifier(ThemeTextEditorModifier(minHeight: minHeight))
    }
}

// MARK: - Input Field Container

/// 输入框容器（带标签）
struct InputFieldContainer<Content: View>: View {
    let label: String
    let isRequired: Bool
    let content: Content
    
    init(label: String, isRequired: Bool = false, @ViewBuilder content: () -> Content) {
        self.label = label
        self.isRequired = isRequired
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Text(label)
                    .textStyleHeadline()
                
                if isRequired {
                    Text("*")
                        .foregroundColor(.error)
                        .font(.themeHeadline)
                }
            }
            
            content
        }
    }
}

// MARK: - Input Field with Error

/// 带错误提示的输入框修饰器
struct InputFieldWithErrorModifier: ViewModifier {
    let errorMessage: String?
    
    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            content
            
            if let error = errorMessage {
                Text(error)
                    .font(.themeCaption)
                    .foregroundColor(.error)
            }
        }
    }
}

extension View {
    /// 添加错误提示
    func inputError(_ message: String?) -> some View {
        self.modifier(InputFieldWithErrorModifier(errorMessage: message))
    }
}

// MARK: - Clearable Text Field

/// 可清除的输入框
struct ClearableTextField: View {
    let placeholder: String
    @Binding var text: String
    let onClear: (() -> Void)?
    
    init(_ placeholder: String, text: Binding<String>, onClear: (() -> Void)? = nil) {
        self.placeholder = placeholder
        self._text = text
        self.onClear = onClear
    }
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            TextField(placeholder, text: $text)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                    onClear?()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray400)
                        .font(.system(size: 16))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .themeTextField()
    }
}

// MARK: - Secure Field Modifier

/// 密码输入框修饰器
struct SecureFieldModifier: ViewModifier {
    @State private var isSecure: Bool = true
    @Binding var text: String
    let placeholder: String
    
    func body(content: Content) -> some View {
        HStack(spacing: Spacing.sm) {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
            
            Button(action: {
                isSecure.toggle()
            }) {
                Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray400)
                    .font(.system(size: 16))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .themeTextField()
    }
}

/// 密码输入框
struct ThemeSecureField: View {
    let placeholder: String
    @Binding var text: String
    
    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }
    
    var body: some View {
        EmptyView()
            .modifier(SecureFieldModifier(text: $text, placeholder: placeholder))
    }
}
