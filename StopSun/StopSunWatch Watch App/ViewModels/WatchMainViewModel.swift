//
//  WatchMainViewModel.swift
//  StopSunWatch Watch App
//
//  Created by J on 2/25/26.
//

import SwiftUI
import Combine

/// Watch 메인 ViewModel
///
/// ## 역할
/// - WatchSessionManager를 통해 iPhone 데이터 수신
/// - MED / UVI / 선크림 타이머 상태 관리
/// - Watch → iPhone 선크림 도포 전송
///
/// ## 데이터 흐름
/// 1. 앱 실행 → 캐시된 Application Context 로드
/// 2. iPhone에 대시보드 동기화 요청
/// 3. 실시간 메시지 / Context 수신으로 UI 갱신
///
@MainActor
@Observable
final class WatchMainViewModel {
    
    // MARK: - Properties (MED / UVI)
    
    var currentUVIndex: Double = 0
    var todayTotalSED: Double = 0
    var maxSED: Double = 1.0
    
    // MARK: - Properties (Sunscreen Timer)
    
    var sunscreenAppliedAt: Date?
    var sunscreenSPF: Int?
    var reapplyIntervalMinutes: Int = 120
    private(set) var remainingSeconds: Int = 0
    
    // MARK: - Properties (Navigation)

    var selectedPage: WatchPage = .dashboard

    // MARK: - Properties (Connection)

    var isPhoneConnected: Bool = false
    var lastSyncTime: Date?
    var syncFailed: Bool = false
    
    // MARK: - Private (Combine / non-observable)
    
    @ObservationIgnored
    private let sessionManager = WatchSessionManager.shared
    
    @ObservationIgnored
    private var cancellables = Set<AnyCancellable>()
    
    @ObservationIgnored
    private var timerCancellable: AnyCancellable?
    
    // MARK: - Computed (MED)
    
    var medPercentage: Int {
        guard maxSED > 0 else { return 0 }
        return min(Int(todayTotalSED / maxSED * 100), 999)
    }
    
    var warningLevel: WarningLevel {
        guard maxSED > 0 else { return .safe }
        return .from(progress: todayTotalSED / maxSED)
    }
    
    var uvLevel: UVLevel {
        UVLevel(uvIndex: currentUVIndex)
    }
    
    // MARK: - Computed (Timer)
    
    var timerState: SunscreenTimerState {
        guard let appliedAt = sunscreenAppliedAt else { return .idle }
        let interval = TimeInterval(reapplyIntervalMinutes * 60)
        return Date().timeIntervalSince(appliedAt) >= interval ? .expired : .active
    }
    
    var timerText: String {
        String(format: "%d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }
    
    // MARK: - Computed (Sync)
    
    @ObservationIgnored
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()
    
    var lastSyncText: String {
        guard let time = lastSyncTime else { return "동기화 안 됨" }
        return "마지막 동기화 \(Self.timeFormatter.string(from: time))"
    }
    
    // MARK: - Init

    init() {
        setupConnectivity()
        setupNotificationObservers()
        loadCachedData()
    }
    
    /// Preview / 테스트용 init
    init(
        currentUVIndex: Double,
        todayTotalSED: Double,
        maxSED: Double,
        sunscreenAppliedAt: Date? = nil,
        sunscreenSPF: Int? = nil
    ) {
        self.currentUVIndex = currentUVIndex
        self.todayTotalSED = todayTotalSED
        self.maxSED = maxSED
        self.sunscreenAppliedAt = sunscreenAppliedAt
        self.sunscreenSPF = sunscreenSPF
    }
    
    // MARK: - Notification Observers

    /// WatchNotificationDelegate의 알림 액션 이벤트를 구독합니다.
    private func setupNotificationObservers() {
        let sunscreenYes = NotificationCenter.default.publisher(for: .watchDidTapSunscreenYes)
            .map { _ in true }
        let bodyTap = NotificationCenter.default.publisher(for: .watchDidTapNotificationBody)
            .map { _ in false }

        sunscreenYes.merge(with: bodyTap)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSunscreenApply in
                if isSunscreenApply {
                    print("[Watch] 알림 액션으로 선크림 도포 처리")
                    self?.applySunscreen()
                }
                self?.selectedPage = .timer
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .watchDidTapSunscreenNo)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                print("[Watch] 알림 액션으로 선크림 미도포 확인")
            }
            .store(in: &cancellables)
    }

    // MARK: - Connectivity Setup

    private func setupConnectivity() {
        sessionManager.onMessageReceived = { [weak self] message in
            self?.handleMessage(message)
        }
        
        sessionManager.onUserInfoReceived = { [weak self] userInfo in
            self?.handleUserInfo(userInfo)
        }
        
        sessionManager.onApplicationContextReceived = { [weak self] context in
            self?.handleDashboardData(context)
        }
        
        // @Observable에서는 assign(to:) 사용 불가 → sink로 대체
        sessionManager.$isReachable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] reachable in
                self?.isPhoneConnected = reachable
            }
            .store(in: &cancellables)
    }
    
    private func loadCachedData() {
        guard let cached = sessionManager.loadCachedApplicationContext() else { return }
        handleDashboardData(cached, isFromCache: true)
        Log.debug("[Watch] 캐시 데이터로 초기 화면 구성")
    }
    
    // MARK: - Public Actions
    
    func requestDashboardSync() {
        syncFailed = false
        sessionManager.requestDashboardSync(onError: { [weak self] in
            DispatchQueue.main.async {
                self?.syncFailed = true
            }
        })
    }
    
    func applySunscreen() {
        sunscreenAppliedAt = Date()
        sunscreenSPF = sunscreenSPF ?? 50
        startTimer()
        
        let message: [String: Any] = [
            WatchMessageKey.type: WatchMessageKey.TypeValue.sunscreenApplication,
            WatchMessageKey.sunscreenSPF: sunscreenSPF ?? 50,
            WatchMessageKey.sunscreenAppliedAt: Date().timeIntervalSince1970,
            WatchMessageKey.timestamp: Date().timeIntervalSince1970
        ]
        
        sessionManager.sendMessage(message, replyHandler: { reply in
            Log.debug("[Watch] 선크림 도포 전송 응답: \(reply)")
        }, errorHandler: { error in
            Log.warning("[Watch] 선크림 도포 전송 실패 — iPhone 미연결: \(error.localizedDescription)")
        })
        
        Log.info("[Watch] 선크림 도포: SPF \(sunscreenSPF ?? 50)")
    }
    
    func cancelSunscreen() {
        sunscreenAppliedAt = nil
        remainingSeconds = 0
        stopTimer()
        
        let message: [String: Any] = [
            WatchMessageKey.type: WatchMessageKey.TypeValue.sunscreenCancellation,
            WatchMessageKey.timestamp: Date().timeIntervalSince1970
        ]
        
        sessionManager.sendMessage(message, replyHandler: { reply in
            Log.debug("[Watch] 선크림 중단 전송 응답: \(reply)")
        }, errorHandler: { error in
            Log.warning("[Watch] 선크림 중단 전송 실패: \(error.localizedDescription)")
        })
        
        Log.info("[Watch] 선크림 타이머 중단")
    }
    
    // MARK: - Timer
    
    func startTimer() {
        updateRemainingTime()
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateRemainingTime()
            }
    }
    
    func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    private func updateRemainingTime() {
        guard let appliedAt = sunscreenAppliedAt else {
            remainingSeconds = 0
            return
        }
        let interval = TimeInterval(reapplyIntervalMinutes * 60)
        let remaining = interval - Date().timeIntervalSince(appliedAt)
        remainingSeconds = max(0, Int(remaining))
    }
    
    // MARK: - Message Handling
    
    private func handleMessage(_ message: [String: Any]) {
        let type = message[WatchMessageKey.type] as? String
        Log.debug("[Watch] 메시지 수신: \(type ?? "unknown")")
        
        switch type {
        case WatchMessageKey.TypeValue.dashboardData:
            handleDashboardData(message)
        case WatchMessageKey.TypeValue.sunscreenApplication:
            handleSunscreenUpdate(message)
        case WatchMessageKey.TypeValue.medStatus:
            handleMEDStatus(message)
        default:
            break
        }
    }
    
    private func handleUserInfo(_ userInfo: [String: Any]) {
        let type = userInfo[WatchMessageKey.type] as? String
        Log.debug("[Watch] UserInfo 수신: \(type ?? "unknown")")
        
        switch type {
        case WatchMessageKey.TypeValue.userProfile:
            if let skinType = userInfo[WatchMessageKey.skinType] as? Int {
                Log.debug("[Watch] 사용자 피부 타입 수신: \(skinType)")
            }
        default:
            break
        }
    }
    
    // MARK: - Data Parsing
    
    private func handleDashboardData(_ data: [String: Any], isFromCache: Bool = false) {
        if let uvIndex = data[WatchMessageKey.uvIndex] as? Double {
            currentUVIndex = uvIndex
        }
        if let sed = data[WatchMessageKey.totalSED] as? Double {
            todayTotalSED = sed
        }
        if let max = data[WatchMessageKey.maxSED] as? Double {
            maxSED = max
        }
        if let spfRaw = data[WatchMessageKey.sunscreenSPF] as? Int {
            sunscreenSPF = spfRaw
        }
        if let minutes = data[WatchMessageKey.reapplyMinutes] as? Int {
            reapplyIntervalMinutes = minutes
        }
        if let appliedAt = data[WatchMessageKey.sunscreenAppliedAt] as? Double {
            sunscreenAppliedAt = Date(timeIntervalSince1970: appliedAt)
            updateRemainingTime()
        }
        
        if !isFromCache {
            lastSyncTime = Date()
            syncFailed = false
        }
    }
    
    private func handleSunscreenUpdate(_ data: [String: Any]) {
        if let spfRaw = data[WatchMessageKey.sunscreenSPF] as? Int {
            sunscreenSPF = spfRaw
        }
        if let minutes = data[WatchMessageKey.reapplyMinutes] as? Int {
            reapplyIntervalMinutes = minutes
        }
        if let appliedAt = data[WatchMessageKey.sunscreenAppliedAt] as? Double {
            sunscreenAppliedAt = Date(timeIntervalSince1970: appliedAt)
            updateRemainingTime()
        }
    }
    
    private func handleMEDStatus(_ data: [String: Any]) {
        if let sed = data[WatchMessageKey.totalSED] as? Double {
            todayTotalSED = sed
        }
        if let max = data[WatchMessageKey.maxSED] as? Double {
            maxSED = max
        }
    }
}

// MARK: - Preview Presets

extension WatchMainViewModel {
    
    static var safe: WatchMainViewModel {
        .init(currentUVIndex: 2, todayTotalSED: 0.18, maxSED: 1.0)
    }
    
    static var caution: WatchMainViewModel {
        .init(
            currentUVIndex: 5,
            todayTotalSED: 0.38,
            maxSED: 1.0,
            sunscreenAppliedAt: Date().addingTimeInterval(-37 * 60),
            sunscreenSPF: 50
        )
    }
    
    static var warning: WatchMainViewModel {
        .init(
            currentUVIndex: 8,
            todayTotalSED: 0.65,
            maxSED: 1.0,
            sunscreenAppliedAt: Date().addingTimeInterval(-3 * 60 * 60),
            sunscreenSPF: 50
        )
    }
    
    static var danger: WatchMainViewModel {
        .init(currentUVIndex: 11, todayTotalSED: 0.92, maxSED: 1.0)
    }
}
