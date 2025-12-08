//
//  GlobalToastContainer.swift
//  ArtMe
//
//  全局顶部 Toast 容器：在任意页面显示任务状态提示
//

import SwiftUI

struct GlobalToastContainer<Content: View>: View {
    @EnvironmentObject private var taskStatusManager: TaskStatusManager
    
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            content
            
            // 顶部轻量 Toast：1）生成开始时「制作中...」提示（约 5 秒自动消失）
            if let item = taskStatusManager.pendingToastItem {
                let _ = print("[GlobalToast] show PENDING toast id=\(item.id), imageUrl=\(item.imageUrl ?? "nil")")
                ToastBanner(
                    title: "制作中...",
                    message: "已帮您存入「首页-我的-作品集」中",
                    onAction: {
                        Task { @MainActor in
                            taskStatusManager.pendingToastItem = nil
                            taskStatusManager.navigateToPortfolio = true
                        }
                    },
                    onDismiss: {
                        Task { @MainActor in
                            taskStatusManager.pendingToastItem = nil
                        }
                    },
                    thumbnailUrl: item.imageUrl
                )
                // 顶部 Toast 统一尺寸 + 居中显示（制作中）
                .frame(width: 280, height: 72)
                //.frame(alignment: .center)
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, 40)
                .padding(.horizontal, Spacing.lg)
            }
            // 2）制作完成时「AI创作100%」提示：多个任务顺序依次展示，每条约 2 秒
            else if let item = taskStatusManager.currentCompletedToast {
                let _ = print("[GlobalToast] show COMPLETED toast id=\(item.id), imageUrl=\(item.imageUrl ?? "nil")")
                ToastBanner(
                    title: "AI创作100%",
                    message: "制作完成，点击查看>>",
                    onAction: {
                        Task { @MainActor in
                            taskStatusManager.currentCompletedToast = nil
                            taskStatusManager.navigateToPortfolio = true
                        }
                    },
                    onDismiss: {
                        Task { @MainActor in
                            taskStatusManager.currentCompletedToast = nil
                        }
                    },
                    thumbnailUrl: item.imageUrl
                )
                // 顶部 Toast 统一尺寸 + 居中显示（制作完成）
                .frame(width: 280, height: 72)
                //.frame(alignment: .center)
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, 40)
                .padding(.horizontal, Spacing.lg)
            }
        }
    }
}


