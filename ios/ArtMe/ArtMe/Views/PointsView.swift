import SwiftUI

struct PointsView: View {
    @StateObject private var viewModel = PointsViewModel()

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("当前积分")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(viewModel.pointsText)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.purple600)
                    }
                    Spacer()
                }
                .padding(.vertical, 6)

                if let err = viewModel.errorMessage {
                    Text(err)
                        .font(.footnote)
                        .foregroundColor(.red)
                }
            }

            Section("积分明细") {
                if viewModel.transactions.isEmpty {
                    Text("暂无记录")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.transactions.sorted(by: { $0.createdAt > $1.createdAt })) { tx in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tx.description ?? tx.transactionType)
                                    .font(.subheadline)
                                HStack(spacing: 8) {
                                    // 交易时间：前端展示到“分钟”即可（不显示秒）
                                    Text(tx.createdAt, format: .dateTime.year().month().day().hour().minute())
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(tx.status)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            let amountInt = Int(tx.amount.rounded())
                            Text(amountInt > 0 ? "+\(amountInt)" : "\(amountInt)")
                                .font(.subheadline)
                                .foregroundColor(amountInt > 0 ? .green : .red)
                        }
                    }
                }
            }
        }
        .navigationTitle("积分明细")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }
}


