import Foundation
import SwiftUI
import AuthenticationServices
import Combine

/// 認証状態の統合管理を担当するService
protocol AuthenticationServiceProtocol {
    /// 指定されたサーバーのOAuth認証を開始
    func authenticate(serverURL: URL) async throws -> String
    
    /// 指定されたサーバーからログアウト
    func logout(from serverURL: URL)
    
    /// 全てのサーバーからログアウト
    func logoutFromAllServers()
    
    /// 指定されたサーバーの認証状態を確認
    func isAuthenticated(for serverURL: URL) -> Bool
    
    /// 指定されたサーバーのアクセストークンを取得
    func getAccessToken(for serverURL: URL) -> String?
    
    /// 認証状態の変更を監視
    var authenticationStatePublisher: AnyPublisher<Bool, Never> { get }
}

@MainActor
class AuthenticationService: NSObject, AuthenticationServiceProtocol, ObservableObject {
    // MARK: - OAuth設定
    private let redirectUri = "ai-chat://oauth/callback"
    private let configurationService: MCPConfigurationServiceProtocol
    
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var currentServerURL: URL?
    @Published var authenticationError: String?
    @Published var isAuthenticating = false
    
    // MARK: - Private Properties
    private var authSession: ASWebAuthenticationSession?
    private let tokenStorage = TokenStorage.shared
    private var cancellables = Set<AnyCancellable>()
    
    var authenticationStatePublisher: AnyPublisher<Bool, Never> {
        $isAuthenticated.eraseToAnyPublisher()
    }
    
    init(configurationService: MCPConfigurationServiceProtocol) {
        self.configurationService = configurationService
        super.init()
        checkAuthenticationStatus()
    }
    
    // MARK: - Authentication Methods
    
    func authenticate(serverURL: URL) async throws -> String {
        currentServerURL = serverURL
        isAuthenticating = true
        authenticationError = nil
        
        MCPStepNotificationService.shared.notifyStep("OAuth認証を開始しています...")
        
        do {
            // 既存のトークンをチェック
            if let existingToken = tokenStorage.getToken(for: serverURL) {
                MCPStepNotificationService.shared.notifyStep("保存されたトークンを使用します")
                
                // トークンの有効性を確認
                if try await validateToken(existingToken, serverURL: serverURL) {
                    isAuthenticated = true
                    isAuthenticating = false
                    return existingToken
                } else {
                    MCPStepNotificationService.shared.notifyStep("保存されたトークンが無効です。再認証を行います")
                    tokenStorage.deleteToken(for: serverURL)
                }
            }
            
            // 新しい認証を実行
            let authorizationCode = try await performOAuthFlow(serverURL: serverURL)
            let accessToken = try await exchangeCodeForToken(authorizationCode, serverURL: serverURL)
            
            // トークンを保存
            tokenStorage.saveToken(accessToken, for: serverURL)
            
            isAuthenticated = true
            isAuthenticating = false
            
            MCPStepNotificationService.shared.notifyStep("✅ OAuth認証が完了しました")
            return accessToken
            
        } catch {
            isAuthenticating = false
            authenticationError = error.localizedDescription
            MCPStepNotificationService.shared.notifyStep("❌ OAuth認証に失敗しました: \(error.localizedDescription)")
            throw error
        }
    }
    
    func logout(from serverURL: URL) {
        tokenStorage.deleteToken(for: serverURL)
        
        if currentServerURL == serverURL {
            isAuthenticated = false
            currentServerURL = nil
        }
        
        checkAuthenticationStatus()
        MCPStepNotificationService.shared.notifyStep("ログアウトしました")
    }
    
    func logoutFromAllServers() {
        tokenStorage.deleteAllTokens()
        isAuthenticated = false
        currentServerURL = nil
        
        MCPStepNotificationService.shared.notifyStep("全てのサーバーからログアウトしました")
    }
    
    func isAuthenticated(for serverURL: URL) -> Bool {
        return tokenStorage.hasToken(for: serverURL)
    }
    
    func getAccessToken(for serverURL: URL) -> String? {
        return tokenStorage.getToken(for: serverURL)
    }
    
    // MARK: - Private Methods
    
    private func checkAuthenticationStatus() {
        let authenticatedServers = tokenStorage.getAllServerURLs()
        isAuthenticated = !authenticatedServers.isEmpty
        
        if let firstServer = authenticatedServers.first {
            currentServerURL = firstServer
        }
    }
    
    private func performOAuthFlow(serverURL: URL) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            // 認証URLを構築
            let authURL = buildAuthorizationURL(serverURL: serverURL)
            
            MCPStepNotificationService.shared.notifyStep("認証URL: \(authURL.absoluteString)")
            
            // ASWebAuthenticationSessionを作成
            authSession = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "ai-chat"
            ) { callbackURL, error in
                if let error = error {
                    MCPStepNotificationService.shared.notifyStep("❌ OAuth認証エラー: \(error.localizedDescription)")
                    continuation.resume(throwing: AuthenticationError.authenticationFailed(error.localizedDescription))
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    MCPStepNotificationService.shared.notifyStep("❌ コールバックURLが無効です")
                    continuation.resume(throwing: AuthenticationError.invalidCallback)
                    return
                }
                
                MCPStepNotificationService.shared.notifyStep("✅ コールバックURL: \(callbackURL.absoluteString)")
                
                // 認証コードを抽出
                guard let code = self.extractAuthorizationCode(from: callbackURL) else {
                    continuation.resume(throwing: AuthenticationError.invalidAuthorizationCode)
                    return
                }
                
                continuation.resume(returning: code)
            }
            
            authSession?.presentationContextProvider = self
            authSession?.prefersEphemeralWebBrowserSession = false
            authSession?.start()
        }
    }
    
    private func buildAuthorizationURL(serverURL: URL) -> URL {
        guard let configuration = configurationService.getConfiguration(for: serverURL) else {
            fatalError("設定が見つかりません: \(serverURL)")
        }
        
        var components = URLComponents(url: serverURL, resolvingAgainstBaseURL: false)!
        components.path = "/oauth/authorize"
        components.queryItems = [
            URLQueryItem(name: "client_id", value: configuration.clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "state", value: "ai-chat-auth-\(UUID().uuidString)")
        ]
        
        return components.url!
    }
    
    private func extractAuthorizationCode(from callbackURL: URL) -> String? {
        let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
        return components?.queryItems?.first(where: { $0.name == "code" })?.value
    }
    
    private func exchangeCodeForToken(_ code: String, serverURL: URL) async throws -> String {
        guard let configuration = configurationService.getConfiguration(for: serverURL) else {
            throw AuthenticationError.invalidConfiguration
        }
        
        let clientSecret = configuration.clientSecret
        
        let tokenURL = serverURL.appendingPathComponent("/oauth/token")
        
        MCPStepNotificationService.shared.notifyStep("トークン交換URL: \(tokenURL.absoluteString)")
        
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "grant_type": "authorization_code",
            "code": code,
            "client_id": configuration.clientId,
            "client_secret": clientSecret,
            "redirect_uri": redirectUri
        ]
        
        let body = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = body.data(using: .utf8)
        
        MCPStepNotificationService.shared.notifyStep("トークン交換リクエスト実行中...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthenticationError.invalidResponse
        }
        
        let responseBody = String(data: data, encoding: .utf8) ?? ""
        MCPStepNotificationService.shared.notifyStep("トークン交換レスポンス: HTTP \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            throw AuthenticationError.tokenExchangeFailed("HTTP \(httpResponse.statusCode): \(responseBody)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String else {
            throw AuthenticationError.invalidTokenResponse
        }
        
        MCPStepNotificationService.shared.notifyStep("✅ アクセストークンを取得しました")
        return accessToken
    }
    
    private func validateToken(_ token: String, serverURL: URL) async throws -> Bool {
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let testPayload = [
            "jsonrpc": "2.0",
            "id": 1,
            "method": "initialize",
            "params": [
                "protocolVersion": "2024-11-05",
                "capabilities": [:]
            ]
        ] as [String : Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: testPayload)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            
            return false
        } catch {
            return false
        }
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension AuthenticationService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}

// MARK: - AuthenticationError

enum AuthenticationError: LocalizedError {
    case authenticationFailed(String)
    case invalidCallback
    case invalidAuthorizationCode
    case invalidResponse
    case tokenExchangeFailed(String)
    case invalidTokenResponse
    case invalidConfiguration
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed(let message):
            return "認証に失敗しました: \(message)"
        case .invalidCallback:
            return "無効なコールバックURLです"
        case .invalidAuthorizationCode:
            return "認証コードが無効です"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .tokenExchangeFailed(let message):
            return "トークンの取得に失敗しました: \(message)"
        case .invalidTokenResponse:
            return "無効なトークンレスポンスです"
        case .invalidConfiguration:
            return "サーバー設定が見つかりません"
        }
    }
}