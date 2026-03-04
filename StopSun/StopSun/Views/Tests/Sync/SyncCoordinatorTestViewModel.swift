//
//  SyncCoordinatorTestViewModel.swift
//  StopSun
//
//  Created by J on 2/9/26.
//

import Foundation

/// SyncCoordinator 테스트용 ViewModel
#if DEBUG
@MainActor
final class SyncCoordinatorTestViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var selectedSkinType: SkinType = .type2
    @Published var selectedSPF: SPFLevel = .spf30
    @Published var sedToAdd: Double = 0.1
    @Published var logs: [LogEntry] = []
    
    // MARK: - Coordinator
    
    let coordinator: MockSyncCoordinator
    
    // MARK: - Initializer
    
    init() {
        self.coordinator = MockSyncCoordinator(todayTotalSED: 0)
        
        if let profile = coordinator.userProfile {
            selectedSkinType = profile.skinType
            selectedSPF = profile.spfLevel
        }
        
        coordinator.simulateLocationChange(uvIndex: 5.0)
        addLog("초기화 완료 (SED 0, UV 5.0, Type II)")
    }
    
    // MARK: - Sync Actions
    
    func startSync() {
        addLog("🚀 startSync()")
        Task {
            await coordinator.startSync()
            addLog("✅ startSync 완료")
        }
    }
    
    func refresh() {
        addLog("🔄 refresh()")
        Task {
            await coordinator.refresh()
            addLog("✅ refresh 완료")
        }
    }
    
    // MARK: - Sunscreen Actions
    
    func applySunscreen() {
        addLog("🧴 선크림 타이머 시작 (SPF \(selectedSPF.displayTitle))")
        coordinator.applySunscreen(spf: selectedSPF)
    }
    
    func stopSunscreen() {
        addLog("🛑 선크림 타이머 종료")
        coordinator.stopSunscreen()
    }
    
    // MARK: - Settings Actions
    
    func updateSkinType(_ skinType: SkinType) {
        addLog("👤 피부 타입 → \(skinType.title)")
        coordinator.updateSkinType(skinType)
    }
    
    func updateSPF(_ spf: SPFLevel) {
        addLog("🔢 선크림 SPF → \(spf.displayTitle)")
        coordinator.updateSunScreenSPF(spf)
    }
    
    // MARK: - Mock Actions
    
    func increaseSED() {
        addLog("📈 SED +\(format(sedToAdd))")
        coordinator.simulateSEDIncrease(by: sedToAdd)
    }
    
    func simulateError() {
        addLog("💥 에러 시뮬레이션")
        coordinator.setError(.healthKit(.authorizationDenied))
    }
    
    func clearError() {
        addLog("🧹 에러 클리어")
        coordinator.setError(nil)
    }
    
    // MARK: - Background 시뮬레이션
    
    func simulateHealthKitData(durationMinutes: Double) {
        let uv = coordinator.currentUVIndex
        let spf = coordinator.activeSunscreen?.spfLevel.displayTitle ?? "없음"
        let beforeSED = coordinator.todayTotalSED
        let beforeLevel = coordinator.warningLevel
        
        addLog("📡 HealthKit: \(Int(durationMinutes))분, UV \(format(uv)), SPF \(spf)")
        
        coordinator.simulateHealthKitDataArrival(durationMinutes: durationMinutes)
        
        let afterSED = coordinator.todayTotalSED
        let afterLevel = coordinator.warningLevel
        let sedDiff = afterSED - beforeSED
        
        addLog("   → SED: \(format(beforeSED)) → \(format(afterSED)) (+\(format(sedDiff, decimals: 4)))")
        
        if beforeLevel != afterLevel {
            addLog("   ⚠️ 경고 레벨: \(beforeLevel.title) → \(afterLevel.title)")
        }
    }
    
    func simulateLocationChange(uvIndex: Double) {
        addLog("📍 위치 변경: UV \(format(uvIndex))")
        coordinator.simulateLocationChange(uvIndex: uvIndex)
    }
    
    // MARK: - 시간 분할 시뮬레이션
    
    /// 선크림 도포 전후 겹침 테스트
    ///
    /// 시나리오: 30분 전 야외 활동 시작, 15분 전 선크림 도포, 지금 끝남
    /// 결과: 15분은 SPF 없음, 15분은 SPF 적용
    ///
    func simulateOverlappingExposure() {
        let now = Date()
        let exposureStart = now.addingTimeInterval(-30 * 60)
        let sunscreenTime = now.addingTimeInterval(-15 * 60)
        let exposureEnd = now
        
        coordinator.clearSunscreenHistory()
        coordinator.applySunscreen(spf: selectedSPF, at: sunscreenTime)
        
        addLog("🧪 시간 분할 테스트")
        addLog("   노출: \(formatTime(exposureStart)) ~ \(formatTime(exposureEnd)) (30분)")
        addLog("   선크림: \(formatTime(sunscreenTime)) (SPF \(selectedSPF.displayTitle))")
        
        let beforeSED = coordinator.todayTotalSED
        
        let result = coordinator.simulateHealthKitDataArrival(
            from: exposureStart,
            to: exposureEnd
        )
        
        addLog("   분할 결과:")
        for segment in result.segments {
            let spfText = segment.spfLevel?.displayTitle ?? "없음"
            addLog("   • \(formatTime(segment.startDate))~\(formatTime(segment.endDate)): SPF \(spfText) (\(format(segment.durationMinutes))분)")
        }
        
        let afterSED = coordinator.todayTotalSED
        addLog("   → SED: \(format(beforeSED)) → \(format(afterSED)) (+\(format(result.totalSED, decimals: 4)))")
    }
    
    // MARK: - Logging
    
    func clearLogs() {
        logs.removeAll()
        addLog("로그 클리어")
    }
    
    private func addLog(_ message: String) {
        let entry = LogEntry(message: message)
        logs.insert(entry, at: 0)
        
        if logs.count > 50 {
            logs.removeLast()
        }
    }
    
    // MARK: - Helpers
    
    private func format(_ value: Double, decimals: Int = 2) -> String {
        String(format: "%.\(decimals)f", value)
    }
    
    private func formatTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }
}

// MARK: - LogEntry

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String
    
    init(message: String) {
        self.timestamp = Date()
        self.message = message
    }
    
    var formattedTime: String {
        timestamp.formatted(date: .omitted, time: .standard)
    }
}
#endif
