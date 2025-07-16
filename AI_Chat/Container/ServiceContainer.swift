import Foundation
import Combine

/// アプリケーション全体の依存関係を管理するコンテナ
@MainActor
class ServiceContainer: ObservableObject {
    static let shared = ServiceContainer()
    
    // MARK: - Services
    private(set) lazy var aiService = AIService()
    private(set) lazy var authenticationService: AuthenticationServiceProtocol = AuthenticationService()
    private(set) lazy var chatService = ChatService(aiService: aiService)
    
    // MARK: - Repositories
    private(set) lazy var chatRepository = ChatRepository()
    private(set) lazy var mcpConnectionRepository = MCPConnectionRepository()
    
    // MARK: - Computed Services
    lazy var mcpConnectionService: MCPConnectionServiceProtocol = {
        return MCPConnectionService(
            aiService: aiService,
            connectionRepository: mcpConnectionRepository,
            authenticationService: authenticationService
        )
    }()
    
    private init() {
        // 初期化ロジック
        setupDependencies()
    }
    
    private func setupDependencies() {
        // サービス間の依存関係設定
        // 必要に応じて追加設定を行う
    }
    
    /// 依存関係を再構築（主にテスト用）
    func reset() {
        // リセットが必要な場合の処理
    }
}