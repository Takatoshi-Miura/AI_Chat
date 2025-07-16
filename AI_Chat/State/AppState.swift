import Foundation
import Combine

/// アプリケーション全体の状態を管理するクラス
@MainActor
class AppState: ObservableObject {
    static let shared = AppState()
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var currentError: AppError?
    @Published var initializationError: String?
    
    // MARK: - State Properties
    private(set) var chatState = ChatState()
    private(set) var connectionState = ConnectionState()
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupStateObservers()
    }
    
    // MARK: - Public Methods
    
    /// エラーを設定
    func setError(_ error: AppError) {
        currentError = error
    }
    
    /// エラーをクリア
    func clearError() {
        currentError = nil
    }
    
    /// 初期化エラーを設定
    func setInitializationError(_ errorMessage: String) {
        initializationError = errorMessage
    }
    
    /// 初期化エラーをクリア
    func clearInitializationError() {
        initializationError = nil
    }
    
    /// ローディング状態を設定
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    // MARK: - Private Methods
    
    private func setupStateObservers() {
        // ChatStateの変更を監視
        chatState.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // ConnectionStateの変更を監視
        connectionState.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}

// MARK: - AppError

enum AppError: LocalizedError, Equatable {
    case networkError(String)
    case authenticationError(String)
    case connectionError(String)
    case aiServiceError(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "ネットワークエラー: \(message)"
        case .authenticationError(let message):
            return "認証エラー: \(message)"
        case .connectionError(let message):
            return "接続エラー: \(message)"
        case .aiServiceError(let message):
            return "AIサービスエラー: \(message)"
        case .unknownError(let message):
            return "不明なエラー: \(message)"
        }
    }
}