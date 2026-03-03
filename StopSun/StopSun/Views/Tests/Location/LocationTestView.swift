//
//  LocationTestView.swift
//  StopSun
//
//  Created by J on 2/24/26.
//

import SwiftUI

struct LocationTestView: View {
    
    @StateObject private var viewModel = LocationTestViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                authorizationSection
                currentLocationSection
                monitoringSection
                historySection
                errorSection
            }
            .navigationTitle("Location 테스트")
        }
    }
}

// MARK: - Sections

private extension LocationTestView {
    
    var authorizationSection: some View {
        Section("권한 상태") {
            row(title: "상태", value: viewModel.authorizationStatus, color: statusColor)
            
            if !viewModel.isAuthorized && !viewModel.isDenied {
                Button("권한 요청 (Always)") {
                    Task { await viewModel.requestAuthorization() }
                }
            }
            
            if viewModel.isDenied {
                Button("설정 앱으로 이동") {
                    viewModel.openSettings()
                }
                .foregroundStyle(.orange)
            }
        }
    }
    
    var currentLocationSection: some View {
        Section("현재 위치") {
            Button("현재 위치 조회") {
                Task { await viewModel.fetchCurrentLocation() }
            }
            .disabled(!viewModel.isAuthorized)
            
            if viewModel.isLoading {
                ProgressView()
            }
            
            if let location = viewModel.currentLocation {
                row(title: "도시", value: location.cityName ?? "알 수 없음")
                row(title: "위도", value: location.latitude.formatted(.number.precision(.fractionLength(4))))
                row(title: "경도", value: location.longitude.formatted(.number.precision(.fractionLength(4))))
            }
        }
    }
    
    var monitoringSection: some View {
        Section("Significant Location Changes") {
            Button(viewModel.isMonitoring ? "모니터링 중지" : "모니터링 시작") {
                viewModel.toggleMonitoring()
            }
            .disabled(!viewModel.isAuthorized)
            
            if viewModel.isMonitoring {
                Label("모니터링 중", systemImage: "location.fill")
                    .foregroundStyle(.green)
            }
        }
    }
    
    var historySection: some View {
        Section("위치 히스토리 (\(viewModel.locationHistory.count)건)") {
            Button("히스토리 로드") {
                viewModel.loadLocationHistory()
            }
            
            ForEach(viewModel.locationHistory) { record in
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("(\(record.latitude.formatted(.number.precision(.fractionLength(4)))), \(record.longitude.formatted(.number.precision(.fractionLength(4)))))")
                        .font(.caption2)
                        .monospaced()
                }
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

private extension LocationTestView {
    
    var statusColor: Color {
        if viewModel.isDenied { return .red }
        if viewModel.isAuthorized { return .green }
        return .secondary
    }
    
    func row(title: String, value: String, color: Color = .secondary) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(color)
        }
    }
}

#Preview {
    LocationTestView()
}
