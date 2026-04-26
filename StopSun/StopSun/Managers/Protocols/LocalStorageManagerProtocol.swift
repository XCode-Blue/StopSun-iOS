//
//  LocalStorageManagerProtocol.swift
//  StopSun
//
//  Created by J on 1/26/26.
//

import Foundation

/// 로컬 저장소 관리 프로토콜
///
/// UserDefaults를 통해 앱 데이터를 저장/조회합니다.
///
/// ## 저장 데이터
/// | 키 | 모델 | 보관 |
/// |----|------|----------|
/// | userProfile | UserProfile | ⭕️ |
/// | sunscreenHistory | [SunscreenApplication] | ⭕️ |
/// | locationHistory | [LocationRecord] | ⭕️ |
/// | exposures.{date} | [UVExposureRecord] | ⭕️ |
/// | dailyMED.{date} | DailyMEDRecord | ⭕️ |
///
protocol LocalStorageManagerProtocol {
    
    // MARK: - UserProfile
    
    /// 사용자 프로필 로드
    func loadUserProfile() -> UserProfile?
    
    /// 사용자 프로필 로드 (없으면 기본값 반환)
    func loadUserProfileOrDefault() -> UserProfile
    
    /// 사용자 프로필 저장
    func saveUserProfile(_ profile: UserProfile)
    
    /// 피부 타입 업데이트
    ///
    /// - Parameter skinType: 새 피부 타입
    /// - Note: 내부에서 NotificationCenter.post 호출
    func updateSkinType(_ skinType: SkinType)
    
    /// 선크림 SPF 업데이트
    ///
    /// - Parameter spfLevel: 새 SPF 레벨
    /// - Note: 내부에서 NotificationCenter.post 호출
    func updateSunscreenSPF(_ spfLevel: SPFLevel)
    
    /// Apple Watch 연동 상태 업데이트
    ///
    /// - Parameter isPaired: Watch 페어링 여부
    func updateHasWatch(_ isPaired: Bool)
    
    /// 선크림 수동 종료 시각 저장
    ///
    /// `loadActiveSunscreen()`에서 이 시각 이전에 도포된 기록을 제외합니다.
    /// `applySunscreen()` 호출 시 초기화되어 새 도포가 정상 활성화됩니다.
    func saveManualSunscreenStopTime(_ date: Date)
    
    /// 선크림 수동 종료 시각 조회
    func loadManualSunscreenStopTime() -> Date?
    
    /// 선크림 수동 종료 시각 초기화
    func clearManualSunscreenStopTime()
    
    /// 사용자 프로필 삭제
    func deleteUserProfile()
    
    /// 온보딩 완료 상태 저장
    func saveOnboardingCompleted(_ isCompleted: Bool)
    
    /// 온보딩 완료 상태 조회
    func loadOnboardingCompleted() -> Bool
    
    /// 첫 실행 여부 확인
    func checkIsFirstLaunch() -> Bool
    
    // MARK: - SunscreenApplication
    
    /// 선크림 기록 히스토리 로드
    func loadSunscreenHistory() -> [SunscreenApplication]
    
    /// 현재 선크림 로드 (가장 최근 기록)
    func loadCurrentSunscreen() -> SunscreenApplication?
    
    /// 선크림 기록 저장
    func saveSunscreenApplication(_ application: SunscreenApplication)
    
    /// 선크림 기록 삭제
    func deleteSunscreen()
    
    /// 선크림이 활성 상태인지 확인
    func isSunscreenActive() -> Bool
    
    /// 선크림 만료까지 남은 시간 (분)
    func loadSunscreenRemainingMinutes() -> Int
    
    /// 특정 시점에 유효한 SPF 조회
    ///
    /// - Parameter date: 조회할 시점
    /// - Returns: 해당 시점에 유효한 SPFLevel (없으면 .none)
    func getActiveSPF(at date: Date) -> SPFLevel
    
    // MARK: - LocationRecord
    
    /// 위치 히스토리 로드
    func loadLocationHistory() -> [LocationRecord]
    
    /// 위치 기록 저장
    func saveLocationRecord(_ record: LocationRecord)
    
    /// 특정 시점의 위치 조회
    ///
    /// - Parameter date: 조회할 시점
    /// - Returns: ±10분 이내 가장 마지막 위치 기록
    func getLocation(at date: Date) -> LocationRecord?
    
    // MARK: - UVExposureRecord
    
    /// 특정 날짜의 노출 기록 로드
    func loadExposureRecords(for date: Date) -> [UVExposureRecord]
    
    /// 노출 기록 저장
    func saveExposureRecord(_ record: UVExposureRecord)
    
    /// 이미 처리된 HealthKit ID인지 확인
    func isProcessed(healthKitID: UUID) -> Bool
    
    // MARK: - DailyMEDRecord
    
    /// 특정 날짜의 일일 MED 기록 로드
    func loadDailyMEDRecord(for date: Date) -> DailyMEDRecord?
    
    /// 일일 MED 기록 저장
    func saveDailyMEDRecord(_ record: DailyMEDRecord)
    
    // MARK: - Cleanup
    
    /// 오래된 데이터 정리
    func cleanupOldData()
}
