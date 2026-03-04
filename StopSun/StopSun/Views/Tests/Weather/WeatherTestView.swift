//
//  WeatherTestView.swift
//  StopSun
//
//  Created by J on 1/30/26.
//

import SwiftUI

#if DEBUG
struct WeatherTestView: View {
    
    @StateObject private var viewModel = WeatherTestViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                currentUVSection
                currentWeatherSection
                hourlyForecastSection
                historySection
                errorSection
            }
            .navigationTitle("Weather 테스트")
        }
    }
}

// MARK: - Sections

private extension WeatherTestView {
    
    var currentUVSection: some View {
        Section("현재 UV Index") {
            Button("현재 UV 조회") {
                Task { await viewModel.fetchCurrentUVIndex() }
            }
            
            if let uv = viewModel.currentUVIndex {
                row(title: "현재 UV 지수", value: uv.formatted(.number.precision(.fractionLength(1))), color: uvColor(uv))
            }
        }
    }
    
    @ViewBuilder
    var currentWeatherSection: some View {
        Section("현재 날씨 + 예보") {
            Button("현재 날씨 조회") {
                Task { await viewModel.fetchCurrentWeather() }
            }
            
            if viewModel.isLoading {
                ProgressView()
            }
            
            if let weather = viewModel.currentWeather {
                row(title: "위치", value: weather.location.cityName ?? "알 수 없음")
                row(title: "현재 UV 지수", value: weather.currentUVIndex.formatted(.number.precision(.fractionLength(1))), color: uvColor(weather.currentUVIndex))
                row(title: "현재 온도", value: "\(weather.currentTemperature.formatted(.number.precision(.fractionLength(1))))°C")
            }
        }
    }
    
    @ViewBuilder
    var hourlyForecastSection: some View {
        if let weather = viewModel.currentWeather, !weather.hourlyForecasts.isEmpty {
            Section("시간별 UV 지수 (\(weather.hourlyForecasts.count)건)") {
                ForEach(weather.hourlyForecasts) { forecast in
                    HStack {
                        Text("\(forecast.hour)시")
                            .frame(width: 50, alignment: .leading)
                        Spacer()
                        Text("UV \(forecast.uvIndex.formatted(.number.precision(.fractionLength(1))))")
                            .foregroundStyle(uvColor(forecast.uvIndex))
                        Text("\(forecast.temperature.formatted(.number.precision(.fractionLength(0))))°C")
                            .foregroundStyle(.secondary)
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            }
        }
    }
    
    var historySection: some View {
        Section("과거 UV 조회") {
            DatePicker("날짜", selection: $viewModel.historyDate, displayedComponents: [.date, .hourAndMinute])
            
            Button("과거 UV 조회") {
                Task { await viewModel.fetchHistoricalUV() }
            }
            
            if let uv = viewModel.historicalUVIndex {
                row(title: "해당 시점 UV 지수", value: uv.formatted(.number.precision(.fractionLength(1))), color: uvColor(uv))
            }
        }
    }
    
    @ViewBuilder
    var errorSection: some View {
        if let errorMessage = viewModel.errorMessage {
            Section("에러") {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
    }
}

// MARK: - Components

private extension WeatherTestView {
    
    func row(title: String, value: String, color: Color = .secondary) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(color)
                .bold(color != .secondary)
        }
    }
    
    func uvColor(_ uv: Double) -> Color {
        switch uv {
        case ..<3: .green
        case 3..<6: .yellow
        case 6..<8: .orange
        case 8..<11: .red
        default: .purple
        }
    }
}

#Preview {
    WeatherTestView()
}
#endif
