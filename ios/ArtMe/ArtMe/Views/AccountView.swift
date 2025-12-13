import SwiftUI

struct AccountView: View {
    @StateObject private var viewModel = AccountViewModel()
    @State private var showPaymentView = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {

                    // MARK: - 账号、会员、积分
                    ProfileCard {
                        // 会员
                        ProfileRow(
                            icon: "crown.fill",
                            title: "立即开通会员",
                            subtitle: "即将上线",
                            onTap: {}
                        )

                        // 积分
                        if viewModel.isLoggedIn {
                            ProfileRow(
                                icon: "star.circle",
                                title: "我的积分",
                                iconColor: .purple600,
                                trailing: {
                                    Text(viewModel.pointsText)
                                        .foregroundColor(.purple600)
                                        .font(.themeHeadline)
                                },
                                destination: {
                                    PointsView()
                                }
                            )
                        } else {
                            ProfileRow(
                                icon: "star.circle",
                                title: "我的积分",
                                iconColor: .purple600,
                                trailing: {
                                    Text("查看")
                                        .foregroundColor(.secondary)
                                },
                                destination: { PointsView() }
                            )
                        }
                    }

                    // MARK: - 我的作品集
                    ProfileCard {
                        ProfileRow(
                            icon: "photo.on.rectangle",
                            title: "我的作品集"
                        ) {
                            PortfolioView()
                        }
                    }

                    // MARK: - 当前订阅
                    if let subscription = viewModel.subscription {
                        ProfileCard {
                            ProfileRow(
                                icon: "checkmark.seal",
                                title: subscription.subscriptionType,
                                subtitle: "到期时间：\(subscription.expiresAt.formatted(date: .abbreviated, time: .omitted))"
                            )
                        }
                    }

                    // MARK: - 交易记录
                    ProfileCard {
                        if viewModel.transactions.isEmpty {
                            ProfileRow(
                                icon: "doc.text",
                                title: "交易记录",
                                subtitle: "暂无交易记录"
                            )
                        } else {
                            ForEach(viewModel.transactions.prefix(5)) { transaction in
                                TransactionRow(transaction: transaction)
                                    .padding(.horizontal, 16)
                            }
                        }
                    }

                    // MARK: - 欢迎评分、分享好友
                    ProfileCard {
                        ProfileRow(icon: "heart", title: "欢迎评分", iconColor: .gray)
                        ProfileRow(icon: "paperplane", title: "分享给好友", iconColor: .gray)
                    }
                    
                    // MARK: - 联系客服
                    ProfileCard {
                        ProfileRow(icon: "message", title: "联系客服", iconColor: .gray)
                    }
                    
                    // MARK: - 设置
                    ProfileCard {
                        ProfileRow(icon: "gearshape", title: "设置", iconColor: .gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .background(Color(hex: "#F5F5F5"))
            .navigationTitle("个人中心")
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
