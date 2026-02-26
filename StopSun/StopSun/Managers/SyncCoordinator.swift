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
/// - 앱 시작 시 권한 요청 및 초기 데이터 로드
/// - HealthKit Background Delivery 수신 및 SED 계산
/// - 위치 변경 감지 및 날씨 조회
/// - 선크림 도포 관리 및 알림 예약
/// - 경고 레벨 모니터링
///
@MainActor
final class SyncCoordinator: ObservableObject, SyncCoordinatorProtocol {
    
    // MARK: - Published Properties
    
    @Published private(set) var userProfile: UserProfile?
    @Published private(set) var todayTotalSED: Double = 0
    @Published private(set) var currentWeather: LocationWeather?
    @Published private(set) var activeSunscreen: SunscreenApplication?
    
    // MARK: - Sync State Properties
    
    @Published private(set) var isSyncing: Bool = false
    @Published private(set) var lastSyncTime: Date?
    @Published private(set) var error: AppError?
    
    // MARK: - Private State
    
    /// 마지막 알림 전송된 경고 레벨 (중복 알림 방지)
    private var lastNotifiedWarningLevel: WarningLevel = .safe
    
    // MARK: - Observer Tasks
    
    private var observerTasks: [Task<Void, Never>] = []
    
    // MARK: - Dependencies
    
    private let healthKit: any HealthKitManagerProtocol
    private let weather: any WeatherManagerProtocol
    private let location: any LocationManagerProtocol
    private let localStorage: any LocalStorageManagerProtocol
    private let notification: any NotificationManagerProtocol
    private let watchConnectivity: any WatchConnectivityManagerProtocol
    
    // MARK: - Initializer
    
    init(
        healthKit: any HealthKitManagerProtocol,
        weather: any WeatherManagerProtocol,
        location: any LocationManagerProtocol,
        localStorage: any LocalStorageManagerProtocol,
        notification: any NotificationManagerProtocol,
        watchConnectivity: any WatchConnectivityManagerProtocol
    ) {
        self.healthKit = healthKit
        self.weather = weather
        self.location = location
        self.localStorage = localStorage
        self.notification = notification
        self.watchConnectivity = watchConnectivity
        
        setupObservers()
        Log.info("SyncCoordinator 초기화 완료")
    }
    
    deinit {
        // Structured Concurrency: 모든 Task 취소
        observerTasks.forEach { $0.cancel() }
        Log.info("SyncCoordinator deinit - 모든 observer 취소됨")
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
        // 1. 위치 변경 Observer
        let locationTask = Task { [weak self] in
            let notifications = NotificationCenter.default.notifications(named: .locationDidChange)
            for await notification in notifications {
                guard let self else { return }
                await self.handleLocationDidChange(notification)
            }
        }
        observerTasks.append(locationTask)
        
        // 2. HealthKit 데이터 업데이트 Observer
        let healthKitTask = Task { [weak self] in
            let notifications = NotificationCenter.default.notifications(named: .healthKitDataDidUpdate)
            for await _ in notifications {
                guard let self else { return }
                await self.handleHealthKitDataUpdate()
            }
        }
        observerTasks.append(healthKitTask)
        
        // 3. 자정 Observer (SED 리셋)
        let midnightTask = Task { [weak self] in
            let notifications = NotificationCenter.default.notifications(named: .NSCalendarDayChanged)
            for await _ in notifications {
                guard let self else { return }
                await self.handleDayChanged()
            }
        }
        observerTasks.append(midnightTask)
        
        // 4. 푸시 알림 "바르기" 버튼 탭 Observer
        let pushApplyTask = Task { [weak self] in
            let notifications = NotificationCenter.default.notifications(named: .didTapApplySunscreenNotification)
            for await _ in notifications {
                guard let self else { return }
                await self.handlePushNotificationApply()
            }
        }
        observerTasks.append(pushApplyTask)
        
        Log.debug("Observer 설정 완료: \(observerTasks.count)개")

        // 5. Watch Connectivity 콜백 설정
        setupWatchConnectivity()
    }

    // MARK: - Watch Connectivity

    private func setupWatchConnectivity() {
        watchConnectivity.onMessageReceived = { [weak self] message in
            self?.handleWatchMessage(message)
        }

        watchConnectivity.onUserInfoReceived = { [weak self] userInfo in
            self?.handleUserInfoFromWatch(userInfo)
        }

        Log.debug("Watch Connectivity 콜백 설정 완료")
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

        // 0. Watch Connectivity 세션 활성화
        watchConnectivity.activate()

        // 1. 프로필 로드
        loadUserProfile()
        
        // 2. 저장된 선크림 상태 로드
        loadActiveSunscreen()
        
        // 3. HealthKit 권한 요청
        do {
            try await healthKit.requestAuthorization()
            try await healthKit.enableBackgroundDelivery()
            Log.info("HealthKit 권한 및 Background Delivery 설정 완료")
        } catch {
            Log.error("HealthKit 설정 실패: \(error.localizedDescription)")
            self.error = .healthKit(.authorizationDenied)
        }
        
        // 4. 위치 권한 요청 및 현재 위치 가져오기
        await location.requestAuthorization()
        
        if location.isAuthorized {
            location.startMonitoringSignificantLocationChanges()
            await fetchCurrentLocationAndWeather()
        } else {
            Log.warning("위치 권한 없음")
            self.error = .location(.authorizationDenied)
        }
        
        // 5. 알림 권한 요청
        do {
            try await notification.requestAuthorization()
            Log.info("알림 권한 설정 완료")
        } catch {
            Log.error("알림 권한 실패: \(error.localizedDescription)")
            self.error = .notification(.authorizationDenied)
        }
        
        // 6. 오늘 SED 계산
        await calculateTodaySED()
        
        // 7. 선크림 만료 체크 및 알림 재예약
        checkSunscreenAndScheduleReminder()
        
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
        
        Log.info("새로고침 시작")
        
        // 1. 현재 위치 및 날씨 조회
        await fetchCurrentLocationAndWeather()
        
        // 2. SED 재계산
        await calculateTodaySED()
        
        // 3. 선크림 상태 갱신
        loadActiveSunscreen()
        
        // 4. 경고 레벨 체크 및 알림
        checkWarningLevelAndNotify()

        // 5. Watch에 최신 상태 동기화
        sendDashboardToWatch()

        Log.info("새로고침 완료")
    }
    
    // MARK: - User Actions
    
    func applySunscreen(spf: SPFLevel) {
        let application = SunscreenApplication(
            spfLevel: spf,
            appliedAt: Date(),
            reapplyIntervalMinutes: spf.recommendedReapplicationMinutes
        )
        
        // 1. 히스토리에 저장
        localStorage.saveSunscreenApplication(application)
        activeSunscreen = application
        
        // 2. 재도포 알림 예약
        let reapplyTime = application.nextReapplyTime
        Task {
            do {
                try await notification.scheduleReapplyReminder(at: reapplyTime)
            } catch {
                Log.error("재도포 알림 예약 실패: \(error.localizedDescription)")
            }
        }
        
        // 3. Watch에 상태 전송
        watchConnectivity.sendSunscreenApplication(application)
        sendDashboardToWatch()

        // 4. TODO: Live Activity 시작
        
        Log.info("선크림 도포: SPF \(spf.rawValue), 재도포 알림: \(reapplyTime.formatted(date: .omitted, time: .shortened))")
    }
    
    func stopSunscreen() {
        // 1. 활성 선크림 해제 (히스토리는 유지)
        activeSunscreen = nil
        
        // 2. 재도포 알림 취소
        notification.cancelReapplyReminder()
        
        // 3. TODO: Live Activity 종료
        
        Log.info("선크림 타이머 종료")
    }
    
    func updateSkinType(_ skinType: SkinType) {
        localStorage.updateSkinType(skinType)
        userProfile?.skinType = skinType
        
        // 경고 레벨 재계산
        checkWarningLevelAndNotify()
        
        // Watch에 프로필 전송
        if let profile = userProfile {
            watchConnectivity.sendUserProfile(profile)
        }
        
        Log.info("피부 타입 변경: \(skinType.title)")
    }
    
    func updateSunScreenSPF(_ spfLevel: SPFLevel) {
        localStorage.updateSunscreenSPF(spfLevel)
        userProfile?.spfLevel = spfLevel
        
        // Watch에 프로필 전송
        if let profile = userProfile {
            watchConnectivity.sendUserProfile(profile)
        }
        
        Log.info("선호 SPF 변경: \(spfLevel.displayTitle)")
    }
    
    // MARK: - App Lifecycle
    
    func handleAppDidBecomeActive() {
        Log.debug("앱 Active")
        
        Task {
            await refresh()
        }
    }
    
    func handleAppWillResignActive() {
        Log.debug("앱 Background 전환")
        
        // 현재 상태 저장 (필요시)
        if let profile = userProfile {
            localStorage.saveUserProfile(profile)
        }
    }
}

// MARK: - Private Methods

private extension SyncCoordinator {
    
    // MARK: - Load Methods
    
    func loadUserProfile() {
        userProfile = localStorage.loadUserProfile() ?? .defaultUser
        Log.debug("프로필 로드: \(userProfile?.skinType.title ?? "없음")")
    }
    
    func loadActiveSunscreen() {
        // 히스토리에서 현재 유효한 선크림 찾기
        activeSunscreen = localStorage.loadSunscreenHistory()
            .filter { $0.isActive(at: Date()) }
            .sorted { $0.appliedAt > $1.appliedAt }
            .first
        
        Log.debug("활성 선크림: \(activeSunscreen != nil ? "있음" : "없음")")
    }
    
    // MARK: - Fetch Methods
    
    func fetchCurrentLocationAndWeather() async {
        do {
            let locationInfo = try await location.getCurrentLocation()
            
            // 위치 기록 저장
            let locationRecord = LocationRecord(from: locationInfo)
            localStorage.saveLocationRecord(locationRecord)
            
            // 날씨 조회
            let weather = try await self.weather.fetchCurrentWeather(for: locationInfo)
            currentWeather = weather
            
            Log.info("위치/날씨 조회 완료: \(locationInfo.cityName ?? "알 수 없음"), UV \(weather.currentUVIndex)")
            
        } catch {
            Log.error("위치/날씨 조회 실패: \(error.localizedDescription)")
            self.error = .weather(.requestFailed)
        }
    }
    
    // MARK: - SED Calculation
    
    func calculateTodaySED() async {
        do {
            // 오늘의 TimeInDaylight 조회
            let timeInDaylightData = try await healthKit.fetchTodayTimeInDaylight()
            
            // 오늘의 선크림 히스토리 로드
            let sunscreenHistory = localStorage.loadSunscreenHistory()
            
            var totalSED: Double = 0
            
            for data in timeInDaylightData {
                // 이미 처리된 데이터 스킵
                if localStorage.isProcessed(healthKitID: data.id) {
                    continue
                }
                
                // 해당 시점의 UV Index 조회 (API)
                let uvIndex = await getUVIndex(for: data.startTime)
                
                // 시간 분할을 고려한 SED 계산
                let sed = SEDCalculator.calculateWithSunscreenHistory(
                    start: data.startTime,
                    end: data.endTime,
                    uvIndex: uvIndex,
                    sunscreenHistory: sunscreenHistory
                )
                
                totalSED += sed
                
                // 해당 시점의 SPF 조회 (노출 기록용)
                let spf = localStorage.getActiveSPF(at: data.startTime)
                
                // 노출 기록 저장
                let exposureRecord = UVExposureRecord(
                    healthKitID: data.id,
                    startTime: data.startTime,
                    endTime: data.endTime,
                    averageUV: uvIndex,
                    appliedSPF: spf,
                    receivedSED: sed
                )
                localStorage.saveExposureRecord(exposureRecord)
            }
            
            // 기존 저장된 SED와 합산
            let existingRecords = localStorage.loadExposureRecords(for: Date())
            let existingSED = existingRecords.reduce(0) { $0 + $1.receivedSED }
            
            todayTotalSED = existingSED + totalSED
            
            // 일일 MED 기록 업데이트
            var dailyRecord = localStorage.loadDailyMEDRecord(for: Date()) ?? DailyMEDRecord(date: Date())
            dailyRecord.totalSED = todayTotalSED
            dailyRecord.recordCount = existingRecords.count
            localStorage.saveDailyMEDRecord(dailyRecord)
            
            Log.info("오늘 SED 계산 완료: \(String(format: "%.2f", todayTotalSED))")
            
        } catch {
            Log.error("SED 계산 실패: \(error.localizedDescription)")
        }
    }
    
    func getUVIndex(for date: Date) async -> Double {
        // 1. 해당 시점의 위치 조회
        guard let locationRecord = localStorage.getLocation(at: date) else {
            Log.warning("과거 위치 없음, 현재 UV 사용")
            return currentUVIndex
        }
        
        // 2. API로 과거 UV 조회
        do {
            let uvIndex = try await weather.fetchUVIndex(
                for: locationRecord.locationInfo,
                at: date
            )
            return uvIndex
        } catch {
            Log.error("과거 UV 조회 실패: \(error.localizedDescription)")
            return currentUVIndex
        }
    }
    
    // MARK: - Check Methods
    
    func checkSunscreenAndScheduleReminder() {
        guard let sunscreen = activeSunscreen else { return }
        
        if sunscreen.isActive(at: Date()) {
            // 아직 유효함 - 남은 시간으로 알림 재예약
            let reapplyTime = sunscreen.nextReapplyTime
            Task {
                do {
                    try await notification.scheduleReapplyReminder(at: reapplyTime)
                    Log.info("선크림 알림 재예약: \(reapplyTime.formatted(date: .omitted, time: .shortened))")
                } catch {
                    Log.error("선크림 알림 재예약 실패: \(error.localizedDescription)")
                }
            }
        } else {
            // 만료됨
            Log.info("선크림 효과 만료됨")
            activeSunscreen = nil
        }
    }
    
    func checkWarningLevelAndNotify() {
        // 푸시 알림은 항상 호출 (NotificationManager가 자체 중복 방지)
        notification.sendMEDWarning(percentage: todaySEDProgress)
        
        // UI/Watch 갱신은 레벨 변경 시에만
        let newLevel = warningLevel
        
        guard newLevel.notificationPriority > lastNotifiedWarningLevel.notificationPriority else {
            return
        }
        
        guard newLevel.shouldNotify else { return }
        
        lastNotifiedWarningLevel = newLevel
        
        // Watch에 상태 전송
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
    
    // MARK: - Notification Handlers
    
    func handleLocationDidChange(_ notification: Notification) async {
        Log.debug("위치 변경 감지")
        
        guard let locationInfo = notification.userInfo?[NotificationUserInfoKey.location] as? LocationInfo else {
            // userInfo 없으면 직접 조회
            await fetchCurrentLocationAndWeather()
            return
        }
        
        do {
            // 위치 기록 저장
            let locationRecord = LocationRecord(from: locationInfo)
            localStorage.saveLocationRecord(locationRecord)
            
            // 날씨 조회
            let weather = try await self.weather.fetchCurrentWeather(for: locationInfo)
            currentWeather = weather
            
            Log.info("위치 변경 처리 완료: UV \(weather.currentUVIndex)")
            
        } catch {
            Log.error("위치 변경 처리 실패: \(error.localizedDescription)")
        }
    }
    
    func handleHealthKitDataUpdate() async {
        Log.debug("HealthKit 데이터 업데이트")
        
        await calculateTodaySED()
        checkWarningLevelAndNotify()
    }
    
    func handleDayChanged() async {
        Log.info("자정 - SED 리셋")
        
        // SED 리셋
        todayTotalSED = 0
        lastNotifiedWarningLevel = .safe
        
        // 알림 경고 이력 초기화
        notification.resetMEDWarningHistory()
        
        // 오래된 데이터 정리
        localStorage.cleanupOldData()
        
        // 새로운 날 시작 알림 (필요시)
    }
    
    /// 타이머 정지됨 (TimerViewModel에서 HealthKit 저장 후 발송)
    func handleTimerStopped() async {
        Log.debug("타이머 정지됨 - SED 재계산")
        
        // HealthKit에 새 데이터가 저장되었으므로 SED 재계산
        await calculateTodaySED()
        
        // 경고 레벨 체크
        checkWarningLevelAndNotify()
    }
    
    /// 푸시 알림에서 "바르기" 버튼 탭
    func handlePushNotificationApply() async {
        Log.debug("푸시 알림에서 선크림 바르기 탭")

        // 사용자 설정된 SPF로 도포
        let spf = userProfile?.spfLevel ?? .spf30
        applySunscreen(spf: spf)
    }

    // MARK: - Watch Communication

    /// Watch에서 수신한 즉시 메시지 처리
    func handleWatchMessage(_ message: [String: Any]) {
        Log.debug("Watch 메시지 수신: \(message[WatchMessageKey.type] as? String ?? "unknown")")

        if message[WatchMessageKey.requestDashboardSync] as? Bool == true {
            sendDashboardToWatch()
        }
    }

    /// Watch에서 수신한 백그라운드 UserInfo 처리
    func handleUserInfoFromWatch(_ userInfo: [String: Any]) {
        Log.debug("Watch UserInfo 수신: \(userInfo[WatchMessageKey.type] as? String ?? "unknown")")

        // 향후 Watch → iPhone 백그라운드 데이터 처리
        // 예: 운동 데이터, Watch에서 선크림 도포 확인 등
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
        }

        // 1. Application Context 업데이트 (보장된 전달 — 먼저 실행)
        do {
            try watchConnectivity.updateApplicationContext(data)
        } catch {
            Log.error("Application Context 업데이트 실패: \(error.localizedDescription)")
        }

        // 2. 즉시 메시지 전송 (Watch가 실행 중일 때 — 실패 가능)
        watchConnectivity.sendMessage(data, replyHandler: { reply in
            Log.debug("Watch 대시보드 응답: \(reply)")
        }, errorHandler: { _ in
            Log.debug("Watch 즉시 전송 불가 - Application Context로 대체됨")
        })

        Log.info("Watch 대시보드 데이터 전송")
    }
}
