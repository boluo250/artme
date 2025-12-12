import SwiftUI

// MARK: - 个人中心主页面
struct ProfileView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 第一组：账号、会员、积分
                    ProfileCardView {
                        ProfileRowView(
                            icon: "person.circle",
                            title: "176****2201",
                            showDivider: true,
                            action: { print("用户账号") }
                        )
                        
                        ProfileRowView(
                            icon: "diamond.fill",
                            title: "立即开通会员",
                            showDivider: true,
                            action: { print("开通会员") }
                        )
                        
                        ProfileRowView(
                            icon: "star.circle",
                            title: "我的积分",
                            rightText: "0 积分",
                            showDivider: false,
                            action: { print("我的积分") }
                        )
                    }
                    
                    // 第二组：作品集
                    ProfileCardView {
                        ProfileRowView(
                            icon: "photo.on.rectangle",
                            title: "我的作品集",
                            showDivider: false,
                            action: { print("我的作品集") }
                        )
                    }
                    
                    // 第三组：评分、分享
                    ProfileCardView {
                        ProfileRowView(
                            icon: "heart",
                            title: "欢迎评分",
                            showDivider: true,
                            action: { print("欢迎评分") }
                        )
                        
                        ProfileRowView(
                            icon: "paperplane",
                            title: "分享给好友",
                            showDivider: false,
                            action: { print("分享给好友") }
                        )
                    }
                    
                    // 第四组：客服、设置
                    ProfileCardView {
                        ProfileRowView(
                            icon: "message",
                            title: "联系客服",
                            showDivider: true,
                            action: { print("联系客服") }
                        )
                        
                        ProfileRowView(
                            icon: "gearshape",
                            title: "设置",
                            showDivider: false,
                            action: { print("设置") }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("个人中心")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Card 容器组件
struct ProfileCardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Row 行组件
struct ProfileRowView: View {
    let icon: String
    let title: String
    var rightText: String? = nil
    var showDivider: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    // 左侧图标
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                    
                    // 主标题
                    Text(title)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .padding(.leading, 12)
                    
                    Spacer()
                    
                    // 右侧副标题（可选）
                    if let rightText = rightText {
                        Text(rightText)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .padding(.trailing, 8)
                    }
                    
                    // 右箭头
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(.systemGray3))
                }
                .frame(height: 56)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
                
                // 分割线
                if showDivider {
                    Divider()
                        .padding(.leading, 52)
                }
            }
        }
        .buttonStyle(ProfileRowButtonStyle())
    }
}

// MARK: - 自定义按钮样式（点击效果）
struct ProfileRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed
                    ? Color(.systemGray5)
                    : Color.clear
            )
    }
}

// MARK: - Preview
#Preview("浅色模式") {
    ProfileView()
        .preferredColorScheme(.light)
}

#Preview("深色模式") {
    ProfileView()
        .preferredColorScheme(.dark)
}

