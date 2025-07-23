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
    
    /// すべてのMCPツールから動的Toolを作成
    /// - Returns: 作成されたFoundationModels.Toolの配列
    func createAllDynamicTools() -> [any FoundationModels.Tool] {
        return mcpService.availableTools.map { mcpTool in
            createDynamicTool(from: mcpTool)
        }
    }
    
    /// MCPツールから動的にFoundationModels.Toolを作成
    /// - Parameter mcpTool: MCPツール
    /// - Returns: 作成されたFoundationModels.Tool
    private func createDynamicTool(from mcpTool: MCP.Tool) -> any FoundationModels.Tool {
        // MCPツールの詳細情報を取得
        let (description, inputSchema) = mcpService.getToolDetails(mcpTool.name)
        
        // スキーマ情報を解析して詳細な説明文を生成
        let enhancedDescription = generateEnhancedDescription(
            toolName: mcpTool.name,
            baseDescription: description,
            schema: inputSchema
        )
        
        // 動的ツール構造体を作成
        return DynamicMCPTool(
            toolName: mcpTool.name,
            toolDescription: enhancedDescription,
            inputSchema: inputSchema,
            mcpService: mcpService
        )
    }
    
    /// スキーマ情報を使って拡張された説明文を生成
    /// - Parameters:
    ///   - toolName: ツール名
    ///   - baseDescription: 基本説明
    ///   - schema: スキーマ情報
    /// - Returns: 拡張された説明文
    private func generateEnhancedDescription(
        toolName: String,
        baseDescription: String?,
        schema: [String: Any]?
    ) -> String {
        var description = baseDescription ?? "MCPツール: \(toolName)"
        
        // スキーマ情報を解析
        if let schema = schema {
            // ネストされたスキーマ構造に対応
            var actualSchema: [String: Any] = schema
            if let someSchema = schema["some"] as? [String: Any] {
                actualSchema = someSchema
            }
            
            if let properties = actualSchema["properties"] as? [String: Any],
               let required = actualSchema["required"] as? [String] {
                
                description += "\n\n引数要件:"
                
                // 必須フィールドの説明を追加
                for (index, fieldName) in required.enumerated() {
                    if let fieldInfo = properties[fieldName] as? [String: Any] {
                        let fieldDesc = fieldInfo["description"] as? String ?? fieldName
                        description += "\n\(index + 1). \(fieldName): \(fieldDesc)"
                        
                        // enum値がある場合は利用可能な値を列挙
                        if let enumValues = fieldInfo["enum"] as? [String] {
                            if enumValues.count <= 20 {  // 値が多すぎない場合のみ表示
                                description += "\n   利用可能な値: \(enumValues.joined(separator: ", "))"
                            } else {
                                description += "\n   利用可能な値: \(enumValues.prefix(10).joined(separator: ", "))... (他\(enumValues.count - 10)個)"
                            }
                        }
                        
                        // 型情報を追加
                        if let type = fieldInfo["type"] as? String {
                            description += " (型: \(type))"
                        }
                    }
                }
            }
        }
        
        return description
    }
}
