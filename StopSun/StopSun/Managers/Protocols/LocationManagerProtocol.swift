//
//  LocationManagerProtocol.swift
//  StopSun
//
//  Created by J on 1/26/26.
//

import Foundation

/// 위치 관리 프로토콜
///
/// CoreLocation을 통해 현재 위치를 조회하고
/// Significant Location Changes를 모니터링합니다.
///
/// ## 주요 기능
/// - 위치 권한 요청
/// - 현재 위치 조회
/// - 백그라운드 위치 변경 감지
///
protocol LocationManagerProtocol {
    
    /// 권한 허용 여부
    var isAuthorized: Bool { get }
    
    /// 권한 명시적 거부 여부
    var isDenied: Bool { get }
    
    /// 위치 권한 요청
    func requestAuthorization() async
    
    /// 현재 위치 조회
    ///
    /// - Returns: 현재 위치 정보 (도시 이름 포함)
    func getCurrentLocation() async throws -> LocationInfo
    
    /// Significant Location Changes 모니터링 시작
    ///
    /// 백그라운드에서 위치 변경 감지 시 LocationRecord 저장용
    func startMonitoringSignificantLocationChanges()
    
    /// Significant Location Changes 모니터링 중지
    func stopMonitoringSignificantLocationChanges()
}
