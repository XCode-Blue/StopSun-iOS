//
//  WeatherManager.swift
//  StopSun
//
//  Created by J on 1/27/26.
//

import Foundation
import Moya

/// 날씨 API 관리자
///
/// WeatherAPI를 통해 현재 및 과거 UV Index를 조회합니다.
///
final class WeatherManager: WeatherManagerProtocol {
    
    // MARK: - Properties
    
    private let apiClient: WeatherAPIClient
    
    // MARK: Init
    
    init(apiClient: WeatherAPIClient = WeatherAPIClient()) {
        self.apiClient = apiClient
    }

    func fetchCurrentUVIndex(for location: LocationInfo) async throws -> Double {
        let response = try await apiClient.request(
            WeatherAPI.current(
                lat: location.latitude,
                lon: location.longitude
            )
        )
        
        return response.current?.uv ?? 0.0
    }
    
    func fetchCurrentWeather(for location: LocationInfo) async throws -> LocationWeather {
        let response = try await apiClient.request(
            WeatherAPI.forecast(
                lat: location.latitude,
                lon: location.longitude,
                days: 1
            )
        )
        
        return mapToLocationWeather(response: response, location: location)
    }
    
    func fetchUVIndex(for location: LocationInfo, at date: Date) async throws -> Double {
        let response = try await apiClient.request(
            WeatherAPI.history(
                lat: location.latitude,
                lon: location.longitude,
                date: date.toAPIDateString
            )
        )
        
        // 해당 시간대의 UV Index 찾기
        let hour = Calendar.current.component(.hour, from: date)
        
        if let forecastDay = response.forecast?.forecastday.first,
           let hourData = forecastDay.hour.first(where: { $0.time.toHour == hour }) {
            return hourData.uv
        }
        
        // 못 찾으면 현재 UV 반환
        return response.current?.uv ?? 0.0
    }
    
    // MARK: - Private Methods
    
    private func mapToLocationWeather(response: WeatherAPIResponse, location: LocationInfo) -> LocationWeather {
        let hourlyForecasts: [HourlyForecast] = response.forecast?.forecastday.first?.hour.compactMap { hour in
            guard let hourInt = hour.time.toHour, let timestamp = hour.time.toDate else {
                return nil
            }
            
            return HourlyForecast(hour: hourInt, uvIndex: hour.uv, temperature: hour.tempC, timestamp: timestamp)
        } ?? []
        
        return LocationWeather(
            location: location,
            currentUVIndex: response.current?.uv ?? 0.0,
            currentTemperature: response.current?.tempC ?? 0.0,
            hourlyForecasts: hourlyForecasts
        )
    }
}
