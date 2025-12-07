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
    @State private var selectedImage: UIImage?
    @State private var isShowingImagePreview: Bool = false
    
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
                            PortfolioGridItem(
                                item: item,
                                image: images[item.id],
                                onTap: {
                                    if let image = images[item.id] {
                                        withAnimation(.easeInOut) {
                                            selectedImage = image
                                            isShowingImagePreview = true
                                        }
                                    }
                                }
                            )
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
        .overlay {
            if isShowingImagePreview, let image = selectedImage {
                ZStack {
                    Color.black.opacity(0.8)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                isShowingImagePreview = false
                                selectedImage = nil
                            }
                        }
                    
                    VStack {
                        Spacer()
                        
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadiusMD()
                            .padding()
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeInOut) {
                                isShowingImagePreview = false
                                selectedImage = nil
                            }
                        }) {
                            Text("关闭")
                                .font(.system(size: 16, weight: .medium))
                                .padding(.horizontal, 24)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.9))
                                .foregroundColor(.black)
                                .cornerRadius(22)
                        }
                        .padding(.bottom, 32)
                    }
                }
                .transition(.opacity)
            }
        }
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
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onTap()
                        }
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
                Text(item.createdAt, style: .date)
                    .textStyleSubheadline()
                    .foregroundColor(.gray400)
            }
        }
        .padding(Spacing.sm)
        .background(Color.gray900.opacity(0.45))
        .cornerRadiusMD()
    }
}

#Preview {
    PortfolioView()
}

