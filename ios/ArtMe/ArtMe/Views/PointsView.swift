import SwiftUI

struct PointsView: View {
    @StateObject private var viewModel = PointsViewModel()
    @State private var showPurchaseSheet = false

    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill").foregroundColor(.pink500)
                        Text("可用积分").font(.subheadline).foregroundColor(.secondary)
                        Spacer()
                    }

                    Text(viewModel.pointsText)
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.purple600)

                    Button(action: { showPurchaseSheet = true }) {
                        Text("购买更多积分")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(LinearGradient(colors: [.pink500, .violet500], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(12)
                    }

                    PointsBreakdownRow(
                        permanent: viewModel.permanentPoints,
                        temporary: viewModel.temporaryPoints,
                        temporaryExpireAt: viewModel.temporaryExpireAt
                    )

                    if let err = viewModel.errorMessage {
                        Text(err).font(.footnote).foregroundColor(.red)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("积分明细") {
                if viewModel.transactions.isEmpty {
                    Text("暂无记录")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.transactions.sorted(by: { $0.createdAt > $1.createdAt })) { tx in
                        PointsTransactionRow(tx: tx)
                    }
                }
            }

            #if DEBUG
            Section("QA") {
                Button("领5测试积分") {
                    Task {
                        do {
                            let userId = try await SessionManager.ensureGuestUser()
                            _ = try await APIService.shared.grantPointsQA(userId: userId, amount: 5)
                            await viewModel.load()
                        } catch {
                            viewModel.errorMessage = "发放失败: \(error.localizedDescription)"
                        }
                    }
                }
            }
            #endif
        }
        .listStyle(.insetGrouped)
        .navigationTitle("积分明细")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .sheet(isPresented: $showPurchaseSheet) { PaymentView() }
    }
}

// MARK: - Breakdown Row (永久 / 临时)

private struct PointsBreakdownRow: View {
    let permanent: Int
    let temporary: Int
    let temporaryExpireAt: Date?

    private var temporaryExpireText: String {
        guard let d = temporaryExpireAt else { return "(永久)" }
        let df = DateFormatter(); df.dateFormat = "yyyy.MM.dd"
        return "(\(df.string(from: d)) 失效)"
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("永久积分").font(.caption).foregroundColor(.secondary)
                Text("\(permanent)").font(.headline)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Text("临时积分")
                    Text(temporaryExpireText)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                Text("\(temporary)").font(.headline)
            }
        }
        .padding(12)
        .background(Color.gray100)
        .cornerRadius(12)
    }
}

// MARK: - Transaction Row

private struct PointsTransactionRow: View {
    let tx: TransactionResponse

    private var title: String {
        if tx.transactionType.lowercased() == "consume" { return "AI绘画" }
        if tx.transactionType.lowercased() == "admin_grant" {
            let amount = Int(tx.amount.rounded())
            return "赠送\(max(amount, 0))积分"
        }
        return tx.description ?? tx.transactionType
    }

    private var amountText: String {
        let v = Int(tx.amount.rounded()); return v > 0 ? "+\(v)" : "\(v)"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline).foregroundColor(.primary)
                Text(tx.createdAt, format: .dateTime.year().month().day().hour().minute())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(amountText)
                .font(.subheadline)
                .foregroundColor(Int(tx.amount.rounded()) > 0 ? .pink500 : .gray700)
        }
        .padding(.vertical, 4)
    }
}
