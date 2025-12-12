//
//  ArtMeApp.swift
//  ArtMe
//
//  应用入口
//

import SwiftUI
import Photos
import PhotosUI
import Foundation

@main
struct ArtMeApp: App {
    @StateObject private var taskStatusManager = TaskStatusManager()
    
    init() {
        // 应用启动日志：使用 Info 级别，在 Debug / Release 都会输出
        Log.info("ArtMe App 启动")
        // 启动阶段打点：App 入口初始化完成
        StartupProfiler.mark("ArtMeApp.init 完成")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(taskStatusManager)
                .preferredColorScheme(.dark)
        }
    }
}

