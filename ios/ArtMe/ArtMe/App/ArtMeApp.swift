//
//  ArtMeApp.swift
//  ArtMe
//
//  应用入口
//

import SwiftUI
import Photos
import PhotosUI

@main
struct ArtMeApp: App {
    @StateObject private var taskStatusManager = TaskStatusManager()
    
    init() {
        // 应用启动日志：使用 Info 级别，在 Debug / Release 都会输出
        Log.info("ArtMe App 启动")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(taskStatusManager)
                .preferredColorScheme(.dark)
        }
    }
}

