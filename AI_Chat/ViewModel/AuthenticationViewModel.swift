import Foundation
import Combine

/// 認証状態の管理を担当するViewModel
@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentServerURL: URL?
    @Published var authenticationError: String?
    @Published var isAuthenticating: Bool = false
    @Published var showingAuthManagementView: Bool = false
    @Published var showingOAuthView: Bool = false
    @Published var selectedServerURL: URL?
    
    private let authenticationService: AuthenticationServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    /// 認証対象のサーバー一覧
    let serverURLs: [URL] = [
        URL(string: "https://mcp-weather.get-weather.workers.dev")!
    ]
    
    init(authenticationService: AuthenticationServiceProtocol) {
        self.authenticationService = authenticationService
        
        setupObservers()
        checkInitialAuthenticationStatus()
    }
    
    // MARK: - Public Methods
    
    /// 指定されたサーバーの認証を開始
    func authenticate(serverURL: URL) async {
        selectedServerURL = serverURL
        showingOAuthView = true
        
        do {
            _ = try await authenticationService.authenticate(serverURL: serverURL)
        } catch {
            authenticationError = error.localizedDescription
        }
    }
    
    /// 指定されたサーバーからログアウト
    func logout(from serverURL: URL) {
        authenticationService.logout(from: serverURL)
    }
    
    /// 全てのサーバーからログアウト
    func logoutFromAllServers() {
        authenticationService.logoutFromAllServers()
    }
    
    /// 指定されたサーバーの認証状態を確認
    func isAuthenticated(for serverURL: URL) -> Bool {
        return authenticationService.isAuthenticated(for: serverURL)
    }
    
    /// 全サーバーの認証を実行
    func authenticateAllServers() async {
        for serverURL in serverURLs {
            if !authenticationService.isAuthenticated(for: serverURL) {
                await authenticate(serverURL: serverURL)
                break
            }
        }
    }
    
    /// 認証エラーをクリア
    func clearAuthenticationError() {
        authenticationError = nil
    }
    
    /// 認証管理画面を閉じる
    func dismissAuthManagementView() {
        showingAuthManagementView = false
    }
    
    /// OAuth認証画面を閉じる
    func dismissOAuthView() {
        showingOAuthView = false
        selectedServerURL = nil
    }
    
    /// 認証状況のサマリーを取得
    func getAuthenticationSummary() -> (authenticated: Int, total: Int) {
        let authenticatedCount = serverURLs.filter { authenticationService.isAuthenticated(for: $0) }.count
        return (authenticated: authenticatedCount, total: serverURLs.count)
    }
    
    /// 個別サーバーの認証状況を取得
    func getServerAuthenticationStatus() -> [(serverURL: URL, serverName: String, isAuthenticated: Bool)] {
        return serverURLs.map { url in
            let serverName = url.host ?? "不明なサーバー"
            let isAuthenticated = authenticationService.isAuthenticated(for: url)
            return (serverURL: url, serverName: serverName, isAuthenticated: isAuthenticated)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // AuthenticationServiceの状態変更を監視
        authenticationService.authenticationStatePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.isAuthenticated, on: self)
            .store(in: &cancellables)
        
        // 認証サービスから直接状態を監視
        if let service = authenticationService as? AuthenticationService {
            service.$currentServerURL
                .receive(on: DispatchQueue.main)
                .assign(to: \.currentServerURL, on: self)
                .store(in: &cancellables)
            
            service.$authenticationError
                .receive(on: DispatchQueue.main)
                .assign(to: \.authenticationError, on: self)
                .store(in: &cancellables)
            
            service.$isAuthenticating
                .receive(on: DispatchQueue.main)
                .assign(to: \.isAuthenticating, on: self)
                .store(in: &cancellables)
        }
    }
    
    private func checkInitialAuthenticationStatus() {
        // 初期認証状態をチェック
        isAuthenticated = serverURLs.contains { authenticationService.isAuthenticated(for: $0) }
        currentServerURL = serverURLs.first { authenticationService.isAuthenticated(for: $0) }
    }
}