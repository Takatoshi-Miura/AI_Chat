import Foundation
import Combine
import SwiftUI
import FoundationModels

@MainActor
class AIService {
    var session: LanguageModelSession
    var errorMessage: String?
    
    // 複数のMCPクライアントを管理
    private var mcpClients: [String: MCPClientService] = [:]
    private var dynamicToolServices: [String: DynamicMCPToolService] = [:]
    private var allDynamicTools: [any FoundationModels.Tool] = []
    private var serverTools: [String: [any FoundationModels.Tool]] = [:]
    
    let systemPrompt = """
    あなたは親切で知識豊富なAIアシスタントです。日本語で丁寧に回答してください。
    ツールの使用について：
     - ツールは必要な場合のみ使用してください
     - 一般的な質問や日常会話には直接回答し、ツールを使用しないでください
     - 外部の最新情報、特定のAPIへのアクセスが明確に必要な場合のみツールを使用してください

    """
    
    init() {
        // 初期状態では空のツールリストで開始
        session = LanguageModelSession(
            tools: [],
            instructions: systemPrompt
        )
    }
    
    /// 指定したMCPサーバーに接続して動的ツールを作成・追加
    /// - Parameter serverURL: MCPサーバーのURL
    func connectAndUpdateTools(serverURL: URL) async throws {
        let serverKey = generateServerKey(from: serverURL)
        
        // 既存の接続があれば切断してから再接続
        if let existingClient = mcpClients[serverKey] {
            await existingClient.disconnect()
        }
        
        // 新しいクライアントを作成
        let mcpClient = MCPClientService()
        mcpClients[serverKey] = mcpClient
        
        // MCPサーバーに接続＆MCPツール取得
        try await mcpClient.connect(to: serverURL)
        
        // MCPツールをFoundationModels.Toolに変換
        let toolService = DynamicMCPToolService(mcpService: mcpClient)
        dynamicToolServices[serverKey] = toolService
        let newServerTools = toolService.createAllDynamicTools()
        serverTools[serverKey] = newServerTools
        
        // 全ツールを再構築
        rebuildAllTools()
        
        let serverName = extractServerName(from: serverURL)
        MCPStepNotificationService.shared.notifyStep("✅ \(serverName)のMCPツールが利用可能になりました: \(newServerTools.map { $0.name }.joined(separator: ", "))")
    }
    
    /// OAuth認証付きでMCPサーバーに接続して動的ツールを作成・追加
    /// - Parameter serverURL: MCPサーバーのURL
    func connectWithAuthAndUpdateTools(serverURL: URL) async throws {
        let serverKey = generateServerKey(from: serverURL)
        let serverName = extractServerName(from: serverURL)
        
        // 既存の接続があれば切断してから再接続
        if let existingClient = mcpClients[serverKey] {
            await existingClient.disconnect()
        }
        
        MCPStepNotificationService.shared.notifyStep("OAuth認証を確認しています...")
        
        // OAuth認証を実行
        let oauthService = OAuthService.shared
        let accessToken: String
        
        do {
            accessToken = try await oauthService.authenticate(serverURL: serverURL)
        } catch {
            MCPStepNotificationService.shared.notifyStep("❌ OAuth認証に失敗しました: \(error.localizedDescription)")
            throw error
        }
        
        // 新しいクライアントを作成
        let mcpClient = MCPClientService()
        mcpClients[serverKey] = mcpClient
        
        // OAuth認証付きでMCPサーバーに接続＆MCPツール取得
        try await mcpClient.connectWithAuth(to: serverURL, accessToken: accessToken)
        
        // MCPツールをFoundationModels.Toolに変換
        let toolService = DynamicMCPToolService(mcpService: mcpClient)
        dynamicToolServices[serverKey] = toolService
        let newServerTools = toolService.createAllDynamicTools()
        serverTools[serverKey] = newServerTools
        
        // 全ツールを再構築
        rebuildAllTools()
        
        MCPStepNotificationService.shared.notifyStep("✅ \(serverName)のOAuth認証付きMCPツールが利用可能になりました: \(newServerTools.map { $0.name }.joined(separator: ", "))")
    }
    
    /// 保存されたトークンを使用してMCPサーバーに接続
    /// - Parameter serverURL: MCPサーバーのURL
    /// - Returns: 接続が成功した場合はtrue
    func connectWithStoredToken(serverURL: URL) async -> Bool {
        let serverKey = generateServerKey(from: serverURL)
        let serverName = extractServerName(from: serverURL)
        
        // 保存されたトークンを確認
        guard let accessToken = TokenStorage.shared.getToken(for: serverURL) else {
            MCPStepNotificationService.shared.notifyStep("⚠️ \(serverName)の保存されたトークンが見つかりません")
            return false
        }
        
        // 既存の接続があれば切断
        if let existingClient = mcpClients[serverKey] {
            await existingClient.disconnect()
        }
        
        // 新しいクライアントを作成
        let mcpClient = MCPClientService()
        
        // トークンの有効性を確認
        if await mcpClient.validateAuthentication(endpoint: serverURL, accessToken: accessToken) {
            do {
                mcpClients[serverKey] = mcpClient
                
                // OAuth認証付きでMCPサーバーに接続
                try await mcpClient.connectWithAuth(to: serverURL, accessToken: accessToken)
                
                // MCPツールをFoundationModels.Toolに変換
                let toolService = DynamicMCPToolService(mcpService: mcpClient)
                dynamicToolServices[serverKey] = toolService
                let newServerTools = toolService.createAllDynamicTools()
                serverTools[serverKey] = newServerTools
                
                // 全ツールを再構築
                rebuildAllTools()
                
                MCPStepNotificationService.shared.notifyStep("✅ \(serverName)に保存されたトークンで接続しました")
                return true
                
            } catch {
                MCPStepNotificationService.shared.notifyStep("❌ \(serverName)への接続に失敗しました: \(error.localizedDescription)")
                return false
            }
        } else {
            MCPStepNotificationService.shared.notifyStep("⚠️ \(serverName)の保存されたトークンが無効です")
            // 無効なトークンを削除
            TokenStorage.shared.deleteToken(for: serverURL)
            return false
        }
    }
    
    /// 全てのサーバーから切断
    func disconnectAllServers() async {
        for (serverKey, client) in mcpClients {
            await client.disconnect()
            MCPStepNotificationService.shared.notifyStep("MCPサーバー \(serverKey) から切断しました")
        }
        
        mcpClients.removeAll()
        dynamicToolServices.removeAll()
        serverTools.removeAll()
        allDynamicTools.removeAll()
        
        // セッションを空のツールで更新
        updateSessionWithAllTools()
    }
    
    /// 特定のサーバーから切断
    /// - Parameter serverURL: 切断するサーバーのURL
    func disconnectFromServer(_ serverURL: URL) async {
        let serverKey = generateServerKey(from: serverURL)
        
        if let client = mcpClients[serverKey] {
            await client.disconnect()
            mcpClients.removeValue(forKey: serverKey)
            dynamicToolServices.removeValue(forKey: serverKey)
            serverTools.removeValue(forKey: serverKey)
            
            // 全ツールを再構築
            rebuildAllTools()
            
            let serverName = extractServerName(from: serverURL)
            MCPStepNotificationService.shared.notifyStep("\(serverName) から切断しました")
        }
    }
    
    /// サーバーごとのツールから全ツールリストを再構築
    private func rebuildAllTools() {
        allDynamicTools.removeAll()
        
        // 各サーバーのツールを統合
        for (_, tools) in serverTools {
            allDynamicTools.append(contentsOf: tools)
        }
        
        // セッションを更新
        updateSessionWithAllTools()
    }
    
    /// セッションを全ツールで更新
    private func updateSessionWithAllTools() {
        session = LanguageModelSession(
            tools: allDynamicTools,
            instructions: systemPrompt
        )
    }
    
    /// URLからサーバーキーを生成
    private func generateServerKey(from url: URL) -> String {
        return url.host ?? url.absoluteString
    }
    
    /// URLからサーバー名を抽出
    private func extractServerName(from url: URL) -> String {
        let host = url.host ?? "不明なサーバー"
        return host
    }
    
    /// 利用可能な全ツールの説明を取得
    private func getAllAvailableToolsDescription() -> String {
        if allDynamicTools.isEmpty {
            return "利用可能なツールはありません"
        }
        
        let descriptions = allDynamicTools.map { tool in
            "- \(tool.name)：\(tool.description)"
        }
        
        return descriptions.joined(separator: "\n")
    }
    
    /// 利用可能な動的ツールの一覧を取得
    func getAvailableDynamicTools() -> [(name: String, description: String)] {
        return allDynamicTools.map { (name: $0.name, description: $0.description) }
    }
    
    /// 接続中のサーバー情報を取得
    func getConnectedServers() -> [String: Bool] {
        var serverStatus: [String: Bool] = [:]
        for (serverKey, client) in mcpClients {
            serverStatus[serverKey] = client.isConnected
        }
        return serverStatus
    }
    
    /// 特定のサーバーの接続状況を確認
    func isServerConnected(_ serverURL: URL) -> Bool {
        let serverKey = generateServerKey(from: serverURL)
        return mcpClients[serverKey]?.isConnected ?? false
    }
    
    /// エラーメッセージをクリア
    func clearError() {
        errorMessage = nil
    }
    
    /// メッセージをAIに送信して応答を取得
    func generateResponse(for message: String) async throws -> String {
        do {
            let response = try await performAIRequest(message: message)
            return response
        } catch {
            throw AIServiceError.responseGenerationFailed
        }
    }
    
    /// Foundation Models Frameworkを使用してAIリクエストを実行
    private func performAIRequest(message: String) async throws -> String {
        do {
            let response = try await generateLLMResponse(userMessage: message)
            return response
        } catch {
            throw AIServiceError.responseGenerationFailed
        }
    }
    
    /// Foundation Models Frameworkを使用してLLM応答を生成（Tool Calling対応）
    private func generateLLMResponse(userMessage: String) async throws -> String {
        do {
            let response = try await session.respond(to: userMessage)
            return response.content
        } catch let error {
            // エラーメッセージを構築
            var dialogMessage = "Apple Intelligence エラー\n\n"
            if (error as NSError?) != nil {
                let errorString = error.localizedDescription.lowercased()
                dialogMessage += errorString
            }
            self.errorMessage = dialogMessage
            return dialogMessage
        }
    }
}

/// AIサービスのエラー定義
enum AIServiceError: LocalizedError {
    case responseGenerationFailed
    case networkError
    case authenticationError
    
    var errorDescription: String? {
        switch self {
        case .responseGenerationFailed:
            return "AI応答の生成に失敗しました"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .authenticationError:
            return "認証エラーが発生しました"
        }
    }
} 
