import Foundation
import MCP

/// OAuth Bearer認証をサポートするHTTPトランスポートファクトリー
@MainActor
class AuthenticatedTransportFactory {
    
    /// 認証付きHTTPトランスポートを作成
    /// - Parameters:
    ///   - endpoint: 接続先のURL
    ///   - accessToken: OAuth アクセストークン
    ///   - streaming: Server-Sent Eventsを有効にするか
    /// - Returns: HTTPClientTransport
    static func createTransport(
        endpoint: URL,
        accessToken: String,
        streaming: Bool = true
    ) -> HTTPClientTransport {
        // 現在のMCP SDKの制限により、HTTPClientTransportに直接認証ヘッダーを設定できません
        // 代替案として、認証トークンをクエリパラメータとして追加する方法を試します
        
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "access_token", value: accessToken)
        ]
        
        let authenticatedEndpoint = components?.url ?? endpoint
        
        return HTTPClientTransport(
            endpoint: authenticatedEndpoint,
            streaming: streaming
        )
    }
    
    /// トークンの有効性を事前チェック
    /// - Parameters:
    ///   - endpoint: 接続先のURL
    ///   - accessToken: OAuth アクセストークン
    /// - Returns: トークンが有効な場合はtrue
    static func validateToken(endpoint: URL, accessToken: String) async -> Bool {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        // 簡単なMCPリクエストでトークンの有効性を確認
        let testPayload = [
            "jsonrpc": "2.0",
            "id": 1,
            "method": "initialize",
            "params": [
                "protocolVersion": "2024-11-05",
                "capabilities": [:]
            ]
        ] as [String : Any]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: testPayload)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            
            return false
        } catch {
            print("❌ トークン検証エラー: \(error.localizedDescription)")
            return false
        }
    }
}

/// 認証付きHTTPリクエストを送信するカスタムトランスポート
class CustomAuthenticatedHTTPTransport {
    
    private let endpoint: URL
    private let accessToken: String
    private let streaming: Bool
    
    init(endpoint: URL, accessToken: String, streaming: Bool = true) {
        self.endpoint = endpoint
        self.accessToken = accessToken
        self.streaming = streaming
    }
    
    /// 認証付きHTTPリクエストを送信
    /// - Parameter payload: MCPリクエストのペイロード
    /// - Returns: サーバーからのレスポンス
    func sendRequest(_ payload: [String: Any]) async throws -> [String: Any] {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        // CORS対応のヘッダーを追加
        request.setValue("*", forHTTPHeaderField: "Access-Control-Allow-Origin")
        request.setValue("GET, POST, OPTIONS", forHTTPHeaderField: "Access-Control-Allow-Methods")
        request.setValue("Content-Type, Authorization", forHTTPHeaderField: "Access-Control-Allow-Headers")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    throw NSError(domain: "MCPError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])
                }
            }
            
            guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw NSError(domain: "MCPError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])
            }
            
            return jsonResponse
        } catch {
            throw NSError(domain: "MCPError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Request failed: \(error.localizedDescription)"])
        }
    }
} 