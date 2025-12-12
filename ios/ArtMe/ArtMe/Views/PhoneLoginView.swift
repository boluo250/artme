//
//  PhoneLoginView.swift
//  ArtMe
//
//  手机号登录视图（用于「我的」页面）
//

import SwiftUI

struct PhoneLoginView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var phoneNumber: String = ""
    @State private var code: String = ""
    @State private var isSendingCode = false
    @State private var isVerifying = false
    @State private var errorMessage: String?
    @State private var debugCode: String?
    
    private let apiService = APIService.shared
    var onLoginSuccess: (() -> Void)?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("手机号")) {
                    TextField("请输入手机号", text: $phoneNumber)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("验证码")) {
                    HStack {
                        TextField("请输入验证码", text: $code)
                            .keyboardType(.numberPad)
                        
                        Button(action: {
                            Task {
                                await sendCode()
                            }
                        }) {
                            if isSendingCode {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("获取验证码")
                            }
                        }
                        .disabled(isSendingCode || phoneNumber.isEmpty)
                    }
                    
                    if let debug = debugCode {
                        Text("开发环境验证码：\(debug)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("手机号登录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        Task {
                            await verifyCode()
                        }
                    }) {
                        if isVerifying {
                            ProgressView()
                        } else {
                            Text("登录")
                                .bold()
                        }
                    }
                    .disabled(phoneNumber.isEmpty || code.isEmpty || isVerifying)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func sendCode() async {
        guard !phoneNumber.isEmpty else { return }
        isSendingCode = true
        errorMessage = nil
        
        do {
            let response: SendCodeResponse = try await apiService.sendLoginCode(phoneNumber: phoneNumber)
            debugCode = response.debugCode
        } catch {
            if let apiError = error as? APIError {
                errorMessage = apiError.errorDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isSendingCode = false
    }
    
    private func verifyCode() async {
        guard !phoneNumber.isEmpty, !code.isEmpty else { return }
        isVerifying = true
        errorMessage = nil
        
        do {
            let auth: AuthUserResponse = try await apiService.verifyLoginCode(phoneNumber: phoneNumber, code: code)
            
            // 持久化用户 ID 与手机号，供 AccountView 使用
            UserDefaults.standard.set(auth.userId, forKey: "userId")
            UserDefaults.standard.set(auth.phoneNumber, forKey: "phoneNumber")
            
            // 登录成功后回调并关闭
            onLoginSuccess?()
            dismiss()
        } catch {
            if let apiError = error as? APIError {
                errorMessage = apiError.errorDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isVerifying = false
    }
}

#Preview {
    PhoneLoginView()
}


