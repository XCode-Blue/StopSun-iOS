//
//  SunScreenViewModel.swift
//  StopSun
//
//  Created by donghee on 1/22/26.
//

import Foundation

#if DEBUG
/// 선크림 관련 View를 위한 ViewModel
/// - ViewModel은 Manager를 통해 데이터에 접근
@MainActor
final class SunScreenViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var isActive: Bool = false
    @Published var remainingMinutes: Int = 0
    @Published var progressRate: Double = 0.0
    @Published var effectiveness: Int = 0
    @Published var applicationTime: String = ""
    @Published var needsReapplication: Bool = false

    // MARK: - Dependencies
    private let localStorage: LocalStorageManagerProtocol

    // MARK: - Properties
    private var updateTimer: Timer?

    // MARK: - Initialization
    init(localStorage: LocalStorageManagerProtocol) {
        self.localStorage = localStorage
        Log.debug("SunScreenViewModel initialized")

        setupTimer()
        refresh()
    }

    deinit {
        updateTimer?.invalidate()
        Log.debug("SunScreenViewModel deinitialized")
    }

    // MARK: - Public Methods

    /// 선크림 발림 처리
    func applySunScreen() {
        let profile = localStorage.loadUserProfileOrDefault()
        let spfLevel = profile.spfLevel
        let sunScreen = SunscreenApplication(spfLevel: spfLevel, appliedAt: Date())
        localStorage.saveSunscreenApplication(sunScreen)
        Log.info("Sunscreen applied successfully")
        refresh()
    }

    /// 커스텀 SPF로 선크림 발림
    /// - Parameter spfLevel: SPF 레벨
    func applySunScreen(withSPF spfLevel: SPFLevel) {
        let sunScreen = SunscreenApplication(spfLevel: spfLevel, appliedAt: Date())
        localStorage.saveSunscreenApplication(sunScreen)
        Log.info("Sunscreen applied with SPF \(spfLevel.rawValue)")
        refresh()
    }

    /// 선크림 기록 삭제
    func removeSunScreen() {
        localStorage.deleteSunscreen()
        Log.info("Sunscreen removed")
        refresh()
    }

    /// 데이터 새로고침
    func refresh() {
        updateState()
        Log.debug("SunScreen state refreshed")
    }

    /// 남은 시간 포맷팅 (Localized)
    func fetchFormattedRemainingTime() -> String {
        let hours = remainingMinutes / 60
        let minutes = remainingMinutes % 60

        if hours > 0 && minutes > 0 {
            return L10n.Sunscreen.Time.hoursMinutes(hours, minutes)
        } else if hours > 0 {
            return L10n.Sunscreen.Time.hours(hours)
        } else if minutes > 0 {
            return L10n.Sunscreen.Time.minutes(minutes)
        } else {
            return L10n.Sunscreen.Time.expired
        }
    }

    /// 효과 상태 텍스트 (Localized)
    func fetchEffectivenessStatus() -> String {
        switch effectiveness {
        case 80...100:
            return L10n.Sunscreen.Effectiveness.excellent
        case 50..<80:
            return L10n.Sunscreen.Effectiveness.good
        case 1..<50:
            return L10n.Sunscreen.Effectiveness.weak
        default:
            return L10n.Sunscreen.Effectiveness.reapply
        }
    }

    /// 효과 상태 색상 (UI용)
    func fetchEffectivenessColor() -> String {
        switch effectiveness {
        case 80...100:
            return "key00" // 좋음
        case 50..<80:
            return "key01" // 보통
        case 1..<50:
            return "text03" // 약함
        default:
            return "text05" // 재발림 필요
        }
    }

    // MARK: - Private Methods

    /// 타이머 설정 (1분마다 업데이트)
    private func setupTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateState()
            }
        }
    }

    /// 상태 업데이트
    private func updateState() {
        isActive = localStorage.isSunscreenActive()
        remainingMinutes = localStorage.loadSunscreenRemainingMinutes()
        progressRate = fetchProgressRate()
        effectiveness = fetchEffectivenessPercentage()
        applicationTime = fetchFormattedApplicationTime()
        needsReapplication = checkNeedsReapplication()
    }

    /// 선크림 발림 후 진행률 (0.0 ~ 1.0)
    private func fetchProgressRate() -> Double {
        guard let sunScreen = localStorage.loadCurrentSunscreen() else {
            return 1.0 // 없으면 만료로 간주
        }

        let elapsed = Date().timeIntervalSince(sunScreen.appliedAt)
        let totalDuration = Double(sunScreen.reapplyIntervalMinutes * 60)
        let rate = elapsed / totalDuration

        return min(max(rate, 0.0), 1.0) // 0.0 ~ 1.0 범위로 제한
    }

    /// 선크림 효과 퍼센티지 (100% ~ 0%)
    private func fetchEffectivenessPercentage() -> Int {
        let progress = progressRate
        let remaining = 1.0 - progress
        return Int(remaining * 100)
    }

    /// 선크림 발림 시각 포맷팅
    private func fetchFormattedApplicationTime() -> String {
        guard let sunScreen = localStorage.loadCurrentSunscreen() else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "a h:mm"
        formatter.locale = Locale(identifier: "ko_KR")

        return formatter.string(from: sunScreen.appliedAt)
    }

    /// 선크림 재발림이 필요한지 확인
    private func checkNeedsReapplication(warningThreshold: Int = 30) -> Bool {
        let remaining = remainingMinutes

        if remaining == 0 {
            return true
        } else if remaining <= warningThreshold {
            return true
        } else {
            return false
        }
    }
}
#endif
