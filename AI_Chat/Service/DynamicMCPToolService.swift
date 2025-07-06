import Foundation
import FoundationModels
import MCP

/// MCPツールから動的にFoundationModels.Toolを作成するサービス
@MainActor
class DynamicMCPToolService {
    
    private let mcpService: MCPClientService
    
    init(mcpService: MCPClientService) {
        self.mcpService = mcpService
    }
    
    /// MCPツールから動的にFoundationModels.Toolを作成
    /// - Parameter mcpTool: MCPツール
    /// - Returns: 作成されたFoundationModels.Tool
    func createDynamicTool(from mcpTool: MCP.Tool) -> any FoundationModels.Tool {
        // MCPツールの詳細情報を取得
        let (description, inputSchema) = mcpService.getToolDetails(mcpTool.name)
        
        // 動的ツール構造体を作成
        return DynamicMCPTool(
            toolName: mcpTool.name,
            toolDescription: description ?? "MCPツール: \(mcpTool.name)",
            inputSchema: inputSchema,
            mcpService: mcpService
        )
    }
    
    /// すべてのMCPツールから動的Toolを作成
    /// - Returns: 作成されたFoundationModels.Toolの配列
    func createAllDynamicTools() -> [any FoundationModels.Tool] {
        return mcpService.availableTools.map { mcpTool in
            createDynamicTool(from: mcpTool)
        }
    }
}

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
        @Guide(description: "都市名や引数を指定してください（例：東京、大阪など）")
        var input: String = ""
        
        @Guide(description: "追加の引数があれば JSON 形式で指定してください（オプション）")
        var additionalArgs: String = "{}"
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        let result = await executeMCPTool(input: arguments.input, additionalArgs: arguments.additionalArgs)
        return ToolOutput(result)
    }
    
    /// MCPツールを実行
    /// - Parameters:
    ///   - input: メイン入力値
    ///   - additionalArgs: 追加引数のJSON文字列
    /// - Returns: 実行結果
    private func executeMCPTool(input: String, additionalArgs: String) async -> String {
        return await performMCPToolCall(input: input, additionalArgs: additionalArgs)
    }
    
    /// 実際のMCPツール呼び出しを実行
    @MainActor
    private func performMCPToolCall(input: String, additionalArgs: String) async -> String {
        do {
            MCPStepNotificationService.shared.notifyStep("動的MCPツール '\(name)' を準備中...")
            print("Dynamic Tool Debug - Name: \(name), Input: \(input), AdditionalArgs: \(additionalArgs)")
            
            // 引数を準備
            let mcpArguments = try prepareArguments(input: input, additionalArgs: additionalArgs)
            print("Prepared MCP Arguments: \(mcpArguments)")
            
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
            let errorMessage = "動的MCPツール '\(name)' の実行中にエラーが発生しました: \(error.localizedDescription)"
            print("Dynamic Tool Error: \(errorMessage)")
            MCPStepNotificationService.shared.notifyStep("❌ \(errorMessage)")
            return errorMessage
        }
    }
    
    /// 引数を準備
    /// - Parameters:
    ///   - input: メイン入力値
    ///   - additionalArgs: 追加引数のJSON文字列
    /// - Returns: MCP用の引数辞書
    private func prepareArguments(input: String, additionalArgs: String) throws -> [String: Value] {
        var arguments: [String: Any] = [:]
        
        // メイン入力値を追加（一般的なキー名を試す）
        let mainKeys = ["city", "query", "input", "text", "value", "param"]
        
        // スキーマがある場合は、スキーマの最初のプロパティを使用
        if let schema = inputSchema,
           let properties = schema["properties"] as? [String: Any],
           let firstKey = properties.keys.first {
            arguments[firstKey] = input
            print("Using schema-based key: \(firstKey) = \(input)")
        } else {
            // スキーマがない場合は、一般的なキー名を試す
            arguments["city"] = input  // 天気ツールなどで一般的
            print("Using default key: city = \(input)")
        }
        
        // 追加引数を解析して追加
        if !additionalArgs.isEmpty && additionalArgs != "{}" {
            do {
                guard let jsonData = additionalArgs.data(using: .utf8) else {
                    throw NSError(domain: "DynamicMCPToolError", code: 1, userInfo: [NSLocalizedDescriptionKey: "JSON文字列の変換に失敗しました"])
                }
                
                let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
                
                if let additionalDict = jsonObject as? [String: Any] {
                    for (key, value) in additionalDict {
                        arguments[key] = value
                    }
                    print("Added additional arguments: \(additionalDict)")
                }
            } catch {
                print("Failed to parse additional arguments, ignoring: \(error)")
                // 追加引数の解析に失敗しても続行
            }
        }
        
        // MCP Value形式に変換
        return mcpService.convertArguments(arguments)
    }
} 
