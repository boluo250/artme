//
//  PaymentView.swift
//  ArtMe
//
//  支付和充值界面
//

import SwiftUI
import StoreKit

struct PaymentView: View {
    @StateObject private var paymentService = PaymentService.shared
    @StateObject private var accountViewModel = AccountViewModel()
    @State private var selectedProduct: Product?
    @State private var showingPurchaseAlert = false
    @State private var purchaseMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                // 账户余额
                Section("账户余额") {
                    HStack {
                        Text("当前余额")
                            .textStyleBody()
                        Spacer()
                        Text("¥\(String(format: "%.2f", accountViewModel.balance))")
                            .font(.themeHeadline)
                            .foregroundColor(.purple600)
                    }
                }
                
                // 单次充值
                Section("单次充值") {
                    ForEach(paymentService.products.filter { product in
                        product.id == PaymentService.ProductID.singleGenerate.rawValue
                    }) { product in
                        ProductRow(product: product) {
                            purchaseProduct(product)
                        }
                    }
                }
                
                // 订阅套餐
                Section("订阅套餐") {
                    ForEach(paymentService.products.filter { product in
                        product.type == .autoRenewable
                    }) { product in
                        SubscriptionRow(product: product) {
                            purchaseProduct(product)
                        }
                    }
                }
                
                // 交易记录
                Section("交易记录") {
                    if accountViewModel.transactions.isEmpty {
                        Text("暂无交易记录")
                            .textColorSecondary()
                    } else {
                        ForEach(accountViewModel.transactions) { transaction in
                            TransactionRow(transaction: transaction)
                        }
                    }
                }
                
                // 订阅信息
                if let subscription = accountViewModel.subscription {
                    Section("当前订阅") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(subscription.subscriptionType)
                                .font(.headline)
                            Text("到期时间: \(subscription.expiresAt, style: .date)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button("取消订阅") {
                                cancelSubscription()
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("充值与订阅")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await accountViewModel.loadAccountInfo()
                await paymentService.requestProducts()
            }
            .alert("购买结果", isPresented: $showingPurchaseAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(purchaseMessage)
            }
        }
    }
    
    private func purchaseProduct(_ product: Product) {
        Task {
            do {
                let transaction = try await paymentService.purchase(product)
                if transaction != nil {
                    purchaseMessage = "购买成功！"
                    showingPurchaseAlert = true
                    await accountViewModel.loadAccountInfo()
                }
            } catch {
                purchaseMessage = "购买失败: \(error.localizedDescription)"
                showingPurchaseAlert = true
            }
        }
    }
    
    private func cancelSubscription() {
        Task {
            // TODO: 调用后端API取消订阅
            await accountViewModel.loadAccountInfo()
        }
    }
}

struct ProductRow: View {
    let product: Product
    let onPurchase: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(product.displayName)
                    .font(.headline)
                Text(product.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(product.displayPrice)
                .font(.themeHeadline)
                .foregroundColor(.purple600)
            
            Button("购买") {
                onPurchase()
            }
            .secondaryButtonStyle()
        }
    }
}

struct SubscriptionRow: View {
    let product: Product
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(product.displayName)
                    .textStyleHeadline()
                Spacer()
                Text(product.displayPrice)
                    .font(.themeHeadline)
                    .foregroundColor(.purple600)
            }
            
            if let subscription = product.subscription {
                Text("每\(subscription.subscriptionPeriod.unit.localizedDescription)自动续费")
                    .textStyleCaption()
            }
            
            Button("订阅") {
                onPurchase()
            }
            .primaryButtonStyle()
        }
        .padding(.vertical, 4)
    }
}

struct TransactionRow: View {
    let transaction: TransactionResponse
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description ?? transaction.transactionType)
                    .font(.subheadline)
                // 交易时间：前端展示到“分钟”即可（不显示秒）
                Text(transaction.createdAt, format: .dateTime.year().month().day().hour().minute())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(transaction.amount > 0 ? "+¥\(String(format: "%.2f", transaction.amount))" : "¥\(String(format: "%.2f", transaction.amount))")
                .font(.subheadline)
                .foregroundColor(transaction.amount > 0 ? .green : .red)
        }
    }
}

extension Product.SubscriptionPeriod.Unit {
    var localizedDescription: String {
        switch self {
        case .day: return "天"
        case .week: return "周"
        case .month: return "月"
        case .year: return "年"
        @unknown default: return ""
        }
    }
}

#Preview {
    PaymentView()
}

