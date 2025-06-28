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
    @Published var availableResources: [Resource] = []
    @Published var availablePrompts: [Prompt] = []
    
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
        print("MCPサーバーへの接続を開始: \(endpoint)")
        
        // HTTPトランスポート作成
        transport = HTTPClientTransport(
            endpoint: endpoint,
            streaming: true // Server-Sent Eventsを有効化
        )
        
        guard let transport = transport else {
            throw MCPError.invalidRequest("Transportの作成に失敗しました")
        }
        
        // 接続実行
        let result = try await client.connect(transport: transport)
        
        // サーバー機能の確認
        print("サーバー機能:")
        if result.capabilities.tools != nil {
            print("- ツール機能: 利用可能")
        }
        if result.capabilities.resources != nil {
            print("- リソース機能: 利用可能")
        }
        if result.capabilities.prompts != nil {
            print("- プロンプト機能: 利用可能")
        }
        
        isConnected = true
        print("MCPサーバーに正常に接続しました")
        
        // 利用可能な機能を取得
        await loadAvailableCapabilities()
    }
    
    /// MCPサーバーから切断
    func disconnect() async {
        print("MCPサーバーから切断中...")
        
        await client.disconnect()
        transport = nil
        isConnected = false
        
        // 状態をリセット
        availableTools = []
        availableResources = []
        availablePrompts = []
        
        print("MCPサーバーから切断しました")
    }
    
    // MARK: - Tools
    
    /// 利用可能なツール一覧を取得
    func listTools() async throws -> [Tool] {
        guard isConnected else {
            throw MCPError.invalidRequest("サーバーに接続されていません")
        }
        
        print("ツール一覧を取得中...")
        let result = try await client.listTools()
        
        print("利用可能なツール: \(result.tools.map { $0.name }.joined(separator: ", "))")
        return result.tools
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
        
        print("ツール '\(toolName)' を実行中...")
        
        let (content, isError) = try await client.callTool(
            name: toolName,
            arguments: arguments
        )
        
        let errorFlag = isError ?? false
        if errorFlag {
            print("ツール '\(toolName)' の実行でエラーが発生しました")
        } else {
            print("ツール '\(toolName)' が正常に実行されました")
        }
        
        // コンテンツを文字列に変換
        let contentString = extractTextFromAny(content)
        return (contentString, errorFlag)
    }
    
    // MARK: - Resources
    
    /// 利用可能なリソース一覧を取得
    func listResources() async throws -> [Resource] {
        guard isConnected else {
            throw MCPError.invalidRequest("サーバーに接続されていません")
        }
        
        print("リソース一覧を取得中...")
        let result = try await client.listResources()
        return result.resources
    }
    
    /// リソースを読み取り
    /// - Parameter uri: リソースのURI
    /// - Returns: リソースの内容
    func readResource(uri: String) async throws -> String {
        guard isConnected else {
            throw MCPError.invalidRequest("サーバーに接続されていません")
        }
        
        print("リソース '\(uri)' を読み取り中...")
        
        let content = try await client.readResource(uri: uri)
        print("リソース '\(uri)' を正常に読み取りました")
        
        return extractTextFromAny(content)
    }
    
    // MARK: - Prompts
    
    /// 利用可能なプロンプト一覧を取得
    func listPrompts() async throws -> [Prompt] {
        guard isConnected else {
            throw MCPError.invalidRequest("サーバーに接続されていません")
        }
        
        print("プロンプト一覧を取得中...")
        let result = try await client.listPrompts()
        
        print("利用可能なプロンプト: \(result.prompts.map { $0.name }.joined(separator: ", "))")
        return result.prompts
    }
    
    /// プロンプトを取得
    /// - Parameters:
    ///   - name: プロンプト名
    ///   - arguments: 引数
    /// - Returns: プロンプトの内容
    func getPrompt(name: String, arguments: [String: Value] = [:]) async throws -> String {
        guard isConnected else {
            throw MCPError.invalidRequest("サーバーに接続されていません")
        }
        
        print("プロンプト '\(name)' を取得中...")
        
        let content = try await client.getPrompt(name: name, arguments: arguments)
        print("プロンプト '\(name)' を正常に取得しました")
        
        return extractTextFromAny(content)
    }
    
    // MARK: - Private Methods
    
    /// 利用可能な機能を取得して状態を更新
    private func loadAvailableCapabilities() async {
        do {
            // ツール一覧を取得
            availableTools = try await listTools()
        } catch {
            print("ツール一覧の取得に失敗: \(error)")
        }
        
        do {
            // リソース一覧を取得
            availableResources = try await listResources()
        } catch {
            print("リソース一覧の取得に失敗: \(error)")
        }
        
        do {
            // プロンプト一覧を取得
            availablePrompts = try await listPrompts()
        } catch {
            print("プロンプト一覧の取得に失敗: \(error)")
        }
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
