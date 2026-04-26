//
//  DashboardViewModel.swift
//  StopSun
//
//  Created by J on 2/21/26.
//

import Foundation

/// Dashboard 화면 전용 ViewModel
///
/// SyncCoordinator의 데이터를 대시보드 UI에 맞게 변환합니다.
/// View-specific 상태(페이지 인덱스 등)만 직접 관리하고,
/// 데이터는 모두 SyncCoordinator에서 computed로 읽습니다.
///
@MainActor
@Observable
final class DashboardViewModel {
    // MARK: - View State
    
    var currentPage: Int = 0
    
    /// Watch 미보유 시 MED 자동 추적 불가 → 선크림 타이머 중심 UI
    var hasWatch: Bool {
        syncCoordinator.userProfile?.hasWatch ?? true
    }
    
    /// 캐싱된 날짜 문자열 (하루에 한 번만 갱신)
    private(set) var formattedDate: String = ""
    private(set) var weeklyChartItems: [WeeklyBarItem] = []
    
    // MARK: - Private Cache State
    
    private var lastBuiltDate: Date?
    
    // MARK: - Dependencies
    
    private let syncCoordinator: SyncCoordinator
    private let localStorage: any LocalStorageManagerProtocol
    
    /// 재sync 판단 기준 (15분)
    private let resyncInterval: TimeInterval = 15 * 60
    
    // MARK: - Initializer
    
    init(
        syncCoordinator: SyncCoordinator,
        localStorage: any LocalStorageManagerProtocol
    ) {
        self.syncCoordinator = syncCoordinator
        self.localStorage = localStorage
        self.formattedDate = Date().toDayWithWeekdayString
    }
    
    // MARK: - MED Data (J/m² 단위로 표시)
    
    /// 오늘 누적 자외선량 (J/m²)
    var currentMED: Double {
        syncCoordinator.todayTotalSED * SEDCalculator.joulesPerSED
    }
    
    /// 피부 타입별 일일 최대 허용량 (J/m²)
    var maxMED: Double {
        syncCoordinator.userProfile?.skinType.maxMED ?? 0
    }
    
    /// MED 진행률 (0~100+)
    var medPercentage: Double {
        syncCoordinator.todaySEDProgress * 100
    }
    
    var warningLevel: WarningLevel {
        syncCoordinator.warningLevel
    }
    
    /// SyncCoordinator 에러 (ErrorHandler 연결용)
    var syncError: AppError? {
        syncCoordinator.error
    }
    
    // MARK: - Weather Data
    
    var uvIndex: Int {
        Int(syncCoordinator.currentWeather?.currentUVIndex ?? 0)
    }
    
    var temperature: Double {
        syncCoordinator.currentWeather?.currentTemperature ?? 0
    }
    
    var locationName: String {
        syncCoordinator.currentWeather?.location.cityName ?? "—"
    }
    
    // MARK: - Sunscreen Timer
    
    var isTimerActive: Bool {
        guard let sunscreen = syncCoordinator.activeSunscreen else { return false }
        return sunscreen.isActive(at: Date())
    }
    
    func timerRemaining(at now: Date) -> String {
        guard let sunscreen = syncCoordinator.activeSunscreen,
              sunscreen.isActive(at: now)
        else {
            return "00:00"
        }
        
        let remaining = sunscreen.nextReapplyTime.timeIntervalSince(now)
        guard remaining > 0 else { return "00:00" }
        
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let seconds = Int(remaining) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Actions
    
    func onAppear() async {
        formattedDate = Date().toDayWithWeekdayString
        
        // Watch 미보유 시 선크림 타이머 카드를 기본으로
        if !hasWatch && currentPage == 0 {
            currentPage = 1
        }
        refreshWeeklyChartItemsIfNeeded()
        
        guard let lastSync = syncCoordinator.lastSyncTime else {
            await syncCoordinator.startSync()
            refreshWeeklyChartItems()
            return
        }
        
        if Date().timeIntervalSince(lastSync) > resyncInterval {
            await syncCoordinator.startSync()
            refreshWeeklyChartItems()
        }
    }
    
    func pullToRefresh() async {
        await syncCoordinator.refresh()
        refreshWeeklyChartItems()
    }
    
    // MARK: - Sunscreen Timer Actions
    
    /// 저장된 SPF로 선크림 타이머 시작
    func applySunscreen() {
        let spf = syncCoordinator.userProfile?.spfLevel ?? .spf30
        syncCoordinator.applySunscreen(spf: spf)
        Log.info("Dashboard: 선크림 도포 (SPF \(spf.displayTitle))")
    }
    
    /// 선크림 타이머 종료
    func stopSunscreen() {
        syncCoordinator.stopSunscreen()
        Log.info("Dashboard: 선크림 타이머 종료")
    }
    
    // MARK: - Weekly Chart
    
    private func refreshWeeklyChartItemsIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        
        guard let lastBuilt = lastBuiltDate,
              Calendar.current.isDate(lastBuilt, inSameDayAs: today)
        else {
            // 날짜 바뀌었거나 최초 진입 → 전체 재계산
            refreshWeeklyChartItems()
            return
        }
        
        // 같은 날이면 오늘 항목만 업데이트
        updateTodayItem()
    }
    
    private func refreshWeeklyChartItems() {
        weeklyChartItems = buildWeeklyChartItems()
        lastBuiltDate = Calendar.current.startOfDay(for: Date())
    }
    
    private func updateTodayItem() {
        guard !weeklyChartItems.isEmpty,
              let skinType = syncCoordinator.userProfile?.skinType
        else { return }
        
        let maxSED = skinType.maxDailyMEDinSED
        let percent = maxSED > 0 ? (syncCoordinator.todayTotalSED / maxSED) * 100 : 0
        let today = Calendar.current.startOfDay(for: Date())
        let minutes = localStorage.loadDailyMEDRecord(for: today)?.totalExposureMinutes ?? 0
        
        weeklyChartItems[6] = WeeklyBarItem(
            dayLabel: weeklyChartItems[6].dayLabel,
            percent: percent,
            exposureMinutes: minutes,
            isToday: true
        )
    }
    
    private func buildWeeklyChartItems() -> [WeeklyBarItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let isEnglish = Locale.current.language.languageCode?.identifier == "en"
        let daySymbols = isEnglish
        ? ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
        : ["일", "월", "화", "수", "목", "금", "토"]
        let todayLabel = isEnglish ? "TODAY" : "오늘"
        
        guard let skinType = syncCoordinator.userProfile?.skinType else {
            return (0..<7).map { offset in
                let date = calendar.date(byAdding: .day, value: offset - 6, to: today)!
                let weekday = calendar.component(.weekday, from: date) - 1
                return WeeklyBarItem(
                    dayLabel: offset == 6 ? todayLabel : daySymbols[weekday],
                    percent: 0,
                    exposureMinutes: 0,
                    isToday: offset == 6
                )
            }
        }
        
        let maxSED = skinType.maxDailyMEDinSED
        
        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset - 6, to: today)!
            let weekday = calendar.component(.weekday, from: date) - 1
            let isToday = offset == 6
            let label = isToday ? todayLabel : daySymbols[weekday]
            
            if isToday {
                let percent = maxSED > 0 ? (syncCoordinator.todayTotalSED / maxSED) * 100 : 0
                let minutes = localStorage.loadDailyMEDRecord(for: date)?.totalExposureMinutes ?? 0
                return WeeklyBarItem(dayLabel: label, percent: percent, exposureMinutes: minutes, isToday: true)
            }
            
            if let record = localStorage.loadDailyMEDRecord(for: date) {
                let percent = maxSED > 0 ? (record.totalSED / maxSED) * 100 : 0
                return WeeklyBarItem(dayLabel: label, percent: percent, exposureMinutes: record.totalExposureMinutes, isToday: false)
            }
            
            return WeeklyBarItem(dayLabel: label, percent: 0, exposureMinutes: 0, isToday: false)
        }
    }
    
    // MARK: - Debug
    
#if DEBUG
    var debugSyncCoordinator: SyncCoordinator {
        syncCoordinator
    }
#endif
}
