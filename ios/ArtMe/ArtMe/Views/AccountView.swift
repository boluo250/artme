//
//  AccountView.swift
//  ArtMe
//
//  账户视图
//

import SwiftUI

struct AccountView: View {
    @StateObject private var viewModel = AccountViewModel()
    @State private var showPaymentView = false
    @State private var showLoginView = false
    
    var body: some View {
        NavigationView {
            List {
                // 顶部三个核心行：登录 / 会员入口 / 我的积分
                Section {
                    // 第 1 行：手机号登录
                    HStack {
                        Text("账号")
                            .textStyleBody()
                        Spacer()
                        if viewModel.isLoggedIn {
                            Text(viewModel.maskedPhoneNumber)
                                .foregroundColor(.purple600)
                                .font(.themeHeadline)
                        } else {
                            Button("登录") {
                                showLoginView = true
                            }
                            .foregroundColor(.purple600)
                            .font(.themeHeadline)
                        }
                    }
                    
                    // 第 2 行：立即开通会员（预留）
                    HStack {
                        Text("会员")
                            .textStyleBody()
                        Spacer()
                        Text("立即开通会员（即将上线）")
                            .textStyleCaption()
                            .foregroundColor(.gray)
                    }
                    
                    // 第 3 行：我的积分
                    HStack {
                        Text("我的积分")
                            .textStyleBody()
                        Spacer()
                        if viewModel.isLoggedIn {
                            Text(viewModel.pointsText)
                                .foregroundColor(.purple600)
                                .font(.themeHeadline)
                        } else {
                            Text("--  登录后可查看")
                                .textStyleCaption()
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section("账户信息") {
                    HStack {
                        Text("余额（积分）")
                            .textStyleBody()
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                                .purpleProgressIndicator()
                        } else {
                            Text("\(String(format: "%.0f", viewModel.balance))")
                                .foregroundColor(.purple600)
                                .font(.themeHeadline)
                        }
                    }
                }
                
                Section("操作") {
                    Button(action: {
                        showPaymentView = true
                    }) {
                        Label("充值与订阅", systemImage: "creditcard")
                            .foregroundColor(.purple600)
                    }
                }
                
                Section("我的作品") {
                    NavigationLink {
                        PortfolioView()
                    } label: {
                        Label("我的作品集", systemImage: "photo.stack")
                            .foregroundColor(.purple600)
                    }
                }
                
                if let subscription = viewModel.subscription {
                    Section("当前订阅") {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text(subscription.subscriptionType)
                                .textStyleHeadline()
                            Text("到期时间: \(subscription.expiresAt, style: .date)")
                                .textStyleCaption()
                        }
                    }
                }
                
                Section("交易记录") {
                    if viewModel.transactions.isEmpty {
                        Text("暂无交易记录")
                            .textColorSecondary()
                    } else {
                        ForEach(viewModel.transactions.prefix(5)) { transaction in
                            TransactionRow(transaction: transaction)
                        }
                    }
                }
            }
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadAccountInfo()
            }
            .sheet(isPresented: $showPaymentView) {
                PaymentView()
            }
            .sheet(isPresented: $showLoginView, onDismiss: {
                Task {
                    await viewModel.loadAccountInfo()
                }
            }) {
                PhoneLoginView {
                    Task {
                        await viewModel.loadAccountInfo()
                    }
                }
            }
        }
    }
}

#Preview {
    AccountView()
}

