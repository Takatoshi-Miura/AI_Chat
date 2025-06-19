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
        
        // Apple Intelligence状態のチェック
        await checkAppleIntelligenceStatus()
        
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機
    }
    
    /// Apple Intelligenceの状態をチェック
    private func checkAppleIntelligenceStatus() async {
        if #available(iOS 18.1, macOS 15.1, *) {
            print("=== Apple Intelligence Status ===")
            print("iOS/macOS version: Compatible")
            
            // デバイス情報の確認
            let deviceModel = await getDeviceModel()
            print("Device Model: \(deviceModel)")
            
            // 実機かシミュレーターかを確認
            #if targetEnvironment(simulator)
            print("⚠️ Running on Simulator - Apple Intelligence not available")
            print("Please run on actual device for Apple Intelligence features")
            #else
            print("✅ Running on real device")
            
            // Foundation Models Frameworkの利用可能性テスト
            do {
                print("🧪 Testing LanguageModelSession...")
                let testSession = LanguageModelSession(instructions: "Test")
                print("✅ LanguageModelSession creation: Success")
                
                // 実際にセッションをテスト
                print("🧪 Testing session response...")
                let testResponse = try await testSession.respond(to: "Hello")
                print("✅ LanguageModelSession respond: Success")
                print("📝 Test response: \(testResponse.content)")
                print("✅ Apple Intelligence is fully functional")
            } catch {
                print("❌ LanguageModelSession test failed: \(error)")
                if let nsError = error as NSError? {
                    print("🔍 Error details:")
                    print("   Domain: \(nsError.domain)")
                    print("   Code: \(nsError.code)")
                    print("   Description: \(nsError.localizedDescription)")
                    if let failureReason = nsError.localizedFailureReason {
                        print("   Failure Reason: \(failureReason)")
                    }
                    
                    // 具体的なエラー原因の特定と解決策
                    if nsError.domain.contains("UnifiedAssetFramework") || nsError.code == 5000 {
                        print("💡 Apple Intelligence Models Not Available")
                        print("   解決策:")
                        print("   1. 設定 > Apple Intelligence & Siri を開く")
                        print("   2. Apple Intelligence がオンになっているか確認")
                        print("   3. モデルのダウンロードが完了しているか確認")
                        print("   4. デバイスが対応機種か確認 (iPhone 15 Pro以上)")
                        print("   5. デバイスを再起動してみる")
                    } else if nsError.domain.contains("ModelInference") {
                        print("💡 Model Inference Error")
                        print("   Apple Intelligence サービスが一時的に利用できません")
                    }
                }
                print("🔄 App will use fallback implementation for AI responses")
            }
            #endif
            
            print("====================================")
        } else {
            print("Apple Intelligence: Not available on this OS version")
            print("Requires iOS 18.1+ or macOS 15.1+")
        }
    }
    
    /// デバイスモデル情報を取得
    private func getDeviceModel() async -> String {
        #if targetEnvironment(simulator)
        return "Simulator"
        #else
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value))!)
        }
        return identifier
        #endif
    }
} 