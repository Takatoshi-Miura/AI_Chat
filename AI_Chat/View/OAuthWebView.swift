import SwiftUI
import WebKit

/// OAuth認証用のWebView
struct OAuthWebView: UIViewRepresentable {
    let serverURL: URL
    @ObservedObject var oauthService: OAuthService
    @Environment(\.dismiss) private var dismiss
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        // OAuth認証URLを構築して読み込み
        let authURL = buildAuthorizationURL()
        let request = URLRequest(url: authURL)
        webView.load(request)
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // 必要に応じて更新処理を追加
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    /// OAuth認証URLを構築
    private func buildAuthorizationURL() -> URL {
        var components = URLComponents(url: serverURL, resolvingAgainstBaseURL: false)!
        components.path = "/oauth/authorize"
        components.queryItems = [
            URLQueryItem(name: "client_id", value: "client_f6d49594-1ef7-4128-8d54-7ab94284a4da"),
            URLQueryItem(name: "redirect_uri", value: "ai-chat://oauth/callback"),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "state", value: "ai-chat-auth-\(UUID().uuidString)")
        ]
        
        return components.url!
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: OAuthWebView
        
        init(_ parent: OAuthWebView) {
            self.parent = parent
        }
        
        /// ナビゲーションが開始された時の処理
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            
            // リダイレクトURLかどうかをチェック
            if url.scheme == "ai-chat" && url.host == "oauth" {
                // 認証コードを抽出
                if let code = extractAuthorizationCode(from: url) {
                    Task { @MainActor in
                        await handleAuthorizationCode(code)
                    }
                }
                
                decisionHandler(.cancel)
                return
            }
            
            decisionHandler(.allow)
        }
        
        /// 認証コードを抽出
        private func extractAuthorizationCode(from url: URL) -> String? {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            return components?.queryItems?.first(where: { $0.name == "code" })?.value
        }
        
        /// 認証コードを処理
        @MainActor
        private func handleAuthorizationCode(_ code: String) async {
            do {
                // 認証コードをアクセストークンに交換
                let accessToken = try await exchangeCodeForToken(code)
                
                // トークンを保存
                TokenStorage.shared.saveToken(accessToken, for: parent.serverURL)
                
                // OAuth認証完了を通知
                parent.oauthService.isAuthenticated = true
                parent.oauthService.currentServerURL = parent.serverURL
                
                MCPStepNotificationService.shared.notifyStep("✅ OAuth認証が完了しました")
                
                // WebViewを閉じる
                parent.dismiss()
                
            } catch {
                parent.oauthService.authenticationError = error.localizedDescription
                MCPStepNotificationService.shared.notifyStep("❌ OAuth認証に失敗しました: \(error.localizedDescription)")
                
                // WebViewを閉じる
                parent.dismiss()
            }
        }
        
        /// 認証コードをアクセストークンに交換
        private func exchangeCodeForToken(_ code: String) async throws -> String {
            let tokenURL = parent.serverURL.appendingPathComponent("/oauth/token")
            
            var request = URLRequest(url: tokenURL)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            
            let parameters = [
                "grant_type": "authorization_code",
                "code": code,
                "client_id": "client_f6d49594-1ef7-4128-8d54-7ab94284a4da",
                "client_secret": "secret_023ee679-9055-4eb7-9743-2fdff213ce0e",
                "redirect_uri": "ai-chat://oauth/callback"
            ]
            
            let body = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
            request.httpBody = body.data(using: .utf8)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OAuthError.invalidResponse
            }
            
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            MCPStepNotificationService.shared.notifyStep("WebView トークン交換レスポンス: HTTP \(httpResponse.statusCode) - \(responseBody)")
            
            guard httpResponse.statusCode == 200 else {
                throw OAuthError.tokenExchangeFailed("HTTP \(httpResponse.statusCode): \(responseBody)")
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let accessToken = json["access_token"] as? String else {
                throw OAuthError.invalidTokenResponse
            }
            
            MCPStepNotificationService.shared.notifyStep("✅ WebView でアクセストークンを取得しました")
            return accessToken
        }
        
        /// WebViewでエラーが発生した時の処理
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Task { @MainActor in
                parent.oauthService.authenticationError = error.localizedDescription
                MCPStepNotificationService.shared.notifyStep("❌ WebView エラー: \(error.localizedDescription)")
            }
        }
        
        /// WebViewでナビゲーションが失敗した時の処理
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            Task { @MainActor in
                parent.oauthService.authenticationError = error.localizedDescription
                MCPStepNotificationService.shared.notifyStep("❌ WebView ナビゲーションエラー: \(error.localizedDescription)")
            }
        }
        
        /// 新しいウィンドウが開かれる時の処理
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            // 新しいウィンドウではなく、現在のWebViewで開く
            if let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }
    }
}

/// OAuth認証WebViewをラップするView
struct OAuthAuthenticationView: View {
    let serverURL: URL
    @ObservedObject var oauthService = OAuthService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if oauthService.isAuthenticating {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("認証中...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    OAuthWebView(serverURL: serverURL, oauthService: oauthService)
                }
            }
            .navigationTitle("OAuth認証")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            oauthService.isAuthenticating = true
        }
        .onDisappear {
            oauthService.isAuthenticating = false
        }
    }
} 