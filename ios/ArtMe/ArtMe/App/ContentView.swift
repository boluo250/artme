//
//  ContentView.swift
//  ArtMe
//
//  主视图
//

import SwiftUI
import UIKit

// MARK: - 全局路由定义

enum Route: Hashable {
    case promptDetail(style: PromptStyle)
    case uploadPreview(style: PromptStyle, imageData: Data)
    case generation(style: PromptStyle, imageData: Data)
}

struct ContentView: View {
    private enum ActiveSheet: String, Identifiable {
        case account
        
        var id: String { rawValue }
    }
    
    @State private var activeSheet: ActiveSheet?
    @State private var path = NavigationPath()
    
    init() {
        // 启动阶段打点：ContentView 初始化开始
        StartupProfiler.mark("ContentView.init 开始")
        
        // 初始化主题
        let t0 = Date()
        ThemeManager.shared.initialize()
        let t1 = Date()
        let cost = String(format: "%.3f", t1.timeIntervalSince(t0))
        Log.info("⏱ [Startup] ThemeManager.initialize() 耗时 \(cost)s")
        
        // 启动阶段打点：ContentView 初始化结束
        StartupProfiler.mark("ContentView.init 结束")
    }
    
    var body: some View {
        GlobalToastContainer {
            NavigationStack(path: $path) {
                PromptStyleGridView {
                    activeSheet = .account
                } onSelectStyle: { style in
                    path.append(Route.promptDetail(style: style))
                }
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .promptDetail(let style):
                        PromptStyleDetailView(style: style) { selectedStyle, image in
                            let t0 = Date()
                            if let data = image.jpegData(compressionQuality: 0.9) {
                                let t1 = Date()
                                Log.debug(">>> [PickerTiming] jpegData 压缩耗时: \(t1.timeIntervalSince(t0))s")
                                path.append(Route.uploadPreview(style: selectedStyle, imageData: data))
                            }
                        }
                    case .uploadPreview(let style, let imageData):
                        if let image = UIImage(data: imageData) {
                            ImageUploadPreviewView(
                                style: style,
                                uploadedImage: image
                            ) {
                                // 确认生成，进入生成页
                                path.append(Route.generation(style: style, imageData: imageData))
                            }
                        } else {
                            // 图片数据异常时，直接回到首页
                            EmptyView()
                                .onAppear {
                                    path = NavigationPath()
                                }
                        }
                    case .generation(let style, let imageData):
                        if let image = UIImage(data: imageData) {
                            ImageGenerationView(
                                style: style,
                                uploadedImage: image
                            , onBackToPrevious: {
                                // 返回到「立即制作」风格详情页：从 generation -> uploadPreview -> promptDetail
                                if path.count >= 2 {
                                    path.removeLast(2)
                                } else if path.count >= 1 {
                                    path.removeLast()
                                }
                            }
                            ) {
                                // 直接清空导航栈，返回首页
                                path = NavigationPath()
                            }
                        } else {
                            EmptyView()
                                .onAppear {
                                    path = NavigationPath()
                                }
                        }
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .account:
                    AccountView()
                }
            }
            .withTheme()
        }
    }
}

#Preview {
    ContentView()
}

