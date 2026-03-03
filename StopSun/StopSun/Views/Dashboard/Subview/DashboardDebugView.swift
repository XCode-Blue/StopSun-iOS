//
//  DashboardDebugView.swift
//  StopSun
//
//  Created by J on 2/22/26.
//

#if DEBUG
import SwiftUI

/// 대시보드 디버그 시트
///
/// SyncCoordinator 내부 상태, localStorage 데이터,
/// HealthKit 처리 현황 등을 실시간 확인합니다.
///
struct DashboardDebugView: View {
    
    let syncCoordinator: SyncCoordinator
    
    @State private var exposureRecords: [UVExposureRecord] = []
    @State private var dailyRecord: DailyMEDRecord?
    @State private var sunscreenHistory: [SunscreenApplication] = []
    @State private var locationHistory: [LocationRecord] = []
    @State private var timeInDaylight: [TimeInDaylight] = []
    @State private var processedStatus: [(id: UUID, processed: Bool)] = []
    @Environment(\.dismiss) private var dismiss
    
    private var storage: any LocalStorageManagerProtocol {
        syncCoordinator.debugLocalStorage
    }
    
    var body: some View {
        NavigationStack {
            List {
                syncStateSection
                sedCalculationSection
                healthKitSection
                exposureRecordsSection
                sunscreenSection
                locationSection
                dailyRecordSection
            }
            .navigationTitle("🐛 Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("새로고침") { loadData() }
                }
            }
            .onAppear { loadData() }
        }
    }
    
    // MARK: - Sync State
    
    private var syncStateSection: some View {
        Section("🔄 Sync 상태") {
            row("isSyncing", syncCoordinator.isSyncing ? "✅" : "❌")
            row("lastSyncTime", syncCoordinator.lastSyncTime?.formatted(date: .abbreviated, time: .standard) ?? "nil")
            row("error", syncCoordinator.error?.localizedDescription ?? "nil")
            row("userProfile", syncCoordinator.userProfile?.skinType.title ?? "nil")
        }
    }
    
    // MARK: - SED Calculation
    
    private var sedCalculationSection: some View {
        Section("📊 SED/MED 계산") {
            row("todayTotalSED", format(syncCoordinator.todayTotalSED, 4))
            row("todaySEDProgress", format(syncCoordinator.todaySEDProgress, 4))
            row("remainingSED", format(syncCoordinator.remainingSED, 4))
            row("warningLevel", syncCoordinator.warningLevel.title)
            row("currentUVIndex", format(syncCoordinator.currentUVIndex, 1))
            row("minutesUntilMax", "\(Int(syncCoordinator.minutesUntilMaxSED()))분")
            
            if let weather = syncCoordinator.currentWeather {
                row("location", weather.location.cityName ?? "알 수 없음")
                row("temperature", "\(Int(weather.currentTemperature))°C")
            } else {
                row("currentWeather", "nil")
            }
        }
    }
    
    // MARK: - HealthKit
    
    private var healthKitSection: some View {
        Section("⌚ HealthKit TimeInDaylight (\(timeInDaylight.count)건)") {
            if timeInDaylight.isEmpty {
                Text("데이터 없음")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(timeInDaylight.enumerated()), id: \.element.id) { index, data in
                    let status = processedStatus.first { $0.id == data.id }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("#\(index + 1)")
                                .font(.caption2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Text(status?.processed == true ? "✅ 처리됨" : "🆕 미처리")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(status?.processed == true ? .green.opacity(0.2) : .orange.opacity(0.2))
                                )
                        }
                        
                        Text("\(timeStr(data.startTime)) ~ \(timeStr(data.endTime))")
                            .font(.caption)
                        
                        HStack {
                            Text("시간: \(format(data.durationMinutes, 1))분")
                            Text("ID: \(data.id.uuidString.prefix(8))…")
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
    
    // MARK: - Exposure Records
    
    private var exposureRecordsSection: some View {
        Section("☀️ 노출 기록 (\(exposureRecords.count)건)") {
            if exposureRecords.isEmpty {
                Text("저장된 기록 없음")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(exposureRecords) { record in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(timeStr(record.startTime)) ~ \(timeStr(record.endTime))")
                            .font(.caption)
                        
                        HStack {
                            label("UV", format(record.averageUV, 1))
                            label("SPF", record.appliedSPF.displayTitle)
                            label("SED", format(record.receivedSED, 4))
                            label("시간", "\(format(record.durationMinutes, 1))분")
                        }
                        .font(.caption2)
                        
                        if let hkID = record.healthKitID {
                            Text("HK: \(hkID.uuidString.prefix(8))…")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
    
    // MARK: - Sunscreen
    
    private var sunscreenSection: some View {
        Section("🧴 선크림") {
            if let active = syncCoordinator.activeSunscreen {
                row("활성", "\(active.spfLevel.displayTitle)")
                row("도포 시각", timeStr(active.appliedAt))
                row("재도포 시각", timeStr(active.nextReapplyTime))
                row("isActive", active.isActive(at: Date()) ? "✅" : "❌")
            } else {
                row("활성", "없음")
            }
            
            if !sunscreenHistory.isEmpty {
                ForEach(Array(sunscreenHistory.enumerated()), id: \.offset) { index, app in
                    Text("히스토리 #\(index + 1): \(app.spfLevel.displayTitle) @ \(timeStr(app.appliedAt))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Location
    
    private var locationSection: some View {
        Section("📍 위치 기록 (\(locationHistory.count)건)") {
            if locationHistory.isEmpty {
                Text("저장된 위치 없음")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(locationHistory.suffix(5).reversed().enumerated()), id: \.offset) { _, record in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.locationInfo.cityName ?? "알 수 없음")
                            .font(.caption)
                        Text("\(format(record.locationInfo.latitude, 4)), \(format(record.locationInfo.longitude, 4)) @ \(timeStr(record.timestamp))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Daily Record
    
    private var dailyRecordSection: some View {
        Section("📅 일일 기록") {
            if let daily = dailyRecord {
                row("totalSED", format(daily.totalSED, 4))
                row("recordCount", "\(daily.recordCount)")
                row("date", daily.date.formatted(date: .abbreviated, time: .omitted))
            } else {
                Text("일일 기록 없음")
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Load Data
    
    private func loadData() {
        exposureRecords = storage.loadExposureRecords(for: Date())
        dailyRecord = storage.loadDailyMEDRecord(for: Date())
        sunscreenHistory = storage.loadSunscreenHistory()
        locationHistory = storage.loadLocationHistory()
        
        Task {
            do {
                let data = try await syncCoordinator.debugHealthKit.fetchTodayTimeInDaylight()
                timeInDaylight = data
                processedStatus = data.map { (id: $0.id, processed: storage.isProcessed(healthKitID: $0.id)) }
            } catch {
                timeInDaylight = []
                processedStatus = []
            }
        }
    }
    
    // MARK: - Helpers
    
    private func row(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
    }
    
    private func label(_ key: String, _ value: String) -> some View {
        HStack(spacing: 2) {
            Text(key)
                .foregroundStyle(.secondary)
            Text(value)
                .fontWeight(.medium)
        }
    }
    
    private func format(_ value: Double, _ decimals: Int) -> String {
        String(format: "%.\(decimals)f", value)
    }
    
    private func timeStr(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .standard)
    }
}
#endif
