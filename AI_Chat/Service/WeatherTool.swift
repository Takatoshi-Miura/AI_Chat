import Foundation
import FoundationModels

/// 天気予報取得ツール
struct WeatherTool: Tool {
    
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
    
    /// 天気予報ツールの実行
    private func executeWeatherTool(cityName: String) async -> ModelToolResult {
        do {
            // 都市名から都市IDを取得
            let weatherService = WeatherService()
            guard let cityId = weatherService.getCityId(for: cityName) else {
                let availableCities = "東京、大阪、名古屋、福岡、札幌、仙台、広島、金沢、新潟、静岡、横浜、神戸、京都、熊本、鹿児島、那覇"
                return ModelToolResult.failure("「\(cityName)」の天気予報は取得できません。利用可能な都市: \(availableCities)")
            }
            
            // 天気予報を取得
            let weatherData = try await weatherService.getWeather(for: cityId)
            
            // 結果を整形
            let formattedResult = formatWeatherResult(weatherData)
            
            return ModelToolResult.success(formattedResult)
            
        } catch let error as WeatherError {
            return ModelToolResult.failure("天気予報の取得に失敗しました: \(error.localizedDescription)")
        } catch {
            return ModelToolResult.failure("予期しないエラーが発生しました: \(error.localizedDescription)")
        }
    }
    
    /// 天気予報結果を整形
    private func formatWeatherResult(_ weatherData: WeatherResponse) -> String {
        var result = "【\(weatherData.location.prefecture)\(weatherData.location.city)の天気予報】\n"
        result += "発表: \(weatherData.publishingOffice) - \(weatherData.publicTimeFormatted)\n\n"
        
        // 天気概況
        result += "【天気概況】\n"
        result += "\(weatherData.description.headlineText)\n"
        result += "\(weatherData.description.bodyText)\n\n"
        
        // 各日の予報
        for (index, forecast) in weatherData.forecasts.enumerated() {
            result += "【\(forecast.dateLabel)（\(forecast.date)）】\n"
            result += "天気: \(forecast.telop)\n"
            
            // 気温
            if let maxTemp = forecast.temperature.max.celsius {
                result += "最高気温: \(maxTemp)°C"
            }
            if let minTemp = forecast.temperature.min.celsius {
                result += " / 最低気温: \(minTemp)°C"
            }
            result += "\n"
            
            // 降水確率
            result += "降水確率: "
            result += "0-6時:\(forecast.chanceOfRain.T00_06) "
            result += "6-12時:\(forecast.chanceOfRain.T06_12) "
            result += "12-18時:\(forecast.chanceOfRain.T12_18) "
            result += "18-24時:\(forecast.chanceOfRain.T18_24)\n"
            
            // 詳細（風・波）
            if let weather = forecast.detail.weather {
                result += "詳細天気: \(weather)\n"
            }
            if let wind = forecast.detail.wind {
                result += "風: \(wind)\n"
            }
            if let wave = forecast.detail.wave {
                result += "波: \(wave)\n"
            }
            
            if index < weatherData.forecasts.count - 1 {
                result += "\n"
            }
        }
        
        result += "\n※ 気象庁データより"
        
        return result
    }
}

/// Tool Calling結果
enum ModelToolResult {
    case success(String)
    case failure(String)
    
    var content: String {
        switch self {
        case .success(let content):
            return content
        case .failure(let error):
            return "エラー: \(error)"
        }
    }
} 
