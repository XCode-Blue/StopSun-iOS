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
    
    /// 캐싱된 날짜 문자열 (하루에 한 번만 갱신)
    private(set) var formattedDate: String = ""
    
    // MARK: - Dependencies
    
    private let syncCoordinator: SyncCoordinator
    
    /// 재sync 판단 기준 (15분)
    private let resyncInterval: TimeInterval = 15 * 60
    
    // MARK: - Initializer
    
    init(syncCoordinator: SyncCoordinator) {
        self.syncCoordinator = syncCoordinator
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
    
    // MARK: - Weekly Chart
    
    /// 주간 MED 차트 아이템
    var weeklyChartItems: [WeeklyBarItem] {
        syncCoordinator.loadWeeklyChartItems()
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
    
    /// 남은 시간 포맷 (TimelineView에서 now를 전달받아 사용)
    func timerRemaining(at now: Date) -> String {
        guard let sunscreen = syncCoordinator.activeSunscreen,
              sunscreen.isActive(at: now) else {
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
    
    /// 최초 진입 또는 포그라운드 복귀 시 호출
    func onAppear() async {
        // 날짜 갱신 (자정 지났을 때 대비)
        formattedDate = Date().toDayWithWeekdayString
        
        // 한 번도 sync 안 했으면 바로 시작
        guard let lastSync = syncCoordinator.lastSyncTime else {
            await syncCoordinator.startSync()
            return
        }
        
        // 마지막 sync로부터 15분 이상 경과했으면 재sync
        if Date().timeIntervalSince(lastSync) > resyncInterval {
            await syncCoordinator.startSync()
        }
    }
    
    // MARK: - Debug
    
#if DEBUG
    var debugSyncCoordinator: SyncCoordinator {
        syncCoordinator
    }
#endif
}
