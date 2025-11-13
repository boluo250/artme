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
            GenerateView()
                .tabItem {
                    Label("生成", systemImage: "sparkles")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Label("历史", systemImage: "clock")
                }
                .tag(1)
            
            AccountView()
                .tabItem {
                    Label("账户", systemImage: "person.circle")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
}

