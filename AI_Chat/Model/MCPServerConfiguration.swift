import Foundation

/// MCPサーバーの設定情報を管理するモデル
struct MCPServerConfiguration: Identifiable, Codable, Equatable {
    /// 一意識別子
    let id: UUID
    
    /// サーバー名（ユーザーが識別しやすい名前）
    var name: String
    
    /// サーバーのURL
    var serverURL: URL
    
    /// OAuthクライアントID
    var clientId: String
    
    /// OAuthクライアントシークレット（Keychainに保存される）
    var clientSecret: String
    
    /// 作成日時
    let createdAt: Date
    
    /// 更新日時
    var updatedAt: Date
    
    /// 設定が有効かどうか
    var isEnabled: Bool
    
    init(
        name: String,
        serverURL: URL,
        clientId: String,
        clientSecret: String,
        isEnabled: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.serverURL = serverURL
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isEnabled = isEnabled
    }
    
    
    /// サーバー名を表示用に取得（URLのホスト名をフォールバック）
    var displayName: String {
        if name.isEmpty {
            return serverURL.host ?? "不明なサーバー"
        }
        return name
    }
    
    /// URLからサーバー名を抽出
    var hostName: String {
        return serverURL.host ?? "不明なサーバー"
    }
}

