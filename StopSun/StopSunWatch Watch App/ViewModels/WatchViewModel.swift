//
//  WatchViewModel.swift
//  StopSunWatch Watch App
//
//  Created by donghee on 2/21/26.
//

import SwiftUI
import Combine

/// Watch 화면 상태 관리 ViewModel
///
/// iPhone에서 수신한 대시보드 데이터를 관리하고 UI에 제공합니다.
///
/// ## 데이터 흐름
/// 1. 앱 실행 시 캐시된 Application Context에서 초기 데이터 로드
/// 2. iPhone에 대시보드 동기화 요청
/// 3. 실시간 메시지 및 Application Context 수신으로 업데이트
///
@MainActor
class WatchViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var isPhoneConnected: Bool = false
    @Published var currentUVIndex: Double = 0.0
    @Published var temperature: Double = 0.0
    @Published var cityName: String = "대기 중..."
    @Published var todayTotalSED: Double = 0.0
    @Published var maxSED: Double = 0.0
    @Published var warningLevel: WarningLevel = .safe
    @Published var sunscreenSPF: SPFLevel?
    @Published var sunscreenAppliedAt: Date?

    /// 마지막 동기화 성공 시각 (nil이면 아직 동기화 안 됨)
    @Published var lastSyncTime: Date?

    /// 동기화 실패 여부
    @Published var syncFailed: Bool = false

    // MARK: - Private Properties

    private let sessionManager = WatchSessionManager.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Formatted Display Properties

    /// 기온 표시 (소수점 1자리)
    var temperatureText: String {
        String(format: "%.1f°", temperature)
    }

    /// UV Index 표시 (소수점 1자리)
    var uvIndexText: String {
        String(format: "%.1f", currentUVIndex)
    }

    /// 누적 SED 표시 (소수점 2자리)
    var totalSEDText: String {
        String(format: "%.2f", todayTotalSED)
    }

    /// 최대 SED 표시 (소수점 1자리)
    var maxSEDText: String {
        String(format: "%.1f", maxSED)
    }

    /// DateFormatter 재사용 (Watch 리소스 절약)
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    /// 마지막 동기화 시각 표시
    var lastSyncText: String {
        guard let time = lastSyncTime else { return "동기화 안 됨" }
        return "마지막 동기화 \(Self.timeFormatter.string(from: time))"
    }

    // MARK: - Computed Properties

    /// SED 진행률 (0.0 ~ 1.0+)
    var sedProgress: Double {
        guard maxSED > 0 else { return 0 }
        return todayTotalSED / maxSED
    }

    /// 경고 레벨 한글 표시 (WarningLevel.title 활용)
    var warningLevelTitle: String {
        warningLevel.title
    }

    /// 경고 레벨 색상 (WarningLevel.color 활용)
    var warningLevelColor: Color {
        warningLevel.color
    }

    /// 선크림 도포 상태 텍스트 (SPFLevel.displayTitle 활용)
    var sunscreenStatusText: String {
        guard let spf = sunscreenSPF else { return "미도포" }
        return spf.displayTitle
    }

    // MARK: - Initialization

    init() {
        setupWatchConnectivity()
        observeReachability()
        loadCachedData()
    }

    // MARK: - Setup Methods

    private func setupWatchConnectivity() {
        // 즉시 메시지 수신 콜백
        sessionManager.onMessageReceived = { [weak self] message in
            self?.handleMessageFromPhone(message)
        }

        // UserInfo 수신 콜백
        sessionManager.onUserInfoReceived = { [weak self] userInfo in
            self?.handleUserInfoFromPhone(userInfo)
        }

        // Application Context 수신 콜백
        sessionManager.onApplicationContextReceived = { [weak self] context in
            self?.handleDashboardData(context)
        }
    }

    private func observeReachability() {
        sessionManager.$isReachable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isReachable in
                self?.isPhoneConnected = isReachable
                Log.debug("[Watch] iPhone 연결 상태: \(isReachable)")
            }
            .store(in: &cancellables)
    }

    /// 캐시된 Application Context에서 초기 데이터 로드
    private func loadCachedData() {
        guard let cached = sessionManager.loadCachedApplicationContext() else { return }
        handleDashboardData(cached, isFromCache: true)
        Log.debug("[Watch] 캐시 데이터로 초기 화면 구성 완료")
    }

    // MARK: - Public Methods

    /// iPhone에 대시보드 동기화 요청
    ///
    /// 성공 여부는 `handleDashboardData()`에서 `lastSyncTime` 갱신으로 확인됩니다.
    /// 전송 실패 시 `syncFailed`가 true로 설정됩니다.
    func requestDashboardSync() {
        syncFailed = false
        sessionManager.requestDashboardSync(onError: { [weak self] in
            DispatchQueue.main.async {
                self?.syncFailed = true
            }
        })
    }

    // MARK: - Message Handling

    private func handleMessageFromPhone(_ message: [String: Any]) {
        let type = message[WatchMessageKey.type] as? String
        Log.debug("[Watch] iPhone 메시지 처리: \(type ?? "unknown")")

        switch type {
        case WatchMessageKey.TypeValue.dashboardData:
            handleDashboardData(message)
        case WatchMessageKey.TypeValue.sunscreenApplication:
            handleSunscreenData(message)
        case WatchMessageKey.TypeValue.medStatus:
            handleMEDStatus(message)
        default:
            break
        }
    }

    private func handleUserInfoFromPhone(_ userInfo: [String: Any]) {
        let type = userInfo[WatchMessageKey.type] as? String
        Log.debug("[Watch] iPhone UserInfo 처리: \(type ?? "unknown")")

        switch type {
        case WatchMessageKey.TypeValue.userProfile:
            handleUserProfile(userInfo)
        default:
            break
        }
    }

    // MARK: - Data Parsing

    private func handleDashboardData(_ data: [String: Any], isFromCache: Bool = false) {
        if let uvIndex = data[WatchMessageKey.uvIndex] as? Double {
            currentUVIndex = uvIndex
        }
        if let temp = data[WatchMessageKey.temperature] as? Double {
            temperature = temp
        }
        if let city = data[WatchMessageKey.cityName] as? String {
            cityName = city
        }
        if let sed = data[WatchMessageKey.totalSED] as? Double {
            todayTotalSED = sed
        }
        if let max = data[WatchMessageKey.maxSED] as? Double {
            maxSED = max
        }
        if let levelString = data[WatchMessageKey.warningLevel] as? String,
           let level = WarningLevel(rawValue: levelString) {
            warningLevel = level
        }

        if let spfRaw = data[WatchMessageKey.sunscreenSPF] as? Int {
            sunscreenSPF = SPFLevel(rawValue: spfRaw)
        } else {
            sunscreenSPF = nil
        }
        if let appliedAt = data[WatchMessageKey.sunscreenAppliedAt] as? Double {
            sunscreenAppliedAt = Date(timeIntervalSince1970: appliedAt)
        } else {
            sunscreenAppliedAt = nil
        }

        // 캐시 로드 시에는 동기화 시각을 갱신하지 않음
        if !isFromCache {
            lastSyncTime = Date()
            syncFailed = false
        }
    }

    private func handleSunscreenData(_ data: [String: Any]) {
        if let spfRaw = data[WatchMessageKey.sunscreenSPF] as? Int {
            sunscreenSPF = SPFLevel(rawValue: spfRaw)
        }
        if let appliedAt = data[WatchMessageKey.sunscreenAppliedAt] as? Double {
            sunscreenAppliedAt = Date(timeIntervalSince1970: appliedAt)
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

    private func handleUserProfile(_ data: [String: Any]) {
        // 향후 피부 타입 표시 등에 활용
        if let skinType = data[WatchMessageKey.skinType] as? Int {
            Log.debug("[Watch] 사용자 피부 타입 수신: \(skinType)")
        }
    }

    // MARK: - Preview

    #if DEBUG
    /// Preview용 샘플 데이터가 설정된 ViewModel
    static var preview: WatchViewModel {
        let vm = WatchViewModel()
        vm.isPhoneConnected = true
        vm.currentUVIndex = 6.3
        vm.temperature = 28.5
        vm.cityName = "서울"
        vm.todayTotalSED = 0.75
        vm.maxSED = 1.5
        vm.warningLevel = .caution
        vm.sunscreenSPF = .spf50
        vm.sunscreenAppliedAt = Date()
        vm.lastSyncTime = Date()
        return vm
    }
    #endif
}
