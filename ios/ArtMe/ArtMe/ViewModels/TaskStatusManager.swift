//
//  TaskStatusManager.swift
//  ArtMe
//
//  全局任务状态与 Toast 管理器
//

import Foundation
import SwiftUI
import Combine

/// 全局任务状态与顶部 Toast 管理
@MainActor
final class TaskStatusManager: ObservableObject {
    // 任务状态提示（逻辑状态）
    @Published var pendingItem: GeneratedImageHistory?
    @Published var completedItem: GeneratedImageHistory?
    
    // 顶部 Toast 展示状态（UI）
    @Published var pendingToastItem: GeneratedImageHistory?
    @Published var completedToastQueue: [GeneratedImageHistory] = []
    @Published var currentCompletedToast: GeneratedImageHistory?
    @Published var isProcessingCompletedQueue = false
    @Published var shownPendingTaskIds: [String] = []
    @Published var shownCompletedTaskIds: [String] = []
    
    private var isPolling = false
    
    init() {
        // 启动时读取一次本地历史：
        // 将当前已有任务视为「旧任务」，它们的完成状态不再弹出 Toast，
        // 只对之后新增的任务弹出「制作完成」Toast。
        let historyManager = HistoryManager()
        shownCompletedTaskIds = historyManager.history.map { $0.id }
        print("[TaskStatus] init, history count = \(historyManager.history.count), shownCompletedTaskIds = \(shownCompletedTaskIds)")
        // 不自动开始轮询，由根视图显式调用 startPollingIfNeeded()
    }
    
    // MARK: - 对外 API
    
    func startPollingIfNeeded() {
        guard !isPolling else {
            print("[TaskStatus] startPollingIfNeeded ignored, already polling")
            return
        }
        print("[TaskStatus] startPollingIfNeeded -> begin polling")
        Task {
            await pollPendingTasksIfNeeded()
        }
    }
    
    // MARK: - 任务状态轮询
    
    private func pollPendingTasksIfNeeded() async {
        if isPolling {
            print("[TaskStatus] pollPendingTasksIfNeeded called but isPolling = true, return")
            return
        }
        isPolling = true
        defer { isPolling = false }
        
        print("[TaskStatus] pollPendingTasksIfNeeded start loop")
        // 持续轮询，直到本地不再有「制作中」任务或任务被取消
        while true {
            let hasPending = await checkPendingTasksOnce()
            if !hasPending {
                print("[TaskStatus] no more pending/processing tasks, stop polling")
                break
            }
            
            // 任务仍在制作中，3 秒后继续查询
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if Task.isCancelled { break }
        }
    }
    
    /// 查询一次所有「制作中」任务的状态
    /// - Returns: 是否仍然需要继续轮询（true 表示仍存在制作中任务）
    private func checkPendingTasksOnce() async -> Bool {
        // 读取本地历史：最新的任务排在最前
        let historyManager = HistoryManager()
        
        let historySnapshot = historyManager.history
        print("[TaskStatus] checkPendingTasksOnce, history count = \(historySnapshot.count)")
        
        // 没有任何历史记录：不需要轮询
        if historySnapshot.isEmpty {
            await MainActor.run {
                pendingItem = nil
            }
            print("[TaskStatus] history empty, stop polling")
            return false
        }
        
        var hasPendingOrProcessing = false
        
        // 逐个遍历所有 pending / processing 任务
        for item in historySnapshot {
            let localStatus = item.status ?? "pending"
            guard localStatus == "pending" || localStatus == "processing" else {
                continue
            }
            
            hasPendingOrProcessing = true
            print("[TaskStatus] polling task id=\(item.id), localStatus=\(localStatus), notifyOnComplete=\(item.notifyOnComplete == true)")
            
            do {
                let statusResponse = try await APIService.shared.fetchTaskStatus(taskId: item.id)
                print("[TaskStatus] status response id=\(item.id), status=\(statusResponse.status), imageUrls=\(statusResponse.imageUrls)")
                
                switch statusResponse.status {
                case "completed":
                    // 更新本地历史为完成状态
                    historyManager.updateHistoryStatus(
                        id: item.id,
                        status: "completed",
                        imageUrl: statusResponse.imageUrls.first,
                        error: nil
                    )
                    
                    // 重新读取更新后的这条记录
                    let updated = historyManager.history.first(where: { $0.id == item.id }) ?? item
                    print("[TaskStatus] task completed id=\(updated.id), notifyOnComplete=\(updated.notifyOnComplete == true)")
                    
                    await MainActor.run {
                        completedItem = updated
                        // 只有用户勾选了「制作完成后通知我」的任务才进入完成队列；
                        // 启动前已有的任务会在 init 中被视为已展示过完成 Toast。
                        if updated.notifyOnComplete == true {
                            enqueueCompletedToastIfNeeded(for: updated)
                        }
                    }
                    
                case "failed":
                    print("[TaskStatus] task failed id=\(item.id)")
                    historyManager.updateHistoryStatus(
                        id: item.id,
                        status: "failed",
                        imageUrl: nil,
                        error: statusResponse.error
                    )
                    
                case "pending", "processing":
                    // 仍在制作中：更新本地状态并继续轮询，并触发一次「正在制作」Toast
                    historyManager.updateHistoryStatus(
                        id: item.id,
                        status: statusResponse.status,
                        imageUrl: statusResponse.imageUrls.first ?? item.imageUrl,
                        error: statusResponse.error
                    )
                    let updated = historyManager.history.first(where: { $0.id == item.id }) ?? item
                    print("[TaskStatus] task still pending/processing id=\(updated.id)")
                    await MainActor.run {
                        showPendingToastIfNeeded(for: updated)
                    }
                    
                default:
                    // 未知状态：保守处理为已完成
                    print("[TaskStatus] task unknown status treated as completed, id=\(item.id), status=\(statusResponse.status)")
                    historyManager.updateHistoryStatus(
                        id: item.id,
                        status: "completed",
                        imageUrl: statusResponse.imageUrls.first ?? item.imageUrl,
                        error: statusResponse.error
                    )
                    let updated = historyManager.history.first(where: { $0.id == item.id }) ?? item
                    await MainActor.run {
                        completedItem = updated
                        if updated.notifyOnComplete == true {
                            enqueueCompletedToastIfNeeded(for: updated)
                        }
                    }
                }
                
            } catch {
                // 查询失败时，保守认为任务仍在制作中，稍后重试，并确保至少展示一次「正在制作」提示
                print("[TaskStatus] fetch status failed for id=\(item.id), error=\(error)")
                await MainActor.run {
                    showPendingToastIfNeeded(for: item)
                }
            }
        }
        
        // 根据最新本地历史情况，找到仍然处于制作中的最新一条任务
        let latestPending = historyManager.history.first { historyItem in
            guard let status = historyItem.status else { return false }
            return status == "pending" || status == "processing"
        }
        
        await MainActor.run {
            pendingItem = latestPending
        }
        
        print("[TaskStatus] checkPendingTasksOnce finished, hasPendingOrProcessing=\(hasPendingOrProcessing), latestPendingId=\(latestPending?.id ?? "nil")")
        return latestPending != nil && hasPendingOrProcessing
    }
    
    // MARK: - Toast 辅助方法
    
    /// 只在每个任务第一次进入「制作中」状态时，展示一次约 5 秒的「正在制作」Toast
    /// 且仅针对用户勾选了「制作完成后通知我」的任务
    private func showPendingToastIfNeeded(for item: GeneratedImageHistory) {
        // 只有用户勾选了通知的任务才展示「正在制作」提示
        guard item.notifyOnComplete == true else {
            print("[TaskStatus] skip pending toast, notifyOnComplete != true, id=\(item.id)")
            return
        }
        guard !shownPendingTaskIds.contains(item.id) else {
            print("[TaskStatus] skip pending toast, already shown for id=\(item.id)")
            return
        }
        print("[TaskStatus] show pending toast for id=\(item.id)")
        shownPendingTaskIds.append(item.id)
        pendingToastItem = item
        
        Task {
            // 展示约 5 秒
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            await MainActor.run {
                if pendingToastItem?.id == item.id {
                    print("[TaskStatus] auto hide pending toast for id=\(item.id)")
                    pendingToastItem = nil
                }
            }
        }
    }
    
    /// 每个任务完成时加入队列，只展示一次；多个任务顺序依次弹出，每条约 2 秒
    private func enqueueCompletedToastIfNeeded(for item: GeneratedImageHistory) {
        // 只有用户勾选了「制作完成后通知我」的任务才加入队列
        guard item.notifyOnComplete == true else {
            print("[TaskStatus] skip completed toast, notifyOnComplete != true, id=\(item.id)")
            return
        }
        guard !shownCompletedTaskIds.contains(item.id) else {
            print("[TaskStatus] skip completed toast, already shown for id=\(item.id)")
            return
        }

        // 如果当前正在展示的 pending Toast 就是这个任务，
        // 让出位置给「制作完成」Toast，避免两者长时间叠加。
        if pendingToastItem?.id == item.id {
            print("[TaskStatus] clear pending toast before completed for id=\(item.id)")
            pendingToastItem = nil
        }

        shownCompletedTaskIds.append(item.id)
        completedToastQueue.append(item)
        print("[TaskStatus] enqueue completed toast id=\(item.id), queueSize=\(completedToastQueue.count)")
        
        Task {
            await processCompletedToastQueueIfNeeded()
        }
    }
    
    /// 依次展示队列中的「制作完成」Toast，每条约 5 秒
    private func processCompletedToastQueueIfNeeded() async {
        guard !isProcessingCompletedQueue else {
            print("[TaskStatus] processCompletedToastQueueIfNeeded already running, skip")
            return
        }
        isProcessingCompletedQueue = true
        print("[TaskStatus] processCompletedToastQueueIfNeeded start, initialQueueSize=\(completedToastQueue.count)")
        
        while !completedToastQueue.isEmpty {
            let next = completedToastQueue.removeFirst()
            print("[TaskStatus] show completed toast id=\(next.id), remainingQueueSize=\(completedToastQueue.count)")

            withAnimation {
                currentCompletedToast = next
            }
            
            // 展示约 5 秒
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            
            withAnimation {
                if currentCompletedToast?.id == next.id {
                    print("[TaskStatus] hide completed toast id=\(next.id)")
                    currentCompletedToast = nil
                }
            }

            // 该任务的「制作完成」Toast 已经完整展示过一次后，就没有必要再在内存中保留它的 ID 了，
            // 下次应用重启时会重新从本地历史中加载一次「旧任务」ID 列表，以避免重复弹出旧任务的完成 Toast。
            shownCompletedTaskIds.removeAll { $0 == next.id }
            
            // 给一点点间隔，避免动画过于拥挤
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
        
        isProcessingCompletedQueue = false
        print("[TaskStatus] processCompletedToastQueueIfNeeded finished")
    }
}


