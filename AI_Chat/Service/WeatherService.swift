//
//  WeatherService.swift
//  AI_Chat
//
//  Created by Claude on 2025/06/18.
//

import Foundation

/// 天気予報データモデル
struct WeatherResponse: Codable {
    let title: String
    let forecasts: [WeatherForecast]
    let location: WeatherLocation
    let copyright: WeatherCopyright
    let description: WeatherDescription
    let publicTime: String
    let publicTimeFormatted: String
    let publishingOffice: String
    let link: String
}

struct WeatherForecast: Codable {
    let date: String
    let dateLabel: String
    let telop: String
    let detail: WeatherDetail
    let temperature: WeatherTemperature
    let chanceOfRain: WeatherChanceOfRain
    let image: WeatherImage
}

struct WeatherDetail: Codable {
    let weather: String?
    let wind: String?
    let wave: String?
}

struct WeatherTemperature: Codable {
    let min: TemperatureValue
    let max: TemperatureValue
}

struct TemperatureValue: Codable {
    let celsius: String?
    let fahrenheit: String?
}

struct WeatherChanceOfRain: Codable {
    let T00_06: String
    let T06_12: String
    let T12_18: String
    let T18_24: String
}

struct WeatherImage: Codable {
    let title: String
    let url: String
    let width: Int
    let height: Int
}

struct WeatherLocation: Codable {
    let area: String
    let prefecture: String
    let district: String
    let city: String
}

struct WeatherCopyright: Codable {
    let title: String
    let link: String
    let image: WeatherImage
    let provider: [WeatherProvider]
}

struct WeatherProvider: Codable {
    let link: String
    let name: String
    let note: String
}

struct WeatherDescription: Codable {
    let publicTime: String
    let publicTimeFormatted: String
    let headlineText: String
    let bodyText: String
    let text: String
}

/// 天気予報サービス
class WeatherService {
    private let baseURL = "https://weather.tsukumijima.net/api/forecast"
    
    /// 指定された都市の天気予報を取得
    func getWeather(for cityId: String) async throws -> WeatherResponse {
        guard let url = URL(string: "\(baseURL)?city=\(cityId)") else {
            throw WeatherError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw WeatherError.networkError
        }
        
        do {
            let weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
            return weatherResponse
        } catch {
            throw WeatherError.decodingError
        }
    }
    
    /// 都市名から都市IDを検索（簡易実装）
    func getCityId(for cityName: String) -> String? {
        let cityMapping = [
            "東京": "130010",
            "大阪": "270000",
            "名古屋": "230010",
            "福岡": "400010",
            "札幌": "016010",
            "仙台": "040010",
            "広島": "340010",
            "金沢": "170010",
            "新潟": "150010",
            "静岡": "220010",
            "横浜": "140010",
            "神戸": "280010",
            "京都": "260010",
            "熊本": "430010",
            "鹿児島": "460010",
            "那覇": "471010"
        ]
        
        return cityMapping[cityName]
    }
}

/// 天気予報エラー定義
enum WeatherError: LocalizedError {
    case invalidURL
    case networkError
    case decodingError
    case cityNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .decodingError:
            return "データの解析に失敗しました"
        case .cityNotFound:
            return "指定された都市が見つかりません"
        }
    }
} 