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
    
    var body: some View {
        NavigationView {
            List {
                Section("账户信息") {
                    HStack {
                        Text("余额")
                            .textStyleBody()
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                                .purpleProgressIndicator()
                        } else {
                            Text("¥\(String(format: "%.2f", viewModel.balance))")
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
            .navigationTitle("账户")
            .navigationBarTitleDisplayMode(.large)
            .toolbar(.visible, for: .tabBar)
            .task {
                await viewModel.loadAccountInfo()
            }
            .sheet(isPresented: $showPaymentView) {
                PaymentView()
            }
        }
    }
}

#Preview {
    AccountView()
}

