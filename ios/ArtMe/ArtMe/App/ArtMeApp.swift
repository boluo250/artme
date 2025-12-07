//
//  ArtMeApp.swift
//  ArtMe
//
//  应用入口
//

import SwiftUI

@main
struct ArtMeApp: App {
    @StateObject private var taskStatusManager = TaskStatusManager()
    
    init() {
        print("ArtMe App 启动")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(taskStatusManager)
                .preferredColorScheme(.dark)
        }
    }
}

