import Foundation
import Security

/// OAuth アクセストークンの安全な保存・取得を管理するクラス
@MainActor
class TokenStorage {
    static let shared = TokenStorage()
    
    private let service = "ai-chat-mcp-tokens"
    
    private init() {}
    
    /// 指定されたサーバーのアクセストークンを保存
    /// - Parameters:
    ///   - token: 保存するアクセストークン
    ///   - serverURL: サーバーのURL
    func saveToken(_ token: String, for serverURL: URL) {
        let key = serverURL.absoluteString
        
        // 既存のトークンを削除
        deleteToken(for: serverURL)
        
        // 新しいトークンを保存
        let tokenData = token.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: tokenData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("✅ トークンを保存しました: \(key)")
        } else {
            print("❌ トークンの保存に失敗しました: \(key), Status: \(status)")
        }
    }
    
    /// 指定されたサーバーのアクセストークンを取得
    /// - Parameter serverURL: サーバーのURL
    /// - Returns: 保存されているアクセストークン（存在しない場合はnil）
    func getToken(for serverURL: URL) -> String? {
        let key = serverURL.absoluteString
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let tokenData = result as? Data,
           let token = String(data: tokenData, encoding: .utf8) {
            print("✅ トークンを取得しました: \(key)")
            return token
        } else {
            print("⚠️ トークンが見つかりません: \(key), Status: \(status)")
            return nil
        }
    }
    
    /// 指定されたサーバーのアクセストークンを削除
    /// - Parameter serverURL: サーバーのURL
    func deleteToken(for serverURL: URL) {
        let key = serverURL.absoluteString
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess {
            print("✅ トークンを削除しました: \(key)")
        } else if status == errSecItemNotFound {
            print("⚠️ 削除対象のトークンが見つかりません: \(key)")
        } else {
            print("❌ トークンの削除に失敗しました: \(key), Status: \(status)")
        }
    }
    
    /// 全てのトークンを削除
    func deleteAllTokens() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess {
            print("✅ 全てのトークンを削除しました")
        } else if status == errSecItemNotFound {
            print("⚠️ 削除対象のトークンが見つかりません")
        } else {
            print("❌ トークンの削除に失敗しました, Status: \(status)")
        }
    }
    
    /// 保存されているトークンが存在するかチェック
    /// - Parameter serverURL: サーバーのURL
    /// - Returns: トークンが存在する場合はtrue
    func hasToken(for serverURL: URL) -> Bool {
        return getToken(for: serverURL) != nil
    }
    
    /// 保存されている全てのサーバーURLを取得
    /// - Returns: トークンが保存されているサーバーURLの配列
    func getAllServerURLs() -> [URL] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let items = result as? [[String: Any]] {
            return items.compactMap { item in
                if let account = item[kSecAttrAccount as String] as? String {
                    return URL(string: account)
                }
                return nil
            }
        }
        
        return []
    }
} 