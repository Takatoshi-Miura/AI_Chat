//
//  ContentView.swift
//  AI_Chat
//
//  Created by Takatoshi Miura on 2025/06/18.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var initializationManager = InitializationManager()
    
    var body: some View {
        Group {
            if initializationManager.isInitialized {
                ChatView()
            } else {
                LoadingView()
            }
        }
        .task {
            await initializationManager.initialize()
        }
    }
}

/// 初期化中の読み込み画面
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("AIチャットを初期化中...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    ContentView()
}
