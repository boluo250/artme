import Foundation
import SwiftUI
import Combine

@MainActor
final class PointsViewModel: ObservableObject {
    @Published var balance: Double = 0
    @Published var transactions: [TransactionResponse] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    private var userId: String? {
        UserDefaults.standard.string(forKey: "userId")
    }

    func load() async {
        let userId: String
        do {
            userId = try await SessionManager.ensureGuestUser()
        } catch {
            errorMessage = "创建游客账号失败: \(error.localizedDescription)"
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let balanceResponse: [String: Double] = try await apiService.request(
                endpoint: Constants.API.account + "/balance?user_id=\(userId)",
                method: "GET"
            )
            balance = balanceResponse["balance"] ?? 0.0

            transactions = try await apiService.request(
                endpoint: Constants.API.account + "/transactions?user_id=\(userId)&limit=100&offset=0",
                method: "GET"
            )
        } catch {
            errorMessage = "加载积分明细失败: \(error.localizedDescription)"
        }
    }

    var pointsText: String {
        "\(Int(balance.rounded()))"
    }

    /// 扣分记录（只看 consume，amount 为负数）
    var consumeTransactions: [TransactionResponse] {
        transactions
            .filter { $0.transactionType.lowercased() == "consume" }
            .sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Breakdown (临时 / 永久)
    // 目前后端旧账本只有一个余额，这里临时按全部归为“永久积分”。
    // 等接入新的 gift/paid 账本后：
    // - temporaryPoints <- gift_balance
    // - permanentPoints <- paid_balance
    // - temporaryExpireAt <- 当前订阅周期结束时间（若有）
    var temporaryPoints: Int { 0 }
    var permanentPoints: Int { Int(balance.rounded()) }
    var temporaryExpireAt: Date? { nil }
}

