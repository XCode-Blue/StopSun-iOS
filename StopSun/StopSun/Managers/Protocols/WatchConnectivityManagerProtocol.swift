//
//  WatchConnectivityManagerProtocol.swift
//  StopSun
//
//  Created by J on 1/26/26.
//

import Foundation

/// Watch Connectivity 관리 프로토콜
///
/// iPhone ↔ Apple Watch 간 데이터 동기화를 관리합니다.
///
/// ## 동기화 데이터
/// - 사용자 프로필
/// - 선크림 도포 기록
/// - 현재 MED 상태
/// - 대시보드 데이터 (날씨, UV, SED)
///
protocol WatchConnectivityManagerProtocol: AnyObject {

    // MARK: - State

    /// Watch 페어링 상태
    var isPaired: Bool { get }
    
    /// Watch 연결 상태
    var isReachable: Bool { get }

    // MARK: - Callbacks

    /// 메시지 수신 콜백
    var onMessageReceived: (([String: Any]) -> Void)? { get set }

    /// UserInfo 수신 콜백
    var onUserInfoReceived: (([String: Any]) -> Void)? { get set }

    // MARK: - Session

    /// Watch Connectivity 세션 활성화
    func activate()

    // MARK: - Domain Methods

    /// 사용자 프로필 전송
    func sendUserProfile(_ profile: UserProfile)

    /// 선크림 도포 기록 전송
    func sendSunscreenApplication(_ application: SunscreenApplication)

    /// 현재 MED 상태 전송
    ///
    /// - Parameters:
    ///   - totalSED: 누적 SED
    ///   - maxMED: 최대 MED (피부 타입 기준)
    func sendMEDStatus(totalSED: Double, maxMED: Double)

    // MARK: - Generic Methods

    /// 즉시 메시지 전송 (양방향 통신)
    ///
    /// - Parameters:
    ///   - message: 전송할 데이터 딕셔너리
    ///   - replyHandler: 응답 수신 핸들러
    ///   - errorHandler: 에러 핸들러
    func sendMessage(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)?,
        errorHandler: ((Error) -> Void)?
    )

    /// 백그라운드 데이터 전송 (UserInfo)
    ///
    /// - Parameter userInfo: 전송할 데이터 딕셔너리
    func transferUserInfo(_ userInfo: [String: Any])

    /// Application Context 업데이트 (최신 상태만 유지)
    ///
    /// - Parameter context: 애플리케이션 컨텍스트 딕셔너리
    func updateApplicationContext(_ context: [String: Any]) throws
}
