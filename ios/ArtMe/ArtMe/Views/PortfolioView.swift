//
//  PortfolioView.swift
//  ArtMe
//
//  我的作品集视图
//

import SwiftUI

struct PortfolioView: View {
    @StateObject private var historyManager = HistoryManager()
    @State private var images: [String: UIImage] = [:]
    
    private let gridColumns = [
        GridItem(.flexible(), spacing: Spacing.md),
        GridItem(.flexible(), spacing: Spacing.md)
    ]
    
    var body: some View {
        Group {
            if historyManager.history.isEmpty {
                EmptyStateView(
                    icon: "photo.on.rectangle.angled",
                    title: "暂无作品",
                    message: "生成的图片会自动保存到作品集"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, Spacing.lg)
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: Spacing.md) {
                        ForEach(historyManager.history) { item in
                            PortfolioGridItem(item: item, image: images[item.id])
                                .task {
                                    await loadImage(for: item)
                                }
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                }
            }
        }
        .navigationTitle("我的作品集")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @MainActor
    private func loadImage(for item: GeneratedImageHistory) async {
        guard images[item.id] == nil else { return }
        guard let imageUrl = item.imageUrl else { return }
        
        let fullURL = imageUrl.hasPrefix("http") ? imageUrl : Constants.apiBaseURL + imageUrl
        do {
            let image = try await ImageService.shared.downloadImage(from: fullURL)
            images[item.id] = image
        } catch {
            print("Portfolio: 图片加载失败 \(error.localizedDescription)")
        }
    }
}

private struct PortfolioGridItem: View {
    let item: GeneratedImageHistory
    let image: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if item.status == "pending" || item.status == "processing" {
                    Rectangle()
                        .fill(Color.gray300.opacity(0.3))
                        .overlay {
                            VStack(spacing: 8) {
                                ProgressView()
                                    .purpleProgressIndicator()
                                Text("制作中...")
                                    .textStyleCaption()
                                    .foregroundColor(.gray400)
                            }
                        }
                } else {
                    Rectangle()
                        .fill(Color.gray300.opacity(0.3))
                        .overlay {
                            ProgressView()
                                .purpleProgressIndicator()
                        }
                }
            }
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .clipped()
            .cornerRadiusMD()
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(item.prompt)
                    .textStyleSubheadline()
                    .lineLimit(2)
                
                if let styleName = item.styleName {
                    Text(styleName)
                        .textStyleCaption()
                        .foregroundColor(.gray400)
                }
                
                if let status = item.status {
                    Text(statusLabel(status))
                        .textStyleCaption()
                        .foregroundColor(statusColor(status))
                }
                
                Text(item.createdAt, style: .date)
                    .textStyleCaption()
                    .foregroundColor(.gray400)
            }
        }
        .padding(Spacing.sm)
        .background(Color.gray900.opacity(0.45))
        .cornerRadiusMD()
    }

    private func statusLabel(_ status: String) -> String {
        switch status {
        case "pending", "processing":
            return "制作中"
        case "failed":
            return "制作失败"
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
    PortfolioView()
}

