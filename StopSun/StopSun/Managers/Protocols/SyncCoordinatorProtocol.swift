//
//  SyncCoordinatorProtocol.swift
//  StopSun
//
//  Created by J on 1/26/26.
//

import Foundation

/// 데이터 동기화 조율 프로토콜
///
/// HealthKit, Weather, Storage 간의 데이터 흐름을 조율합니다.
///
/// ## 핵심 기능
/// - HealthKit 데이터 수신 및 처리
/// - SED/MED 계산
/// - 선크림 도포 관리
///
/// ## 데이터 흐름
/// ```
/// HealthKit (TimeInDaylight)
///     ↓
/// + LocationRecord (과거 위치)
/// + WeatherAPI (과거 UV)
/// + SunscreenApplication (과거 SPF)
///     ↓
/// UVExposureRecord 생성 & 저장
///     ↓
/// DailyMEDRecord 업데이트
/// ```
///
@MainActor
protocol SyncCoordinatorProtocol {
    
    // MARK: - Published Properties
    
    /// 사용자 프로필
    var userProfile: UserProfile? { get }
    
    /// 오늘의 총 SED
    var todayTotalSED: Double { get }
    
    /// 현재 날씨 정보
    var currentWeather: LocationWeather? { get }
    
    /// 현재 유효한 선크림 기록
    var activeSunscreen: SunscreenApplication? { get }
    
    // MARK: - Sync
    
    /// 동기화 시작
    /// 
    /// 앱 시작 시 호출. 권한 확인 후 데이터 로드
    /// - Note: 권한 요청은 온보딩/PermissionManager가 담당
    func startSync() async
    
    /// 수동 새로고침
    func refresh() async
    
    // MARK: - User Actions
    
    /// 선크림 도포 기록 및 타이머 시작
    ///
    /// - Parameter spf: 사용한 SPF
    func applySunscreen(spf: SPFLevel)
    
    /// 선크림 타이머 종료
    ///
    /// 알림 취소, LiveActivity 종료
    func stopSunscreen()
    
    /// 피부 타입 변경
    ///
    /// - Parameter skinType: 새 피부 타입
    func updateSkinType(_ skinType: SkinType)
    
    /// 선호 SPF 변경
    ///
    /// - Parameter spfLevel: 새 SPF 레벨
    func updateSunScreenSPF(_ spfLevel: SPFLevel)
}
