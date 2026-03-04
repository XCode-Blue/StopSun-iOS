//
//  WeatherTestViewModel.swift
//  StopSun
//
//  Created by J on 1/30/26.
//

import Foundation

#if DEBUG
@MainActor
final class WeatherTestViewModel: ObservableObject {
    
    // MARK: - Published
    
    @Published private(set) var currentUVIndex: Double?
    @Published private(set) var currentWeather: LocationWeather?
    @Published private(set) var historicalUVIndex: Double?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading = false
    
    @Published var historyDate: Date
    
    // MARK: - Dependencies
    
    private let weatherManager: any WeatherManagerProtocol
    private let locationManager: any LocationManagerProtocol
    
    // MARK: - Init
    
    init() {
        self.weatherManager = DIContainer.shared.weather
        self.locationManager = DIContainer.preview.location
        self.historyDate = Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
    }

    // MARK: - Methods
     
    func fetchCurrentUVIndex() async {
        await performTask {
            let location = try await self.locationManager.getCurrentLocation()
            self.currentUVIndex = try await self.weatherManager.fetchCurrentUVIndex(for: location)
        }
    }
    
    func fetchCurrentWeather() async {
        await performTask {
            let location = try await self.locationManager.getCurrentLocation()
            self.currentWeather = try await self.weatherManager.fetchCurrentWeather(for: location)
        }
    }
    
    func fetchHistoricalUV() async {
        await performTask {
            let location = try await self.locationManager.getCurrentLocation()
            self.historicalUVIndex = try await self.weatherManager.fetchUVIndex(for: location, at: self.historyDate)
        }
    }
    
    // MARK: - Private
    
    private func performTask(_ task: () async throws -> Void) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await task()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
#endif
