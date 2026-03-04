//
//  MockSyncCoordinator.swift
//  StopSun
//
//  Created by J on 2/9/26.
//

import Foundation

/// SyncCoordinator Mock
///
/// UI 테스트 및 Preview에서 사용하는 Mock입니다.
/// 실제 SyncCoordinator의 동작을 시뮬레이션할 수 있습니다.
///
/// ## 사용법
/// ```swift
/// // 기본 생성
/// let mock = MockSyncCoordinator()
///
/// // 초기값 지정
/// let mock = MockSyncCoordinator(todayTotalSED: 1.5)
///
/// // Preview용
/// let mock = MockSyncCoordinator.warning
/// ```
///
#if DEBUG
@MainActor
@Observable
final class MockSyncCoordinator: SyncCoordinatorProtocol {
    
    // MARK: - State
    
    private(set) var userProfile: UserProfile?
    private(set) var todayTotalSED: Double = 0
    private(set) var currentWeather: LocationWeather?
    private(set) var activeSunscreen: SunscreenApplication?
    
    private(set) var isSyncing: Bool = false
    private(set) var lastSyncTime: Date?
    private(set) var error: AppError?
    
    // MARK: - 선크림 히스토리 (시간 분할 계산용)
    
    private(set) var sunscreenHistory: [SunscreenApplication] = []
    
    // MARK: - Initializer
    
    init(
        userProfile: UserProfile? = .mockUser,
        todayTotalSED: Double = 0.5,
        currentWeather: LocationWeather? = nil,
        activeSunscreen: SunscreenApplication? = nil
    ) {
        self.userProfile = userProfile
        self.todayTotalSED = todayTotalSED
        self.currentWeather = currentWeather
        self.activeSunscreen = activeSunscreen
    }
    
    // MARK: - SED Computed Properties
    
    var todaySEDProgress: Double {
        guard let skinType = userProfile?.skinType else { return 0 }
        return SEDCalculator.progress(currentSED: todayTotalSED, skinType: skinType)
    }
    
    var remainingSED: Double {
        guard let skinType = userProfile?.skinType else { return 0 }
        return SEDCalculator.remainingSED(currentSED: todayTotalSED, skinType: skinType)
    }
    
    var currentUVIndex: Double {
        currentWeather?.currentUVIndex ?? 0
    }
    
    var warningLevel: WarningLevel {
        WarningLevel.from(progress: todaySEDProgress)
    }
    
    func minutesUntilMaxSED() -> Double {
        guard let skinType = userProfile?.skinType else { return 0 }
        return SEDCalculator.minutesUntilMax(
            currentSED: todayTotalSED,
            skinType: skinType,
            uvIndex: currentUVIndex,
            spf: activeSunscreen?.spfLevel.protectionFactor
        )
    }
    
    // MARK: - Sync Methods
    
    func startSync() async {
        isSyncing = true
        try? await Task.sleep(nanoseconds: 300_000_000)
        isSyncing = false
        lastSyncTime = Date()
    }
    
    func refresh() async {
        isSyncing = true
        try? await Task.sleep(nanoseconds: 100_000_000)
        isSyncing = false
        lastSyncTime = Date()
    }
    
    // MARK: - User Actions
    
    func applySunscreen(spf: SPFLevel) {
        applySunscreen(spf: spf, at: Date())
    }
    
    func stopSunscreen() {
        activeSunscreen = nil
    }
    
    func updateSkinType(_ skinType: SkinType) {
        userProfile?.skinType = skinType
    }
    
    func updateSunScreenSPF(_ spfLevel: SPFLevel) {
        userProfile?.spfLevel = spfLevel
    }
    
    // MARK: - App Lifecycle
    
    func handleAppDidBecomeActive() {
        Task { await refresh() }
    }
    
    func handleAppWillResignActive() {}
}

// MARK: - Mock Simulation Methods

extension MockSyncCoordinator {
    
    /// 특정 시간에 선크림 도포 시뮬레이션
    func applySunscreen(spf: SPFLevel, at date: Date) {
        let sunscreen = SunscreenApplication(
            spfLevel: spf,
            appliedAt: date,
            reapplyIntervalMinutes: spf.recommendedReapplicationMinutes
        )
        activeSunscreen = sunscreen
        sunscreenHistory.append(sunscreen)
    }
    
    /// 날씨/위치 변경 시뮬레이션
    func simulateLocationChange(uvIndex: Double, temperature: Double = 25.0) {
        let location = LocationInfo(latitude: 36.0190, longitude: 129.3435, cityName: "포항")
        currentWeather = LocationWeather(
            location: location,
            currentUVIndex: uvIndex,
            currentTemperature: temperature
        )
    }
    
    /// HealthKit 데이터 도착 시뮬레이션 (단순 버전)
    ///
    /// 현재 활성 선크림 기준으로 계산합니다.
    ///
    func simulateHealthKitDataArrival(durationMinutes: Double, uvIndex: Double? = nil) {
        let uv = uvIndex ?? currentUVIndex
        let sed = SEDCalculator.calculate(
            uvIndex: uv,
            durationMinutes: durationMinutes,
            spf: activeSunscreen?.spfLevel.protectionFactor
        )
        todayTotalSED += sed
    }
    
    /// HealthKit 데이터 도착 시뮬레이션 (시간 분할 버전)
    ///
    /// 선크림 타이머와 노출 시간이 겹치는 경우를 정확하게 계산합니다.
    ///
    /// ## 시나리오
    /// ```
    /// 선크림: 10:00 ~ 12:00 (SPF 30)
    /// TimeInDaylight: 09:30 ~ 10:30
    ///
    /// 결과:
    /// - 09:30 ~ 10:00: SPF 없음 → SED 계산
    /// - 10:00 ~ 10:30: SPF 30 → SED ÷ 30
    /// ```
    ///
    @discardableResult
    func simulateHealthKitDataArrival(
        from startDate: Date,
        to endDate: Date,
        uvIndex: Double? = nil
    ) -> (totalSED: Double, segments: [ExposureSegment]) {
        let uv = uvIndex ?? currentUVIndex
        
        let segments = SEDCalculator.splitExposure(
            start: startDate,
            end: endDate,
            sunscreenHistory: sunscreenHistory
        )
        
        let sed = SEDCalculator.calculateWithSunscreenHistory(
            start: startDate,
            end: endDate,
            uvIndex: uv,
            sunscreenHistory: sunscreenHistory
        )
        
        todayTotalSED += sed
        return (sed, segments)
    }
    
    /// SED 직접 설정
    func setTodayTotalSED(_ sed: Double) {
        todayTotalSED = sed
    }
    
    /// SED 증가
    func simulateSEDIncrease(by amount: Double) {
        todayTotalSED += amount
    }
    
    /// 에러 설정
    func setError(_ error: AppError?) {
        self.error = error
    }
    
    /// 날씨 설정
    func setCurrentWeather(_ weather: LocationWeather?) {
        currentWeather = weather
    }
    
    /// 선크림 히스토리 초기화
    func clearSunscreenHistory() {
        sunscreenHistory.removeAll()
        activeSunscreen = nil
    }
}

// MARK: - Preview Helpers

extension MockSyncCoordinator {
    
    /// Safe 상태 (진행률 < 50%)
    static var safe: MockSyncCoordinator {
        let mock = MockSyncCoordinator(todayTotalSED: 0.3)
        mock.simulateLocationChange(uvIndex: 5.0)
        return mock
    }
    
    /// Caution 상태 (진행률 50~75%)
    static var caution: MockSyncCoordinator {
        let mock = MockSyncCoordinator(todayTotalSED: 1.8)
        mock.simulateLocationChange(uvIndex: 5.0)
        return mock
    }
    
    /// Warning 상태 (진행률 75~100%)
    static var warning: MockSyncCoordinator {
        let mock = MockSyncCoordinator(todayTotalSED: 2.5)
        mock.simulateLocationChange(uvIndex: 5.0)
        return mock
    }
    
    /// Danger 상태 (진행률 > 100%)
    static var danger: MockSyncCoordinator {
        let mock = MockSyncCoordinator(todayTotalSED: 3.5)
        mock.simulateLocationChange(uvIndex: 5.0)
        return mock
    }
    
    /// 선크림 도포 상태
    static var withSunscreen: MockSyncCoordinator {
        let mock = MockSyncCoordinator(todayTotalSED: 0.3)
        mock.simulateLocationChange(uvIndex: 5.0)
        mock.applySunscreen(spf: .spf50)
        return mock
    }
}
#endif
