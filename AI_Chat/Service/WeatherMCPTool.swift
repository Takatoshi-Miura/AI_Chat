import Foundation
import FoundationModels
import MCP

struct WeatherMCPTool: FoundationModels.Tool {
    
    let name = "getWeather"
    let description = "都市の天気予報、気温、降水確率、風速、波を取得できます。"
    
    let serverURL = URL(string: "https://mcp-weather.get-weather.workers.dev")
    
    @Generable
    struct Arguments {
        @Guide(description: "The city to get weather information for")
        var city: String
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        let cityName = arguments.city
        let result = await executeWeatherTool(cityName: cityName)
        return ToolOutput(result.content)
    }
    
    /// MCP-Weatherを使用して天気予報を取得する
    /// - Parameter cityName: 都市名
    /// - Returns: 天気予報
    private func executeWeatherTool(cityName: String) async -> ModelToolResult {
        return await performWeatherToolCall(cityName: cityName)
    }
    
    /// 実際のMCPツール呼び出しを実行
    @MainActor
    private func performWeatherToolCall(cityName: String) async -> ModelToolResult {
        let mcpClient = MCPClientService()
        
        do {
            guard let endpoint = serverURL else {
                return ModelToolResult.failure("無効なエンドポイントURL")
            }
            
            MCPStepNotificationService.shared.notifyStep("天気データ取得を開始します (都市: \(cityName))")
            
            // サーバーに接続
            try await mcpClient.connect(to: endpoint)
            
            // 特定のツールが利用可能かチェック
            let toolName = "get_weather_overview"
            guard mcpClient.isToolAvailable(toolName) else {
                await mcpClient.disconnect()
                let availableTools = mcpClient.availableTools.map { $0.name }.joined(separator: ", ")
                return ModelToolResult.failure("ツール '\(toolName)' は利用できません。利用可能なツール: \(availableTools)")
            }
            
            // ツールの引数を準備
            let arguments: [String: Value] = [
                "city": mcpClient.stringValue(cityName)
            ]
            
            print("ツール '\(toolName)' を呼び出し中...")
            
            // get_weather_overviewツールを呼び出し
            let (content, isError) = try await mcpClient.callTool(
                name: toolName,
                arguments: arguments
            )
            
            // 接続を切断
            await mcpClient.disconnect()
            
            // 結果を返す
            if isError {
                print("天気データ取得エラー: \(content)")
                return ModelToolResult.failure("天気データの取得中にエラーが発生しました: \(content)")
            } else {
                print("天気データ取得成功")
                MCPStepNotificationService.shared.notifyStep("天気データの取得が完了しました")
                return ModelToolResult.success(content)
            }
            
        } catch {
            // 確実に接続を切断
            await mcpClient.disconnect()
            
            let errorMessage = "MCP接続エラー: \(error.localizedDescription)"
            print(errorMessage)
            return ModelToolResult.failure(errorMessage)
        }
    }
}
