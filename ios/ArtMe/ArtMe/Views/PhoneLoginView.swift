//
//  PhoneLoginView.swift
//  ArtMe
//
//  原手机号登录视图（用于「我的」页面）
//  需求：屏蔽手机号登录。保留此视图作为“账号入口”，提供游客继续使用能力。
//

import SwiftUI

struct PhoneLoginView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var errorMessage: String?
    @State private var isCreatingGuest = false
    
    var onLoginSuccess: (() -> Void)?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("手机号登录已下线")
                        .font(.headline)
                    Text("你仍可以使用游客模式继续体验（会在本机保存一个 userId，用于扣积分/查询余额）。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                Button {
                    Task { await createGuest() }
                } label: {
                    if isCreatingGuest {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("创建中…")
                        }
                    } else {
                        Text("继续使用（游客模式）")
                            .bold()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isCreatingGuest)
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("账号")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func createGuest() async {
        isCreatingGuest = true
        errorMessage = nil
        
        do {
            _ = try await SessionManager.ensureGuestUser()
            onLoginSuccess?()
            dismiss()
        } catch {
            if let apiError = error as? APIError {
                errorMessage = apiError.errorDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isCreatingGuest = false
    }
}

#Preview {
    PhoneLoginView()
}


