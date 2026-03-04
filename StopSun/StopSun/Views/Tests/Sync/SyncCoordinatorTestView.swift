//
//  SyncCoordinatorTestView.swift
//  StopSun
//
//  Created by J on 2/9/26.
//

import SwiftUI

/// SyncCoordinator 테스트 화면
///
/// Mock 상태를 조작하며 UI 동작을 확인합니다.
///
/// ## 진입점 (개발용)
/// ```swift
/// #if DEBUG
/// Button("SyncCoordinator Test") {
///     // SyncCoordinatorTestView() 표시
/// }
/// #endif
/// ```
///
#if DEBUG
struct SyncCoordinatorTestView: View {
    
    @StateObject private var viewModel = SyncCoordinatorTestViewModel()
    
    private var coordinator: MockSyncCoordinator {
        viewModel.coordinator
    }
    
    var body: some View {
        NavigationStack {
            List {
                statusSection
                warningSection
                syncSection
                sunscreenSection
                settingsSection
                backgroundSimulationSection
                overlapTestSection
                mockSection
                logsSection
            }
            .navigationTitle("SyncCoordinator Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Sections

private extension SyncCoordinatorTestView {
    
    // MARK: 현재 상태
    
    var statusSection: some View {
        Section("📊 현재 상태") {
            row("SED", "\(format(coordinator.todayTotalSED)) (\(Int(coordinator.todaySEDProgress * 100))%)")
            row("남은 SED", format(coordinator.remainingSED))
            row("UV Index", format(coordinator.currentUVIndex, decimals: 1))
            row("경고 레벨", coordinator.warningLevel.title)
            row("최대까지", "\(Int(coordinator.minutesUntilMaxSED()))분")
            
            if let sunscreen = coordinator.activeSunscreen {
                row("선크림", sunscreen.spfLevel.displayTitle)
                row("재도포 시간", sunscreen.nextReapplyTime.formatted(date: .omitted, time: .shortened))
            } else {
                row("선크림", "없음")
            }
            
            row("동기화 중", coordinator.isSyncing ? "✅" : "❌")
            row("마지막 동기화", coordinator.lastSyncTime?.formatted(date: .omitted, time: .shortened) ?? "-")
            
            if let error = coordinator.error {
                row("에러", error.localizedDescription)
                    .foregroundStyle(.red)
            }
        }
    }
    
    // MARK: 경고 레벨
    
    var warningSection: some View {
        Section("⚠️ 경고 레벨") {
            HStack {
                VStack(alignment: .leading) {
                    Text(coordinator.warningLevel.title)
                        .font(.headline)
                    Text(coordinator.warningLevel.statusDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: 동기화
    
    var syncSection: some View {
        Section("🔄 동기화") {
            Button("Start Sync") { viewModel.startSync() }
                .disabled(coordinator.isSyncing)
            
            Button("Refresh") { viewModel.refresh() }
                .disabled(coordinator.isSyncing)
        }
    }
    
    // MARK: 선크림
    
    var sunscreenSection: some View {
        Section("🧴 선크림") {
            if coordinator.activeSunscreen == nil {
                Button("선크림 타이머 시작") { viewModel.applySunscreen() }
            } else {
                Button("선크림 타이머 종료") { viewModel.stopSunscreen() }
            }
        }
    }
    
    // MARK: 설정
    
    var settingsSection: some View {
        Section("⚙️ 설정") {
            Picker("피부 타입", selection: $viewModel.selectedSkinType) {
                ForEach(SkinType.allCases, id: \.self) { type in
                    Text(type.title).tag(type)
                }
            }
            .onChange(of: viewModel.selectedSkinType) { _, newValue in
                viewModel.updateSkinType(newValue)
            }
            
            Picker("선크림 SPF", selection: $viewModel.selectedSPF) {
                ForEach(SPFLevel.allCases, id: \.self) { spf in
                    Text(spf.displayTitle).tag(spf)
                }
            }
            .onChange(of: viewModel.selectedSPF) { _, newValue in
                viewModel.updateSPF(newValue)
            }
        }
    }
    
    // MARK: Background 시뮬레이션
    
    var backgroundSimulationSection: some View {
        Section("📡 Background 시뮬레이션") {
            Button("HealthKit 10분 노출") { viewModel.simulateHealthKitData(durationMinutes: 10) }
            Button("HealthKit 30분 노출") { viewModel.simulateHealthKitData(durationMinutes: 30) }
            Button("HealthKit 60분 노출") { viewModel.simulateHealthKitData(durationMinutes: 60) }
            
            Divider()
            
            Button("위치 변경: UV 3 (낮음)") { viewModel.simulateLocationChange(uvIndex: 3) }
            Button("위치 변경: UV 6 (보통)") { viewModel.simulateLocationChange(uvIndex: 6) }
            Button("위치 변경: UV 9 (높음)") { viewModel.simulateLocationChange(uvIndex: 9) }
        }
    }
    
    // MARK: 시간 분할 테스트
    
    var overlapTestSection: some View {
        Section("⏱️ 시간 분할 테스트") {
            Text("30분 노출 중 15분 후 선크림 도포 시뮬레이션")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Button("겹침 테스트 실행") { viewModel.simulateOverlappingExposure() }
        }
    }
    
    // MARK: Mock 전용
    
    var mockSection: some View {
        Section("🧪 Mock 전용") {
            HStack {
                Text("SED 증가량")
                Spacer()
                TextField("0.1", value: $viewModel.sedToAdd, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .keyboardType(.decimalPad)
            }
            
            Button("SED 증가") { viewModel.increaseSED() }
            Button("에러 시뮬레이션") { viewModel.simulateError() }
            Button("에러 클리어") { viewModel.clearError() }
        }
    }
    
    // MARK: 로그
    
    var logsSection: some View {
        Section("📝 로그") {
            Button("로그 클리어") { viewModel.clearLogs() }
            
            ForEach(viewModel.logs) { log in
                VStack(alignment: .leading, spacing: 2) {
                    Text(log.formattedTime)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(log.message)
                        .font(.caption)
                }
            }
        }
    }
}

// MARK: - Helpers

private extension SyncCoordinatorTestView {
    
    func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
    
    func format(_ value: Double, decimals: Int = 2) -> String {
        String(format: "%.\(decimals)f", value)
    }
}

// MARK: - Preview

#Preview {
    SyncCoordinatorTestView()
}
#endif
