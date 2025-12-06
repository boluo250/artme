//
//  ContentView.swift
//  ArtMe
//
//  主视图
//

import SwiftUI

struct ContentView: View {
    private enum ActiveSheet: String, Identifiable {
        case account
        
        var id: String { rawValue }
    }
    
    @State private var activeSheet: ActiveSheet?
    
    init() {
        // 初始化主题
        ThemeManager.shared.initialize()
    }
    
    var body: some View {
        NavigationStack {
            PromptStyleGridView {
                activeSheet = .account
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

#Preview {
    ContentView()
}

