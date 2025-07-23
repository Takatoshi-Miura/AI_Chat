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
    private var customTransport: CustomAuthenticatedHTTPTransport?
    @Published var isConnected = false
    @Published var availableTools: [MCP.Tool] = []
    
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
            throw NSError(domain: "MCPError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Transportの作成に失敗しました"])
        }
        
        // 接続実行
        _ = try await client.connect(transport: transport)
        isConnected = true
        MCPStepNotificationService.shared.notifyStep("✅ MCP サーバーに接続完了")
        
        // ツール一覧を取得
        availableTools = try await listTools()
    }
    
    /// OAuth認証付きでMCPサーバーに接続
    /// - Parameters:
    ///   - endpoint: 接続先のURL
    ///   - accessToken: OAuth アクセストークン
    func connectWithAuth(to endpoint: URL, accessToken: String) async throws {
        MCPStepNotificationService.shared.notifyStep("OAuth認証付きでMCPサーバーへの接続を開始しています...")
        
        // カスタム認証トランスポートを作成
        customTransport = CustomAuthenticatedHTTPTransport(
            endpoint: endpoint,
            accessToken: accessToken,
            streaming: true
        )
        
        // 基本的なMCPハンドシェイクを実行
        let initializePayload = [
            "jsonrpc": "2.0",
            "id": 1,
            "method": "initialize",
            "params": [
                "protocolVersion": "2024-11-05",
                "capabilities": [
                    "tools": [:]
                ]
            ]
        ] as [String : Any]
        
        guard let customTransport = customTransport else {
            throw NSError(domain: "MCPError", code: -1, userInfo: [NSLocalizedDescriptionKey: "カスタムトランスポートの作成に失敗しました"])
        }
        
        // 初期化リクエストを送信
        let response = try await customTransport.sendRequest(initializePayload)
        
        // レスポンスを確認
        if let error = response["error"] {
            throw NSError(domain: "MCPError", code: -1, userInfo: [NSLocalizedDescriptionKey: "初期化エラー: \(error)"])
        }
        
        // 初期化完了通知を送信
        let initializedPayload = [
            "jsonrpc": "2.0",
            "method": "notifications/initialized",
            "params": [:]
        ] as [String : Any]
        
        _ = try await customTransport.sendRequest(initializedPayload)
        
        isConnected = true
        MCPStepNotificationService.shared.notifyStep("✅ OAuth認証付きMCPサーバーに接続完了")
        
        // ツール一覧を取得
        availableTools = try await listToolsWithAuth()
    }
    
    /// 指定されたサーバーの認証状態を確認
    /// - Parameters:
    ///   - endpoint: 接続先のURL
    ///   - accessToken: OAuth アクセストークン
    /// - Returns: 認証が有効な場合はtrue
    func validateAuthentication(endpoint: URL, accessToken: String) async -> Bool {
        return await AuthenticatedTransportFactory.validateToken(endpoint: endpoint, accessToken: accessToken)
    }
    
    /// MCPサーバーから切断
    func disconnect() async {
        MCPStepNotificationService.shared.notifyStep("MCPサーバーから切断しています...")
        
        if transport != nil {
            await client.disconnect()
            transport = nil
        }
        
        customTransport = nil
        isConnected = false
        availableTools = []
        
        MCPStepNotificationService.shared.notifyStep("MCPサーバーから切断しました")
    }
    
    // MARK: - Tools
    
    /// 利用可能なツール一覧を取得
    /// - Returns: ツール一覧
    private func listTools() async throws -> [MCP.Tool] {
        guard isConnected else {
            throw NSError(domain: "MCPError", code: -1, userInfo: [NSLocalizedDescriptionKey: "サーバーに接続されていません"])
        }
        
        do {
            let result = try await client.listTools()
            let tools = result.tools
            MCPStepNotificationService.shared.notifyStep("✅ ツール一覧を取得しました (\(tools.count)個)")
            return tools
        } catch {
            MCPStepNotificationService.shared.notifyStep("❌ ツール一覧の取得に失敗しました: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// OAuth認証付きでツール一覧を取得
    /// - Returns: ツール一覧
    private func listToolsWithAuth() async throws -> [MCP.Tool] {
        guard let customTransport = customTransport else {
            throw NSError(domain: "MCPError", code: -1, userInfo: [NSLocalizedDescriptionKey: "認証付きトランスポートが設定されていません"])
        }
        
        let listToolsPayload = [
            "jsonrpc": "2.0",
            "id": 2,
            "method": "tools/list",
            "params": [:]
        ] as [String : Any]
        
        do {
            let response = try await customTransport.sendRequest(listToolsPayload)
            
            if let error = response["error"] {
                throw NSError(domain: "MCPError", code: -1, userInfo: [NSLocalizedDescriptionKey: "ツール一覧取得エラー: \(error)"])
            }
            
            guard let result = response["result"] as? [String: Any],
                  let toolsArray = result["tools"] as? [[String: Any]] else {
                throw NSError(domain: "MCPError", code: -1, userInfo: [NSLocalizedDescriptionKey: "無効なツール一覧レスポンス"])
            }
            
            let tools = toolsArray.compactMap { toolDict -> MCP.Tool? in
                guard let name = toolDict["name"] as? String else { return nil }
                let description = toolDict["description"] as? String
                let inputSchema = toolDict["inputSchema"] as? [String: Any]
                
                // [String: Any]をValue?に変換
                let inputSchemaValue: Value? = inputSchema != nil ? convertToValue(inputSchema!) : nil
                
                return MCP.Tool(
                    name: name,
                    description: description ?? "",
                    inputSchema: inputSchemaValue
                )
            }
            
            MCPStepNotificationService.shared.notifyStep("✅ 認証付きツール一覧を取得しました (\(tools.count)個)")
            return tools
        } catch {
            MCPStepNotificationService.shared.notifyStep("❌ 認証付きツール一覧の取得に失敗しました: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// ツールの詳細情報を取得
    /// - Parameter toolName: ツール名
    /// - Returns: (説明, 入力スキーマ)
    func getToolDetails(_ toolName: String) -> (description: String?, inputSchema: [String: Any]?) {
        guard let tool = availableTools.first(where: { $0.name == toolName }) else {
            return (nil, nil)
        }
        
        // Value?を[String: Any]?に変換
        let inputSchemaDict: [String: Any]? = tool.inputSchema != nil ? convertValueToDict(tool.inputSchema!) : nil
        
        return (description: tool.description, inputSchema: inputSchemaDict)
    }
    
    /// ツールが利用可能かチェック
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
            throw NSError(domain: "MCPError", code: -1, userInfo: [NSLocalizedDescriptionKey: "サーバーに接続されていません"])
        }
        
        // 引数の詳細を表示
        let argumentsText = arguments.isEmpty ? "なし" : arguments.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        MCPStepNotificationService.shared.notifyStep("MCPツール '\(toolName)' を実行中... (引数: \(argumentsText))")
        
        // カスタムトランスポートを使用する場合
        if let customTransport = customTransport {
            return try await callToolWithAuth(name: toolName, arguments: arguments, transport: customTransport)
        }
        
        // 標準トランスポートを使用する場合
        do {
            let (content, isError) = try await client.callTool(
                name: toolName,
                arguments: arguments
            )
            
            let errorFlag = isError ?? false
            if errorFlag {
                MCPStepNotificationService.shared.notifyStep("❌ MCPツール '\(toolName)' の実行でエラーが発生しました")
                let contentString = extractTextFromAny(content)
                return (contentString, errorFlag)
            } else {
                MCPStepNotificationService.shared.notifyStep("✅ MCPツール '\(toolName)' の実行が完了しました")
                let contentString = extractTextFromAny(content)
                return (contentString, errorFlag)
            }
            
        } catch {
            MCPStepNotificationService.shared.notifyStep("❌ MCPツール '\(toolName)' の呼び出しで例外が発生しました: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// OAuth認証付きでツールを呼び出し
    /// - Parameters:
    ///   - toolName: ツール名
    ///   - arguments: 引数
    ///   - transport: カスタムトランスポート
    /// - Returns: ツールの実行結果とエラー状態
    private func callToolWithAuth(name toolName: String, arguments: [String: Value], transport: CustomAuthenticatedHTTPTransport) async throws -> (content: String, isError: Bool) {
        
        // MCP Value を JSON 互換の値に変換
        let jsonArguments = convertMCPValuesToJSON(arguments)
        
        let callToolPayload = [
            "jsonrpc": "2.0",
            "id": 3,
            "method": "tools/call",
            "params": [
                "name": toolName,
                "arguments": jsonArguments
            ]
        ] as [String : Any]
        
        do {
            let response = try await transport.sendRequest(callToolPayload)
            
            if let error = response["error"] {
                MCPStepNotificationService.shared.notifyStep("❌ MCPツール '\(toolName)' の実行でエラーが発生しました")
                return ("エラー: \(error)", true)
            }
            
            guard let result = response["result"] as? [String: Any] else {
                throw NSError(domain: "MCPError", code: -1, userInfo: [NSLocalizedDescriptionKey: "無効なツール実行レスポンス"])
            }
            
            let content = extractTextFromAny(result["content"] ?? "")
            let isError = result["isError"] as? Bool ?? false
            
            if isError {
                MCPStepNotificationService.shared.notifyStep("❌ MCPツール '\(toolName)' の実行でエラーが発生しました")
            } else {
                MCPStepNotificationService.shared.notifyStep("✅ MCPツール '\(toolName)' の実行が完了しました")
            }
            
            return (content, isError)
        } catch {
            MCPStepNotificationService.shared.notifyStep("❌ MCPツール '\(toolName)' の呼び出しで例外が発生しました: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Utility Methods
    
    /// MCP Value を JSON 互換の値に変換
    /// - Parameter values: MCP Value の辞書
    /// - Returns: JSON 互換の値の辞書
    private func convertMCPValuesToJSON(_ values: [String: Value]) -> [String: Any] {
        var result: [String: Any] = [:]
        
        for (key, value) in values {
            switch value {
            case .string(let str):
                result[key] = str
            case .double(let num):
                result[key] = num
            case .bool(let bool):
                result[key] = bool
            case .array(let arr):
                result[key] = arr.map { convertValueToJSON($0) }
            case .object(let obj):
                result[key] = obj.mapValues { convertValueToJSON($0) }
            case .null:
                result[key] = NSNull()
            @unknown default:
                result[key] = NSNull()
            }
        }
        
        return result
    }
    
    /// 個別の Value を JSON 互換の値に変換
    /// - Parameter value: MCP Value
    /// - Returns: JSON 互換の値
    private func convertValueToJSON(_ value: Value) -> Any {
        switch value {
        case .string(let str):
            return str
        case .double(let num):
            return num
        case .bool(let bool):
            return bool
        case .array(let arr):
            return arr.map { convertValueToJSON($0) }
        case .object(let obj):
            return obj.mapValues { convertValueToJSON($0) }
        case .null:
            return NSNull()
        @unknown default:
            return NSNull()
        }
    }
    
    /// Any値からテキストを抽出
    private func extractTextFromAny(_ content: Any) -> String {
        if let string = content as? String {
            return string
        } else if let array = content as? [Any] {
            return array.compactMap { item in
                if let dict = item as? [String: Any],
                   let text = dict["text"] as? String {
                    return text
                }
                return String(describing: item)
            }.joined(separator: "\n")
        } else if let dict = content as? [String: Any] {
            if let text = dict["text"] as? String {
                return text
            }
            return dict.compactMap { key, value in
                "\(key): \(value)"
            }.joined(separator: "\n")
        } else {
            return String(describing: content)
        }
    }
    
    /// Value配列を作成
    private func arrayValue(_ array: [Any]) -> Value {
        let values = array.compactMap { convertToValue($0) }
        return .array(values)
    }
    
    /// Valueオブジェクトを作成
    private func objectValue(_ dict: [String: Any]) -> Value {
        let values = dict.compactMapValues { convertToValue($0) }
        return .object(values)
    }
    
    /// Any値をValueに変換
    private func convertToValue(_ value: Any) -> Value? {
        switch value {
        case let string as String:
            return .string(string)
        case let int as Int:
            return .double(Double(int))
        case let double as Double:
            return .double(double)
        case let bool as Bool:
            return .bool(bool)
        case let array as [Any]:
            return arrayValue(array)
        case let dict as [String: Any]:
            return objectValue(dict)
        default:
            return nil
        }
    }
    
    /// ValueをAnyに変換（逆変換）
    private func convertValueToAny(_ value: Value) -> Any {
        switch value {
        case .string(let str):
            return str
        case .double(let num):
            return num
        case .bool(let bool):
            return bool
        case .array(let arr):
            return arr.map { convertValueToAny($0) }
        case .object(let obj):
            return obj.mapValues { convertValueToAny($0) }
        case .null:
            return NSNull()
        @unknown default:
            return NSNull()
        }
    }
    
    /// ValueをDictに変換
    private func convertValueToDict(_ value: Value) -> [String: Any]? {
        let anyValue = convertValueToAny(value)
        return anyValue as? [String: Any]
    }
    
    /// 辞書をValue辞書に変換する便利メソッド
    func convertArguments(_ args: [String: Any]) -> [String: Value] {
        print("=== Converting Arguments to MCP Values ===")
        print("Input arguments: \(args)")
        
        let result = args.compactMapValues { value in
            let convertedValue = convertToValue(value)
            print("Converting \(value) (type: \(type(of: value))) -> \(convertedValue?.description ?? "nil")")
            return convertedValue
        }
        
        print("Final MCP Values: \(result)")
        print("=========================================")
        
        return result
    }
}
