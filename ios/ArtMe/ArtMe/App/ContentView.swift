//
//  ContentView.swift
//  ArtMe
//
//  主视图
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PromptStyleGridView()
                .tabItem {
                    Label("风格", systemImage: "photo.on.rectangle.angled")
                }
                .tag(0)
            
            GenerateView()
                .tabItem {
                    Label("生成", systemImage: "sparkles")
                }
                .tag(1)
            
            HistoryView()
                .tabItem {
                    Label("历史", systemImage: "clock")
                }
                .tag(2)
            
            AccountView()
                .tabItem {
                    Label("账户", systemImage: "person.circle")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
}

