import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var initializationManager = InitializationManager()
    
    var body: some View {
        Group {
            if initializationManager.isInitialized {
                ChatView(initializationError: initializationManager.errorMessage)
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
            
            Text("Apple Intelligenceの状態を確認しています")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    ContentView()
}
