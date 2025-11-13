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
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("¥\(String(format: "%.2f", viewModel.balance))")
                                .foregroundColor(.blue)
                                .font(.headline)
                        }
                    }
                }
                
                Section("操作") {
                    Button(action: {
                        showPaymentView = true
                    }) {
                        Label("充值与订阅", systemImage: "creditcard")
                    }
                }
                
                if let subscription = viewModel.subscription {
                    Section("当前订阅") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(subscription.subscriptionType)
                                .font(.headline)
                            Text("到期时间: \(subscription.expiresAt, style: .date)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("交易记录") {
                    if viewModel.transactions.isEmpty {
                        Text("暂无交易记录")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.transactions.prefix(5)) { transaction in
                            TransactionRow(transaction: transaction)
                        }
                    }
                }
            }
            .navigationTitle("账户")
            .navigationBarTitleDisplayMode(.large)
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

