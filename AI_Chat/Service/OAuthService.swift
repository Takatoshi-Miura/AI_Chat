import Foundation
import SwiftUI
import AuthenticationServices
import Combine

/// OAuth 2.0 認証サービス
@MainActor
class OAuthService: NSObject, ObservableObject {
    static let shared = OAuthService()
    
    // MARK: - OAuth設定
    private let clientId = "client_f6d49594-1ef7-4128-8d54-7ab94284a4da"
    private let clientSecret = "secret_023ee679-9055-4eb7-9743-2fdff213ce0e"
    private let redirectUri = "ai-chat://oauth/callback"
    
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var currentServerURL: URL?
    @Published var authenticationError: String?
    @Published var isAuthenticating = false
    
    // MARK: - Private Properties
    private var authSession: ASWebAuthenticationSession?
    private let tokenStorage = TokenStorage.shared
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
        checkAuthenticationStatus()
    }
    
    // MARK: - Public Methods
    
    /// 指定されたサーバーのOAuth認証を開始
    /// - Parameter serverURL: MCPサーバーのURL
    /// - Returns: 取得したアクセストークン
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
    
    /// 指定されたサーバーからログアウト
    /// - Parameter serverURL: MCPサーバーのURL
    func logout(from serverURL: URL) {
        tokenStorage.deleteToken(for: serverURL)
        
        if currentServerURL == serverURL {
            isAuthenticated = false
            currentServerURL = nil
        }
        
        MCPStepNotificationService.shared.notifyStep("ログアウトしました")
    }
    
    /// 全てのサーバーからログアウト
    func logoutFromAllServers() {
        tokenStorage.deleteAllTokens()
        isAuthenticated = false
        currentServerURL = nil
        
        MCPStepNotificationService.shared.notifyStep("全てのサーバーからログアウトしました")
    }
    
    /// 指定されたサーバーの認証状態を確認
    /// - Parameter serverURL: MCPサーバーのURL
    /// - Returns: 認証済みの場合はtrue
    func isAuthenticated(for serverURL: URL) -> Bool {
        return tokenStorage.hasToken(for: serverURL)
    }
    
    /// 指定されたサーバーのアクセストークンを取得
    /// - Parameter serverURL: MCPサーバーのURL
    /// - Returns: アクセストークン（存在しない場合はnil）
    func getAccessToken(for serverURL: URL) -> String? {
        return tokenStorage.getToken(for: serverURL)
    }
    
    // MARK: - Private Methods
    
    /// 認証状態をチェック
    private func checkAuthenticationStatus() {
        let authenticatedServers = tokenStorage.getAllServerURLs()
        isAuthenticated = !authenticatedServers.isEmpty
        
        if let firstServer = authenticatedServers.first {
            currentServerURL = firstServer
        }
    }
    
    /// OAuth認証フローを実行
    /// - Parameter serverURL: MCPサーバーのURL
    /// - Returns: 認証コード
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
                    continuation.resume(throwing: OAuthError.authenticationFailed(error.localizedDescription))
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    MCPStepNotificationService.shared.notifyStep("❌ コールバックURLが無効です")
                    continuation.resume(throwing: OAuthError.invalidCallback)
                    return
                }
                
                MCPStepNotificationService.shared.notifyStep("✅ コールバックURL: \(callbackURL.absoluteString)")
                
                // 認証コードを抽出
                guard let code = self.extractAuthorizationCode(from: callbackURL) else {
                    continuation.resume(throwing: OAuthError.invalidAuthorizationCode)
                    return
                }
                
                continuation.resume(returning: code)
            }
            
            authSession?.presentationContextProvider = self
            authSession?.prefersEphemeralWebBrowserSession = false
            authSession?.start()
        }
    }
    
    /// 認証URLを構築
    /// - Parameter serverURL: MCPサーバーのURL
    /// - Returns: 認証URL
    private func buildAuthorizationURL(serverURL: URL) -> URL {
        var components = URLComponents(url: serverURL, resolvingAgainstBaseURL: false)!
        components.path = "/oauth/authorize"
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "state", value: "ai-chat-auth-\(UUID().uuidString)")
        ]
        
        return components.url!
    }
    
    /// コールバックURLから認証コードを抽出
    /// - Parameter callbackURL: コールバックURL
    /// - Returns: 認証コード
    private func extractAuthorizationCode(from callbackURL: URL) -> String? {
        let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
        return components?.queryItems?.first(where: { $0.name == "code" })?.value
    }
    
    /// 認証コードをアクセストークンに交換
    /// - Parameters:
    ///   - code: 認証コード
    ///   - serverURL: MCPサーバーのURL
    /// - Returns: アクセストークン
    private func exchangeCodeForToken(_ code: String, serverURL: URL) async throws -> String {
        let tokenURL = serverURL.appendingPathComponent("/oauth/token")
        
        MCPStepNotificationService.shared.notifyStep("トークン交換URL: \(tokenURL.absoluteString)")
        
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "grant_type": "authorization_code",
            "code": code,
            "client_id": clientId,
            "client_secret": clientSecret,
            "redirect_uri": redirectUri
        ]
        
        let body = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = body.data(using: .utf8)
        
        MCPStepNotificationService.shared.notifyStep("トークン交換リクエスト: \(String(data: body.data(using: .utf8) ?? Data(), encoding: .utf8) ?? "")")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OAuthError.invalidResponse
        }
        
        let responseBody = String(data: data, encoding: .utf8) ?? ""
        MCPStepNotificationService.shared.notifyStep("トークン交換レスポンス: HTTP \(httpResponse.statusCode) - \(responseBody)")
        
        guard httpResponse.statusCode == 200 else {
            throw OAuthError.tokenExchangeFailed("HTTP \(httpResponse.statusCode): \(responseBody)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String else {
            throw OAuthError.invalidTokenResponse
        }
        
        MCPStepNotificationService.shared.notifyStep("✅ アクセストークンを取得しました")
        return accessToken
    }
    
    /// トークンの有効性を確認
    /// - Parameters:
    ///   - token: アクセストークン
    ///   - serverURL: MCPサーバーのURL
    /// - Returns: トークンが有効な場合はtrue
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

extension OAuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}

// MARK: - OAuthError

enum OAuthError: LocalizedError {
    case authenticationFailed(String)
    case invalidCallback
    case invalidAuthorizationCode
    case invalidResponse
    case tokenExchangeFailed(String)
    case invalidTokenResponse
    
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
        }
    }
} 