//
//  AccountViewModel.swift
//  ArtMe
//
//  账户视图模型
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AccountViewModel: ObservableObject {
    @Published var balance: Double = 0.0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var transactions: [TransactionResponse] = []
    @Published var subscription: SubscriptionResponse?
    
    private let apiService = APIService.shared
    private let paymentService = PaymentService.shared
    
    var userId: String? {
        // TODO: 从用户认证系统获取
        UserDefaults.standard.string(forKey: "userId")
    }
    
    func loadAccountInfo() async {
        guard let userId = userId else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 加载余额
            let balanceResponse: [String: Double] = try await apiService.request(
                endpoint: Constants.API.account + "/balance?user_id=\(userId)",
                method: "GET"
            )
            balance = balanceResponse["balance"] ?? 0.0
            
            // 加载交易记录
            transactions = try await apiService.request(
                endpoint: Constants.API.account + "/transactions?user_id=\(userId)",
                method: "GET"
            )
            
            // 加载订阅信息
            do {
                subscription = try await apiService.request(
                    endpoint: Constants.API.account + "/subscription?user_id=\(userId)",
                    method: "GET"
                )
            } catch {
                // 没有订阅是正常的
                subscription = nil
            }
            
        } catch {
            errorMessage = "加载账户信息失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func recharge(amount: Double, paymentMethod: String) async {
        guard let userId = userId else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let request = RechargeRequest(amount: amount, paymentMethod: paymentMethod)
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let body = try encoder.encode(request)
            
            let response: RechargeResponse = try await apiService.request(
                endpoint: Constants.API.account + "/recharge?user_id=\(userId)",
                method: "POST",
                body: body
            )
            
            // 处理支付
            // TODO: 根据 paymentMethod 调用相应的支付服务
            
        } catch {
            errorMessage = "充值失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

// MARK: - 数据模型

struct TransactionResponse: Codable, Identifiable {
    let id: String
    let transactionType: String
    let amount: Double
    let description: String?
    let status: String
    let createdAt: Date
}

struct SubscriptionResponse: Codable {
    let id: String
    let subscriptionType: String
    let price: Double
    let startedAt: Date
    let expiresAt: Date
    let autoRenew: Bool
    let isActive: Bool
}

struct RechargeRequest: Codable {
    let amount: Double
    let paymentMethod: String
}

struct RechargeResponse: Codable {
    let message: String
    let paymentId: String
    let amount: Double
}

