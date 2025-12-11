//
//  HistoryView.swift
//  ArtMe
//
//  历史记录视图
//

import SwiftUI
import Combine

// MARK: - 历史记录模型

struct GeneratedImageHistory: Identifiable, Codable {
    let id: String
    let prompt: String
    let styleId: String?
    let styleName: String?
    let imageUrl: String?
    let status: String?        // pending / processing / completed / failed
    let createdAt: Date
    let error: String?
    /// 用户是否勾选了「制作完成后通知我」
    let notifyOnComplete: Bool?
}

// MARK: - 历史记录管理

class HistoryManager: ObservableObject {
    @Published var history: [GeneratedImageHistory] = []
    
    private let userDefaults = UserDefaults.standard
    private let historyKey = "generatedImageHistory"
    
    init() {
        loadHistory()
    }
    
    /// 新增或更新一条历史记录
    func upsertHistory(_ item: GeneratedImageHistory) {
        if let idx = history.firstIndex(where: { $0.id == item.id }) {
            history[idx] = item
        } else {
            history.insert(item, at: 0)
        }
        saveHistory()
    }
    
    /// 更新状态、图片和错误信息（用于轮询任务状态）
    func updateHistoryStatus(id: String, status: String, imageUrl: String?, error: String?) {
        guard let idx = history.firstIndex(where: { $0.id == id }) else { return }
        let item = history[idx]
        history[idx] = GeneratedImageHistory(
            id: item.id,
            prompt: item.prompt,
            styleId: item.styleId,
            styleName: item.styleName,
            imageUrl: imageUrl ?? item.imageUrl,
            status: status,
            createdAt: item.createdAt,
            error: error,
            notifyOnComplete: item.notifyOnComplete
        )
        saveHistory()
    }
    
    func deleteHistory(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        saveHistory()
    }
    
    func clearHistory() {
        history.removeAll()
        saveHistory()
    }
    
    /// 更新某条记录的通知开关（不改变其他字段）
    func updateNotifyOnComplete(id: String, notifyOnComplete: Bool) {
        guard let idx = history.firstIndex(where: { $0.id == id }) else { return }
        let item = history[idx]
        history[idx] = GeneratedImageHistory(
            id: item.id,
            prompt: item.prompt,
            styleId: item.styleId,
            styleName: item.styleName,
            imageUrl: item.imageUrl,
            status: item.status,
            createdAt: item.createdAt,
            error: item.error,
            notifyOnComplete: notifyOnComplete
        )
        saveHistory()
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            userDefaults.set(encoded, forKey: historyKey)
        }
    }
    
    private func loadHistory() {
        if let data = userDefaults.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([GeneratedImageHistory].self, from: data) {
            history = decoded
        }
    }
}

// MARK: - 历史记录列表视图

struct HistoryView: View {
    @StateObject private var historyManager = HistoryManager()
    @State private var images: [String: UIImage] = [:]
    
    var body: some View {
        NavigationView {
            Group {
                if historyManager.history.isEmpty {
                    EmptyStateView(
                        icon: "photo.on.rectangle.angled",
                        title: "暂无历史记录",
                        message: "生成的图片会显示在这里"
                    )
                } else {
                    List {
                        ForEach(historyManager.history) { item in
                            HistoryRow(item: item, image: images[item.id])
                                .task {
                                    await loadImage(for: item)
                                }
                        }
                        .onDelete(perform: historyManager.deleteHistory)
                    }
                }
            }
            .navigationTitle("历史记录")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !historyManager.history.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("清空") {
                            historyManager.clearHistory()
                        }
                        .foregroundColor(.purple600)
                    }
                }
            }
        }
    }
    
    private func loadImage(for item: GeneratedImageHistory) async {
        guard images[item.id] == nil else { return }
        guard let imageUrl = item.imageUrl else { return }
        
        let fullURL = imageUrl.hasPrefix("http") ? imageUrl : Constants.apiBaseURL + imageUrl
        do {
            let image = try await ImageService.shared.downloadImage(from: fullURL)
            images[item.id] = image
        } catch {
            Log.error("加载图片失败: \(error)")
        }
    }
}

// MARK: - 单行历史记录

struct HistoryRow: View {
    let item: GeneratedImageHistory
    let image: UIImage?
    
    var body: some View {
        HStack(spacing: 12) {
            // 缩略图
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipped()
                    .cornerRadiusSM()
            } else if item.status == "pending" || item.status == "processing" {
                Rectangle()
                    .fill(Color.gray300.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .cornerRadiusSM()
                    .overlay {
                        ProgressView()
                            .purpleProgressIndicator()
                    }
            } else {
                Rectangle()
                    .fill(Color.gray300.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .cornerRadiusSM()
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    }
            }
            
            // 文本信息
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(item.prompt)
                    .textStyleHeadline()
                    .lineLimit(2)
                
                if let styleName = item.styleName {
                    Text(styleName)
                        .textStyleCaption()
                }
                
                if let status = item.status {
                    Text(statusDisplay(status))
                        .textStyleCaption()
                        .foregroundColor(statusColor(status))
                }
                
                Text(item.createdAt, style: .relative)
                    .textStyleCaption()
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func statusDisplay(_ status: String) -> String {
        switch status {
        case "pending", "processing":
            return "制作中..."
        case "failed":
            return "失败"
        default:
            return "已完成"
        }
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "pending", "processing":
            return .orange
        case "failed":
            return .red
        default:
            return .green
        }
    }
}

#Preview {
    HistoryView()
}


