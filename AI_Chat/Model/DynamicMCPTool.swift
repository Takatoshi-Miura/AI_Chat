import Foundation
import FoundationModels
import MCP

/// 動的に作成されるMCPツール
struct DynamicMCPTool: FoundationModels.Tool {
    let name: String
    let description: String
    private let inputSchema: [String: Any]?
    private let mcpService: MCPClientService
    
    init(toolName: String, toolDescription: String, inputSchema: [String: Any]?, mcpService: MCPClientService) {
        self.name = toolName
        self.description = toolDescription
        self.inputSchema = inputSchema
        self.mcpService = mcpService
    }
    
    @Generable
    struct Arguments {
        @Guide(description: "引数を指定してください")
        var input: String = ""
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        let result = await executeMCPTool(input: arguments.input)
        return ToolOutput(result)
    }
    
    /// MCPツールを実行
    /// - Parameter input: メイン入力値
    /// - Returns: 実行結果
    private func executeMCPTool(input: String) async -> String {
        return await performMCPToolCall(input: input)
    }
    
    /// MCPツールを実行
    /// - Parameter input: メイン入力値
    /// - Returns: 実行結果
    @MainActor
    private func performMCPToolCall(input: String) async -> String {
        do {
            // 引数を準備
            let mcpArguments = try prepareArguments(input: input)
            
            // MCPサービスを通じてツールを呼び出し
            let (result, isError) = try await mcpService.callTool(
                name: name,
                arguments: mcpArguments
            )
            
            if isError {
                return "エラー: \(result)"
            }
            
            return result
            
        } catch {
            let errorMessage = "MCPツール '\(name)' の実行中にエラーが発生しました: \(error.localizedDescription)"
            MCPStepNotificationService.shared.notifyStep("❌ \(errorMessage)")
            return errorMessage
        }
    }
    
    /// 引数を準備
    /// - Parameter input: メイン入力値
    /// - Returns: MCP用の引数辞書
    private func prepareArguments(input: String) throws -> [String: Value] {
        var arguments: [String: Any] = [:]
        
        print("=== Preparing arguments for \(name) ===")
        print("Input: '\(input)'")
        
        // スキーマ情報を詳しく解析（ネストされた構造に対応）
        var actualSchema: [String: Any]?
        var requiredFields: [String] = []
        var properties: [String: Any] = [:]
        
        if let schema = inputSchema {
            print("Raw schema: \(schema)")
            
            // "some"キーの下にネストされている場合
            if let someSchema = schema["some"] as? [String: Any] {
                actualSchema = someSchema
                print("Found nested schema under 'some': \(someSchema)")
            } else {
                actualSchema = schema
            }
            
            if let actualSchema = actualSchema {
                if let schemaProperties = actualSchema["properties"] as? [String: Any] {
                    properties = schemaProperties
                    print("Schema properties: \(properties)")
                }
                
                if let required = actualSchema["required"] as? [String] {
                    requiredFields = required
                    print("Required fields: \(required)")
                }
            }
        } else {
            print("No schema available for this tool")
        }
        
        // メイン入力値を追加（スキーマベースの判定）
        var primaryField = "city" // デフォルト
        
        if !requiredFields.isEmpty {
            primaryField = requiredFields[0]
            arguments[primaryField] = input
            print("Using required field from schema: \(primaryField) = \(input)")
        } else if !properties.isEmpty, let firstKey = properties.keys.first {
            primaryField = firstKey
            arguments[primaryField] = input
            print("Using first property from schema: \(primaryField) = \(input)")
        } else {
            // フォールバック
            arguments[primaryField] = input
            print("Using fallback key: \(primaryField) = \(input)")
        }
        
        print("Final arguments before conversion: \(arguments)")
        
        // MCP Value形式に変換
        let convertedArguments = mcpService.convertArguments(arguments)
        print("Converted MCP arguments: \(convertedArguments)")
        print("=====================================")
        
        return convertedArguments
    }
} 
