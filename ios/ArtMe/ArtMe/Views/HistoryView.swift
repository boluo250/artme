//
//  HistoryView.swift
//  ArtMe
//
//  历史记录视图
//

import SwiftUI

struct GeneratedImageHistory: Identifiable, Codable {
    let id: String
    let prompt: String
    let styleId: String?
    let styleName: String?
    let imageUrl: String
    let createdAt: Date
}

class HistoryManager: ObservableObject {
    @Published var history: [GeneratedImageHistory] = []
    
    private let userDefaults = UserDefaults.standard
    private let historyKey = "generatedImageHistory"
    
    init() {
        loadHistory()
    }
    
    func addHistory(_ item: GeneratedImageHistory) {
        history.insert(item, at: 0)
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

struct HistoryView: View {
    @StateObject private var historyManager = HistoryManager()
    @State private var images: [String: UIImage] = [:]
    
    var body: some View {
        NavigationView {
            Group {
                if historyManager.history.isEmpty {
                    VStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("暂无历史记录")
                            .foregroundColor(.gray)
                            .padding()
                    }
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
                    }
                }
            }
        }
    }
    
    private func loadImage(for item: GeneratedImageHistory) async {
        guard images[item.id] == nil else { return }
        
        let fullURL = Constants.apiBaseURL + item.imageUrl
        do {
            let image = try await ImageService.shared.downloadImage(from: fullURL)
            images[item.id] = image
        } catch {
            print("加载图片失败: \(error)")
        }
    }
}

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
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .overlay {
                        ProgressView()
                    }
            }
            
            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(item.prompt)
                    .font(.headline)
                    .lineLimit(2)
                
                if let styleName = item.styleName {
                    Text(styleName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(item.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView()
}

