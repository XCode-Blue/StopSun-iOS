//
//  SyncCoordinator.swift
//  StopSun
//
//  Created by J on 1/27/26.
//

import Foundation

/// 데이터 동기화 조율자
///
/// HealthKit, Weather, Storage 간의 데이터 흐름을 조율합니다.
///
/// ## 핵심 역할
/// - 앱 시작 시 초기 데이터 로드 (권한 요청은 온보딩/PermissionManager 담당)
/// - HealthKit Background Delivery 수신 및 SED 계산
/// - 위치 변경 감지 및 날씨 조회
/// - 선크림 도포 관리 및 알림 예약
/// - 경고 레벨 모니터링
///
@MainActor
@Observable
final class SyncCoordinator: SyncCoordinatorProtocol {
    
    // MARK: - Observable Properties
    
    private(set) var userProfile: UserProfile?
    private(set) var todayTotalSED: Double = 0
    private(set) var currentWeather: LocationWeather?
    private(set) var activeSunscreen: SunscreenApplication?
    
    // MARK: - Sync State Properties
    
    private(set) var isSyncing: Bool = false
    private(set) var lastSyncTime: Date?
    private(set) var error: AppError?
    
    // MARK: - Private State
    
    /// 마지막 알림 전송된 경고 레벨 (중복 알림 방지)
    private var lastNotifiedWarningLevel: WarningLevel = .safe
    
    /// 날씨 캐시 TTL (초)
    private static let weatherCacheTTL: TimeInterval = 900  // 15분
    
    // MARK: - Observer Tasks
    @ObservationIgnored
    nonisolated(unsafe) private var observerTasks: [Task<Void, Never>] = []
    
    // MARK: - Dependencies
    
    private let healthKit: any HealthKitManagerProtocol
    private let weather: any WeatherManagerProtocol
    private let location: any LocationManagerProtocol
    private let localStorage: any LocalStorageManagerProtocol
    private let notification: any NotificationManagerProtocol
    private let watchConnectivity: any WatchConnectivityManagerProtocol
    private let liveActivity: any LiveActivityManagerProtocol
    
    // MARK: - Initializer
    
    init(
        healthKit: any HealthKitManagerProtocol,
        weather: any WeatherManagerProtocol,
        location: any LocationManagerProtocol,
        localStorage: any LocalStorageManagerProtocol,
        notification: any NotificationManagerProtocol,
        watchConnectivity: any WatchConnectivityManagerProtocol,
        liveActivity: any LiveActivityManagerProtocol
    ) {
        self.healthKit = healthKit
        self.weather = weather
        self.location = location
        self.localStorage = localStorage
        self.notification = notification
        self.watchConnectivity = watchConnectivity
        self.liveActivity = liveActivity
        
        setupObservers()
        Log.info("SyncCoordinator 초기화 완료")
    }
    
    deinit {
        observerTasks.forEach { $0.cancel() }
        Log.info("SyncCoordinator deinit - 모든 observer 취소됨")
    }
    
    // MARK: - Computed Properties
    
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
        let spf: Double? = activeSunscreen?.spfLevel.protectionFactor
        return SEDCalculator.minutesUntilMax(
            currentSED: todayTotalSED,
            skinType: skinType,
            uvIndex: currentUVIndex,
            spf: spf
        )
    }
    
    // MARK: - Setup Observers
    
    private func setupObservers() {
        let locationTask = Task { [weak self] in
            let notifications = NotificationCenter.default.notifications(named: .locationDidChange)
            for await notification in notifications {
                guard let self else { return }
                await self.handleLocationDidChange(notification)
            }
        }
        observerTasks.append(locationTask)
        
        let healthKitTask = Task { [weak self] in
            let notifications = NotificationCenter.default.notifications(named: .healthKitDataDidUpdate)
            for await _ in notifications {
                guard let self else { return }
                await self.handleHealthKitDataUpdate()
            }
        }
        observerTasks.append(healthKitTask)
        
        let midnightTask = Task { [weak self] in
            let notifications = NotificationCenter.default.notifications(named: .NSCalendarDayChanged)
            for await _ in notifications {
                guard let self else { return }
                await self.handleDayChanged()
            }
        }
        observerTasks.append(midnightTask)
        
        let pushApplyTask = Task { [weak self] in
            let notifications = NotificationCenter.default.notifications(named: .didTapApplySunscreenNotification)
            for await _ in notifications {
                guard let self else { return }
                await self.handlePushNotificationApply()
            }
        }
        observerTasks.append(pushApplyTask)
        
        Log.debug("Observer 설정 완료: \(observerTasks.count)개")
        
        setupWatchConnectivity()
    }
    
    // MARK: - Sync
    
    func startSync() async {
        guard !isSyncing else {
            Log.debug("이미 동기화 중")
            return
        }
        
        isSyncing = true
        error = nil
        
        defer {
            isSyncing = false
            lastSyncTime = Date()
        }
        
        Log.info("동기화 시작")
        
        // 0. Watch Connectivity 세션 활성화 (Watch 보유 시에만)
        if userProfile?.hasWatch != false {
            watchConnectivity.activate()
        }
        
        // 1. 프로필 로드
        loadUserProfile()

        // 1. Watch Connectivity 세션 활성화 (Watch 보유 시에만)
        if userProfile?.hasWatch != false {
            watchConnectivity.activate()
        }
        
        // 2. 저장된 선크림 상태 로드
        loadActiveSunscreen()
        
        // 3. HealthKit Background Delivery 설정 (Watch 미보유 시에도 수동 입력 감지 필요)
        if healthKit.isAuthorized {
            do {
                try await healthKit.enableBackgroundDelivery()
                Log.info("HealthKit Background Delivery 설정 완료")
            } catch {
                Log.error("HealthKit Background Delivery 실패: \(error.localizedDescription)")
            }
        } else {
            Log.warning("HealthKit 권한 없음 — Background Delivery 스킵")
        }
        
        // 4. 현재 위치 및 날씨 조회
        await location.requestAuthorization()
        
        if location.isAuthorized {
            location.startMonitoringSignificantLocationChanges()
            await fetchCurrentLocationAndWeather()
        } else {
            Log.warning("위치 권한 없음 — 위치/날씨 조회 스킵")
        }
        
        // 5. 알림 상태 확인
        if !notification.isAuthorized {
            Log.warning("알림 권한 없음 — 알림 기능 제한")
        }
        
        // 6. 최근 SED 계산 (과거 지연 도착 데이터 포함)
        await calculateRecentSED()
        
        // 7. 선크림 만료 체크 및 알림 재예약
        checkSunscreenAndScheduleReminder()
        
        // 7-1. Live Activity 복원
        if let sunscreen = activeSunscreen,
           sunscreen.nextReapplyTime > .now,
           !liveActivity.isActivityActive {
            liveActivity.startActivity(
                appliedAt: sunscreen.appliedAt,
                reapplyAt: sunscreen.nextReapplyTime,
                spfDisplayTitle: sunscreen.spfLevel.displayTitle,
                warningLevel: warningLevel,
                progress: todaySEDProgress
            )
        }
        // 8. 경고 레벨 체크
        checkWarningLevelAndNotify()
        
        Log.info("동기화 완료")
        NotificationCenter.default.post(name: .syncDidComplete, object: nil)
    }
    
    func refresh() async {
        guard !isSyncing else { return }
        
        isSyncing = true
        error = nil
        
        defer {
            isSyncing = false
            lastSyncTime = Date()
        }
        
        // 날짜 변경 체크 (자정 넘긴 후 앱 재진입)
        if let lastSync = lastSyncTime,
           !Calendar.current.isDateInToday(lastSync) {
            resetForNewDay()
        }
        
        Log.info("새로고침 시작")
        
        await fetchCurrentLocationAndWeather()
        await calculateRecentSED()
        loadActiveSunscreen()
        checkWarningLevelAndNotify()
        if userProfile?.hasWatch != false {
            sendDashboardToWatch()
        }

        Log.info("새로고침 완료")
    }
    
    // MARK: - User Actions
    
    func applySunscreen(spf: SPFLevel) {
        let application = SunscreenApplication(
            spfLevel: spf,
            appliedAt: Date(),
            reapplyIntervalMinutes: spf.recommendedReapplicationMinutes
        )
        
        localStorage.saveSunscreenApplication(application)
        localStorage.clearManualSunscreenStopTime()
        activeSunscreen = application
        
        let reapplyTime = application.nextReapplyTime
        Task {
            do {
                try await notification.scheduleReapplyReminder(at: reapplyTime)
            } catch {
                Log.error("재도포 알림 예약 실패: \(error.localizedDescription)")
                self.error = .notification(.scheduleFailed)
            }
        }
        
        if userProfile?.hasWatch != false {
            watchConnectivity.sendSunscreenApplication(application)
            sendDashboardToWatch()
        }
        
        liveActivity.startActivity(
            appliedAt: application.appliedAt,
            reapplyAt: reapplyTime,
            spfDisplayTitle: spf.displayTitle,
            warningLevel: warningLevel,
            progress: todaySEDProgress
        )
        
        Log.info("선크림 도포: SPF \(spf.rawValue), 재도포 알림: \(reapplyTime.formatted(date: .omitted, time: .shortened))")
    }
    
    func stopSunscreen() {
        activeSunscreen = nil
        localStorage.saveManualSunscreenStopTime(Date())
        notification.cancelReapplyReminder()
        liveActivity.endActivity()
        Log.info("선크림 타이머 종료")
    }
    
    func updateSkinType(_ skinType: SkinType) {
        localStorage.updateSkinType(skinType)
        userProfile?.skinType = skinType
        
        checkWarningLevelAndNotify()
        
        if let profile = userProfile {
            watchConnectivity.sendUserProfile(profile)
        }
        
        Log.info("피부 타입 변경: \(skinType.title)")
    }
    
    func updateSunScreenSPF(_ spfLevel: SPFLevel) {
        localStorage.updateSunscreenSPF(spfLevel)
        userProfile?.spfLevel = spfLevel
        
        if let profile = userProfile {
            watchConnectivity.sendUserProfile(profile)
        }
        
        Log.info("선호 SPF 변경: \(spfLevel.displayTitle)")
    }
    
    func checkAndUpdateWatchConnection() async {
        await watchConnectivity.activateAndWait()
        
        let isPaired = watchConnectivity.isPaired
        localStorage.updateHasWatch(isPaired)
        userProfile?.hasWatch = isPaired
        
        Log.info("Watch 연동 확인 — \(isPaired ? "연결됨" : "미연결")")
    }
    
    // MARK: - App Lifecycle
    
    func handleAppDidBecomeActive() {
        Log.debug("앱 Active")
        Task { await refresh() }
    }
    
    func handleAppWillResignActive() {
        Log.debug("앱 Background 전환")
        if let profile = userProfile {
            localStorage.saveUserProfile(profile)
        }
    }
}

// MARK: - SED Calculation

private extension SyncCoordinator {
    
    /// 최근 N일간 SED 계산 (지연 도착 데이터 보정)
    ///
    /// Apple Watch의 timeInDaylight 데이터는 지연 전송될 수 있으므로,
    /// 오늘뿐 아니라 최근 며칠치를 같이 계산하여 누락을 방지합니다.
    /// 첫 sync 시에는 주간 차트를 채우기 위해 7일치를 조회합니다.
    func calculateRecentSED() async {
        let calendar = Calendar.current
        let today = Date()
        
        // 첫 sync → 7일 (차트용), 이후 → 3일
        let lookbackDays = lastSyncTime == nil ? 6 : 2
        
        let sunscreenHistory = localStorage.loadSunscreenHistory()
        let locationHistory = localStorage.loadLocationHistory()
        
        var uvCache: [String: Double] = [:]
        
        // 과거 → 오늘 순서로 처리 (오늘이 마지막이어야 todayTotalSED 최종 반영)
        for dayOffset in (0...lookbackDays).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            uvCache = await calculateSED(
                for: date,
                sunscreenHistory: sunscreenHistory,
                locationHistory: locationHistory,
                uvCache: uvCache
            )
        }
    }
    
    /// 특정 날짜의 SED 계산
    ///
    /// HealthKit에서 해당 날짜의 TimeInDaylight 데이터를 조회하고,
    /// 미처리 레코드만 선별하여 SED를 계산합니다.
    func calculateSED(
        for date: Date,
        sunscreenHistory: [SunscreenApplication],
        locationHistory: [LocationRecord],
        uvCache: [String: Double]
    ) async -> [String: Double] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.isDateInToday(date)
        ? Date()
        : calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        var cache = uvCache
        
        do {
            let timeInDaylightData = try await healthKit.fetchTimeInDaylight(from: startOfDay, to: endOfDay)
            let existingRecords = localStorage.loadExposureRecords(for: date)
            var runningTotal = existingRecords.reduce(0) { $0 + $1.receivedSED }
            
            let processedIDs = Set(existingRecords.compactMap(\.healthKitID))
            
            var newCount = 0
            var totalMinutes = 0
            
            for data in timeInDaylightData {
                totalMinutes += Int(data.endTime.timeIntervalSince(data.startTime) / 60)
                
                if processedIDs.contains(data.id) {
                    continue
                }
                
                let locationRecord = locationHistory.last { record in
                    abs(record.timestamp.timeIntervalSince(data.startTime)) < 600
                }
                
                let locationInfo = locationRecord?.locationInfo
                ?? currentWeather?.location
                ?? .mockSeoul
                
                let cacheKey = "\(String(format: "%.2f", locationInfo.latitude)),\(String(format: "%.2f", locationInfo.longitude))-\(date.toAPIDateString)-\(calendar.component(.hour, from: data.startTime))"
                
                let uvIndex: Double
                if let cached = cache[cacheKey] {
                    uvIndex = cached
                } else {
                    do {
                        uvIndex = try await weather.fetchUVIndex(for: locationInfo, at: data.startTime)
                    } catch {
                        Log.error("과거 UV 조회 실패: \(error.localizedDescription)")
                        uvIndex = currentUVIndex
                    }
                    cache[cacheKey] = uvIndex
                }
                
                let sed = SEDCalculator.calculateWithSunscreenHistory(
                    start: data.startTime,
                    end: data.endTime,
                    uvIndex: uvIndex,
                    sunscreenHistory: sunscreenHistory
                )
                
                let spf = sunscreenHistory.first { $0.isActive(at: data.startTime) }?.spfLevel ?? .none
                
                let record = UVExposureRecord(
                    healthKitID: data.id,
                    startTime: data.startTime,
                    endTime: data.endTime,
                    averageUV: uvIndex,
                    appliedSPF: spf,
                    receivedSED: sed
                )
                
                localStorage.saveExposureRecord(record)
                
                runningTotal += sed
                newCount += 1
            }
            
            if calendar.isDateInToday(date) {
                todayTotalSED = runningTotal
            }
            
            var dailyRecord = localStorage.loadDailyMEDRecord(for: date) ?? DailyMEDRecord(date: date)
            dailyRecord.totalSED = runningTotal
            dailyRecord.recordCount = existingRecords.count + newCount
            dailyRecord.totalExposureMinutes = totalMinutes
            localStorage.saveDailyMEDRecord(dailyRecord)
            
            if newCount > 0 {
                Log.info("\(date.toDateString) SED 계산: \(String(format: "%.2f", runningTotal)), 새로 처리 \(newCount)건")
            }
        } catch {
            Log.error("\(date.toDateString) SED 계산 실패: \(error.localizedDescription)")
            if calendar.isDateInToday(date) {
                self.error = .healthKit(.dataFetchFailed)
            }
        }
        
        return cache
    }
}

// MARK: - Watch Communication

private extension SyncCoordinator {
    
    func setupWatchConnectivity() {
        watchConnectivity.onMessageReceived = { [weak self] message in
            self?.handleWatchMessage(message)
        }
        
        watchConnectivity.onUserInfoReceived = { [weak self] userInfo in
            self?.handleUserInfoFromWatch(userInfo)
        }
        
        Log.debug("Watch Connectivity 콜백 설정 완료")
    }
    
    /// Watch에서 수신한 즉시 메시지 처리
    func handleWatchMessage(_ message: [String: Any]) {
        let type = message[WatchMessageKey.type] as? String
        Log.debug("Watch 메시지 수신: \(type ?? "unknown")")
        
        switch type {
        case WatchMessageKey.TypeValue.sunscreenApplication:
            handleSunscreenFromWatch(message)
        case WatchMessageKey.TypeValue.sunscreenCancellation:
            stopSunscreen()
            sendDashboardToWatch()
            Log.info("Watch에서 선크림 중단 수신")
        default:
            break
        }
        
        if message[WatchMessageKey.requestDashboardSync] as? Bool == true {
            sendDashboardToWatch()
        }
    }
    
    /// Watch에서 선크림 도포 수신
    func handleSunscreenFromWatch(_ message: [String: Any]) {
        let spfRaw = message[WatchMessageKey.sunscreenSPF] as? Int ?? 50
        let spf = SPFLevel(rawValue: spfRaw) ?? .spf50
        
        applySunscreen(spf: spf)
        Log.info("Watch에서 선크림 도포 수신: SPF \(spfRaw)")
    }
    
    /// Watch에서 수신한 백그라운드 UserInfo 처리
    func handleUserInfoFromWatch(_ userInfo: [String: Any]) {
        let type = userInfo[WatchMessageKey.type] as? String
        Log.debug("Watch UserInfo 수신: \(type ?? "unknown")")
        
        if type == WatchMessageKey.TypeValue.sunscreenApplication {
            handleSunscreenFromWatch(userInfo)
        }
    }
    
    /// Watch에 대시보드 데이터 전송 및 Application Context 업데이트
    func sendDashboardToWatch() {
        var data: [String: Any] = [
            WatchMessageKey.type: WatchMessageKey.TypeValue.dashboardData,
            WatchMessageKey.uvIndex: currentUVIndex,
            WatchMessageKey.totalSED: todayTotalSED,
            WatchMessageKey.warningLevel: warningLevel.rawValue,
            WatchMessageKey.timestamp: Date().timeIntervalSince1970
        ]
        
        if let weather = currentWeather {
            data[WatchMessageKey.cityName] = weather.location.cityName
            data[WatchMessageKey.temperature] = weather.currentTemperature
        }
        
        if let skinType = userProfile?.skinType {
            data[WatchMessageKey.maxSED] = SEDCalculator.maxSED(for: skinType)
        }
        
        if let sunscreen = activeSunscreen {
            data[WatchMessageKey.sunscreenSPF] = sunscreen.spfLevel.rawValue
            data[WatchMessageKey.sunscreenAppliedAt] = sunscreen.appliedAt.timeIntervalSince1970
            data[WatchMessageKey.reapplyMinutes] = sunscreen.reapplyIntervalMinutes
        }
        
        // 1. Application Context 업데이트 (보장된 전달)
        do {
            try watchConnectivity.updateApplicationContext(data)
        } catch {
            Log.error("Application Context 업데이트 실패: \(error.localizedDescription)")
        }
        
        // 2. 즉시 메시지 전송 (Watch 실행 중일 때)
        watchConnectivity.sendMessage(data, replyHandler: { reply in
            Log.debug("Watch 대시보드 응답: \(reply)")
        }, errorHandler: { _ in
            Log.debug("Watch 즉시 전송 불가 - Application Context로 대체됨")
        })
        
        Log.info("Watch 대시보드 데이터 전송")
    }
}

// MARK: - Event Handlers

private extension SyncCoordinator {
    
    func handleLocationDidChange(_ notification: Notification) async {
        Log.debug("위치 변경 감지")
        
        guard let locationInfo = notification.userInfo?[NotificationUserInfoKey.location] as? LocationInfo else {
            await fetchCurrentLocationAndWeather()
            return
        }
        
        do {
            let locationRecord = LocationRecord(from: locationInfo)
            localStorage.saveLocationRecord(locationRecord)
            
            let weather = try await self.weather.fetchCurrentWeather(for: locationInfo)
            currentWeather = weather
            
            Log.info("위치 변경 처리 완료: UV \(weather.currentUVIndex)")
        } catch {
            Log.error("위치 변경 처리 실패: \(error.localizedDescription)")
        }
    }
    
    func handleHealthKitDataUpdate() async {
        Log.debug("HealthKit 데이터 업데이트")
        await calculateRecentSED()
        checkWarningLevelAndNotify()
    }
    
    func handleDayChanged() async {
        resetForNewDay()
    }
    
    /// 타이머 정지됨 (TimerViewModel에서 HealthKit 저장 후 발송)
    func handleTimerStopped() async {
        Log.debug("타이머 정지됨 - SED 재계산")
        await calculateRecentSED()
        checkWarningLevelAndNotify()
    }
    
    /// 푸시 알림에서 "바르기" 버튼 탭
    func handlePushNotificationApply() async {
        Log.debug("푸시 알림에서 선크림 바르기 탭")
        let spf = userProfile?.spfLevel ?? .spf30
        applySunscreen(spf: spf)
    }
    
    /// 새 날짜 리셋 (자정 Observer 또는 앱 재진입 시)
    ///
    /// SED, 경고 이력, Live Activity를 초기화합니다.
    /// `handleDayChanged()`와 `refresh()` 날짜 비교에서 호출됩니다.
    func resetForNewDay() {
        todayTotalSED = 0
        lastNotifiedWarningLevel = .safe
        notification.resetMEDWarningHistory()
        localStorage.cleanupOldData()
        liveActivity.updateWarningLevel(.safe, progress: 0)
        Log.info("새 날짜 감지 — SED 리셋")
    }
}

// MARK: - Warning & Check Helpers

private extension SyncCoordinator {
    
    func checkWarningLevelAndNotify() {
        // 푸시 알림은 항상 호출 (NotificationManager가 자체 중복 방지)
        notification.sendMEDWarning(percentage: todaySEDProgress)
        
        // Live Activity는 항상 현재 레벨 반영
        let newLevel = warningLevel
        liveActivity.updateWarningLevel(newLevel, progress: todaySEDProgress)
        
        // UI/Watch 갱신은 레벨 변경 시에만
        guard newLevel.notificationPriority > lastNotifiedWarningLevel.notificationPriority else {
            return
        }
        guard newLevel.shouldNotify else { return }
        
        lastNotifiedWarningLevel = newLevel
        
        if let skinType = userProfile?.skinType {
            watchConnectivity.sendMEDStatus(
                totalSED: todayTotalSED,
                maxMED: SEDCalculator.maxSED(for: skinType)
            )
        }
        
        Log.info("경고 레벨 변경: \(newLevel.title)")
        
        NotificationCenter.default.post(
            name: .warningLevelDidChange,
            object: nil,
            userInfo: [NotificationUserInfoKey.level: newLevel]
        )
    }
    
    func loadUserProfile() {
        userProfile = localStorage.loadUserProfile() ?? .defaultUser
        Log.debug("프로필 로드: \(userProfile?.skinType.title ?? "없음")")
    }
    
    func loadActiveSunscreen() {
        let stopTime = localStorage.loadManualSunscreenStopTime()
        
        activeSunscreen = localStorage.loadSunscreenHistory()
            .filter { $0.isActive(at: Date()) }
            .filter { record in
                // 수동 종료 시각 이후에 도포된 기록만 유효
                guard let stopTime else { return true }
                return record.appliedAt > stopTime
            }
            .sorted { $0.appliedAt > $1.appliedAt }
            .first
        
        Log.debug("활성 선크림: \(activeSunscreen != nil ? "있음" : "없음")")
    }
    
    /// 현재 위치 및 날씨 조회
    ///
    /// 실패 시 기존 날씨가 있으면 유지하여, 이후 SED 계산에서
    /// 과거 UV 조회 시 위치 정보를 활용할 수 있도록 합니다.
    /// 날씨가 한 번도 성공하지 못한 경우에만 서울 기본값으로 대체합니다.
    func fetchCurrentLocationAndWeather() async {
        
        if let weather = currentWeather,
           Date().timeIntervalSince(weather.fetchedAt) < Self.weatherCacheTTL {
            Log.debug("날씨 캐시 유효 (\(Int(Date().timeIntervalSince(weather.fetchedAt)))초 경과), API 스킵")
            return
        }
        
        do {
            let locationInfo = try await location.getCurrentLocation()
            
            let locationRecord = LocationRecord(from: locationInfo)
            localStorage.saveLocationRecord(locationRecord)
            
            let weather = try await self.weather.fetchCurrentWeather(for: locationInfo)
            currentWeather = weather
            
            Log.info("위치/날씨 조회 완료: \(locationInfo.cityName ?? "알 수 없음"), UV \(weather.currentUVIndex)")
        } catch {
            Log.error("위치/날씨 조회 실패: \(error.localizedDescription)")
            // 기존 날씨가 있으면 유지, 없을 때만 기본값
            if currentWeather == nil {
                self.error = .weather(.requestFailed)
                await fetchDefaultWeather()
            }
        }
    }
    
    func fetchDefaultWeather() async {
        do {
            let weather = try await self.weather.fetchCurrentWeather(for: .mockSeoul)
            currentWeather = weather
            Log.info("서울 기본 날씨 로드: UV \(weather.currentUVIndex)")
        } catch {
            Log.error("서울 기본 날씨도 실패: \(error.localizedDescription) - 정적 기본값 사용")
            currentWeather = LocationWeather(
                location: .mockSeoul,
                currentUVIndex: 0,
                currentTemperature: 0
            )
        }
    }
    
    func checkSunscreenAndScheduleReminder() {
        guard let sunscreen = activeSunscreen else { return }
        
        if sunscreen.isActive(at: Date()) {
            let reapplyTime = sunscreen.nextReapplyTime
            Task {
                do {
                    try await notification.scheduleReapplyReminder(at: reapplyTime)
                    Log.info("선크림 알림 재예약: \(reapplyTime.formatted(date: .omitted, time: .shortened))")
                } catch {
                    Log.error("선크림 알림 재예약 실패: \(error.localizedDescription)")
                    self.error = .notification(.scheduleFailed)
                }
            }
        } else {
            activeSunscreen = nil
            liveActivity.endActivity()
            Log.info("선크림 효과 만료됨")
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension SyncCoordinator {
    
    var debugLocalStorage: any LocalStorageManagerProtocol { localStorage }
    var debugHealthKit: any HealthKitManagerProtocol { healthKit }
    
    static func preview(
        totalSED: Double = 0,
        uvIndex: Double = 5.0,
        temperature: Double = 25.0,
        cityName: String = "포항시",
        skinType: SkinType = .type3,
        activeSunscreen: SunscreenApplication? = nil
    ) -> SyncCoordinator {
        let coordinator = SyncCoordinator(
            healthKit: MockHealthKitManager(),
            weather: MockWeatherManager(),
            location: MockLocationManager(),
            localStorage: MockLocalStorageManager(),
            notification: MockNotificationManager(),
            watchConnectivity: MockWatchConnectivityManager(),
            liveActivity: MockLiveActivityManager()
        )
        coordinator.userProfile = UserProfile(skinType: skinType)
        coordinator.todayTotalSED = totalSED
        coordinator.activeSunscreen = activeSunscreen
        coordinator.currentWeather = LocationWeather(
            location: LocationInfo(latitude: 36.0190, longitude: 129.3435, cityName: cityName),
            currentUVIndex: uvIndex,
            currentTemperature: temperature
        )
        coordinator.lastSyncTime = Date()
        return coordinator
    }
}
#endif
