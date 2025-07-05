import MCP
import SwiftUI
import UIKit
import Combine
import Foundation

@MainActor
class MCPClientService: ObservableObject {
    // MARK: - Properties
    private let client: Client
    private var transport: HTTPClientTransport?
    @Published var isConnected = false
    @Published var availableTools: [Tool] = []
    
    // MARK: - Initialization
    init(appName: String = "AI_Chat", appVersion: String = "1.0.0") {
        // クライアント初期化
        self.client = Client(
            name: appName,
            version: appVersion
        )
    }
    
    // MARK: - Connection Management
    
    /// MCPサーバーに接続
    /// - Parameter endpoint: 接続先のURL
    func connect(to endpoint: URL) async throws {
        MCPStepNotificationService.shared.notifyStep("MCPサーバーへの接続を開始しています...")
        
        // HTTPトランスポート作成
        transport = HTTPClientTransport(
            endpoint: endpoint,
            streaming: true // Server-Sent Eventsを有効化
        )
        
        guard let transport = transport else {
            throw MCPError.invalidRequest("Transportの作成に失敗しました")
        }
        
        // 接続実行
        _ = try await client.connect(transport: transport)
        isConnected = true
        MCPStepNotificationService.shared.notifyStep("✅ MCP サーバーに接続完了")
        
        // ツール一覧を取得
        availableTools = try await listTools()
    }
    
    /// MCPサーバーから切断
    func disconnect() async {
        MCPStepNotificationService.shared.notifyStep("MCPサーバーから切断しています...")
        
        await client.disconnect()
        transport = nil
        isConnected = false
        
        // 状態をリセット
        availableTools = []
        
        MCPStepNotificationService.shared.notifyStep("MCPサーバーから切断しました")
    }
    
    // MARK: - Tools
    
    /// 利用可能なツール一覧を取得
    private func listTools() async throws -> [Tool] {
        guard isConnected else {
            throw MCPError.invalidRequest("サーバーに接続されていません")
        }
        
        let result = try await client.listTools()
        if !result.tools.isEmpty {
            let toolNames = result.tools.map { $0.name }.joined(separator: ", ")
            MCPStepNotificationService.shared.notifyStep("利用可能なMCPツール: \(toolNames)")
        } else {
            MCPStepNotificationService.shared.notifyStep("利用可能なMCPツールが見つかりませんでした")
        }
        return result.tools
    }
    
    /// 指定されたツールが利用可能かどうかを確認
    /// - Parameter toolName: ツール名
    /// - Returns: ツールが利用可能な場合はtrue
    func isToolAvailable(_ toolName: String) -> Bool {
        return availableTools.contains { $0.name == toolName }
    }
    
    /// ツールを呼び出し
    /// - Parameters:
    ///   - toolName: ツール名
    ///   - arguments: 引数
    /// - Returns: ツールの実行結果とエラー状態
    func callTool(name toolName: String, arguments: [String: Value] = [:]) async throws -> (content: String, isError: Bool) {
        guard isConnected else {
            throw MCPError.invalidRequest("サーバーに接続されていません")
        }
        
        // 引数の詳細を表示
        let argumentsText = arguments.isEmpty ? "なし" : arguments.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        MCPStepNotificationService.shared.notifyStep("MCPツール '\(toolName)' を実行中... (引数: \(argumentsText))")
        
        let (content, isError) = try await client.callTool(
            name: toolName,
            arguments: arguments
        )
        
        let errorFlag = isError ?? false
        if errorFlag {
            MCPStepNotificationService.shared.notifyStep("❌ MCPツール '\(toolName)' の実行でエラーが発生しました")
        } else {
            MCPStepNotificationService.shared.notifyStep("✅ MCPツール '\(toolName)' の実行が完了しました")
        }
        
        // コンテンツを文字列に変換
        let contentString = extractTextFromAny(content)
        return (contentString, errorFlag)
    }
    
    // MARK: - Utility Methods
    
    /// 任意の型からテキストを抽出
    /// - Parameter content: コンテンツ
    /// - Returns: 抽出されたテキスト
    private func extractTextFromAny(_ content: Any) -> String {
        if let string = content as? String {
            return string
        }
        
        if let array = content as? [Any] {
            return array.compactMap { item in
                if let string = item as? String {
                    return string
                }
                return String(describing: item)
            }.joined(separator: "\n")
        }
        
        if let dict = content as? [String: Any] {
            if let text = dict["text"] as? String {
                return text
            }
            if let content = dict["content"] as? String {
                return content
            }
        }
        
        return String(describing: content)
    }
    
    // MARK: - Helper Methods for Value Conversion
    
    /// String値をValueに変換
    func stringValue(_ string: String) -> Value {
        return .string(string)
    }
    
    /// Int値をValueに変換
    func intValue(_ int: Int) -> Value {
        return .string(String(int))
    }
    
    /// Double値をValueに変換
    func doubleValue(_ double: Double) -> Value {
        return .string(String(double))
    }
    
    /// Bool値をValueに変換
    func boolValue(_ bool: Bool) -> Value {
        return .string(String(bool))
    }
    
    /// Array値をValueに変換
    func arrayValue(_ array: [Any]) -> Value {
        let convertedArray = array.compactMap { value -> Value? in
            return convertToValue(value)
        }
        return .array(convertedArray)
    }
    
    /// Dictionary値をValueに変換
    func objectValue(_ dict: [String: Any]) -> Value {
        let convertedDict = dict.compactMapValues { value -> Value? in
            return convertToValue(value)
        }
        return .object(convertedDict)
    }
    
    /// Any値をValueに変換
    private func convertToValue(_ value: Any) -> Value? {
        switch value {
        case let string as String:
            return .string(string)
        case let int as Int:
            return .string(String(int))
        case let double as Double:
            return .string(String(double))
        case let bool as Bool:
            return .string(String(bool))
        case let array as [Any]:
            return arrayValue(array)
        case let dict as [String: Any]:
            return objectValue(dict)
        default:
            return nil
        }
    }
    
    /// 辞書をValue辞書に変換する便利メソッド
    func convertArguments(_ args: [String: Any]) -> [String: Value] {
        return args.compactMapValues { value in
            return convertToValue(value)
        }
    }
}
