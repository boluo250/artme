//
//  PaymentService.swift
//  ArtMe
//
//  支付服务（iOS 内购）
//

import Foundation
import StoreKit
import Combine

@MainActor
class PaymentService: ObservableObject {
    static let shared = PaymentService()
    
    @Published var products: [Product] = []
    @Published var purchasedProducts: Set<String> = []
    @Published var isLoading = false
    
    private var updateListenerTask: Task<Void, Error>?
    
    // 产品ID（需要在 App Store Connect 中配置）
    enum ProductID: String, CaseIterable {
        case singleGenerate = "com.artme.generate.single"
        case weeklySubscription = "com.artme.subscription.weekly"
        case monthlySubscription = "com.artme.subscription.monthly"
    }
    
    init() {
        // 监听交易更新
        updateListenerTask = listenForTransactions()
        
        Task {
            await requestProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - 请求产品
    
    func requestProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let productIDs = ProductID.allCases.map { $0.rawValue }
            let storeProducts = try await Product.products(for: productIDs)
            
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            Log.error("获取产品失败: \(error)")
        }
    }
    
    // MARK: - 购买产品
    
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updatePurchasedProducts()
            return transaction
        case .userCancelled, .pending:
            return nil
        @unknown default:
            return nil
        }
    }
    
    // MARK: - 订阅管理
    
    func checkSubscriptionStatus() async -> Bool {
        var hasActiveSubscription = false
        
        for product in products where product.type == .autoRenewable {
            guard let subscription = product.subscription else { continue }
            
            let statuses = try? await subscription.status
            for status in statuses ?? [] {
                switch status.state {
                case .subscribed, .inGracePeriod:
                    hasActiveSubscription = true
                default:
                    break
                }
            }
        }
        
        return hasActiveSubscription
    }
    
    func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchasedProducts()
    }
    
    // MARK: - 私有方法
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await transaction.finish()
                    await self.updatePurchasedProducts()
                } catch {
                    Log.error("交易验证失败: \(error)")
                }
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PaymentError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    private func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                purchased.insert(transaction.productID)
            } catch {
                Log.error("更新购买产品失败: \(error)")
            }
        }
        
        purchasedProducts = purchased
    }
}

enum PaymentError: Error {
    case failedVerification
    case purchaseFailed
}

