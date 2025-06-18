//
//  InitializationManager.swift
//  AI_Chat
//
//  Created by Claude on 2025/06/18.
//

import Foundation
import Combine

/// アプリの初期化を管理するマネージャー
@MainActor
class InitializationManager: ObservableObject {
    @Published var isInitialized = false
    
    /// アプリの初期化を実行
    func initialize() async {
        // 初期化処理（必要に応じて追加）
        await performInitialization()
        isInitialized = true
    }
    
    private func performInitialization() async {
        // Foundation Models Frameworkの初期化や
        // その他の初期設定をここに追加
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機
    }
} 