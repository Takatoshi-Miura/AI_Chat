import Foundation
import FoundationModels
import MCP

struct WeatherMCPTool: FoundationModels.Tool {
    
    let name = "getWeather"
    let description = "都市の天気予報、気温、降水確率、風速、波を取得できます。"
    
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
        do {
            // MCPClientServiceを初期化
            let mcpClient = MCPClientService()
            
            // リモートMCPサーバーのエンドポイント
            guard let endpoint = URL(string: "https://mcp-weather.get-weather.workers.dev") else {
                return ModelToolResult.failure("無効なエンドポイントURL")
            }
            
            // サーバーに接続
            try await mcpClient.connect(to: endpoint)
            
            // ツールの引数を準備
            let arguments: [String: Value] = [
                "city": mcpClient.stringValue(cityName)
            ]
            
            // get_weather_overviewツールを呼び出し
            let (content, isError) = try await mcpClient.callTool(
                name: "get_weather_overview",
                arguments: arguments
            )
            
            // 接続を切断
            await mcpClient.disconnect()
            
            // 結果を返す
            if isError {
                return ModelToolResult.failure("天気データの取得中にエラーが発生しました: \(content)")
            } else {
                return ModelToolResult.success(content)
            }
            
        } catch {
            return ModelToolResult.failure("MCP接続エラー: \(error.localizedDescription)")
        }
    }
}
