//
//  HealthKitManagerProtocol.swift
//  StopSun
//
//  Created by J on 1/26/26.
//

import Foundation

/// HealthKit 데이터 관리 프로토콜
///
/// Apple Watch의 `timeInDaylight` 데이터를 조회하고
/// Background Delivery를 통해 실시간 업데이트를 수신합니다.
///
/// ## 주요 기능
/// - 권한 요청
/// - 일광 노출 데이터 조회
/// - Background Delivery 설정
///
protocol HealthKitManagerProtocol {
    
    /// HealthKit 사용 가능 여부 (기기 지원)
    var isAvailable: Bool { get }
    
    /// 권한 요청 완료 여부
    var isAuthorized: Bool { get }
    
    /// 권한 요청
    func requestAuthorization() async throws
    
    /// 오늘의 일광 노출 데이터 조회
    ///
    /// - Returns: 오늘 기록된 TimeInDaylight 배열
    func fetchTodayTimeInDaylight() async throws -> [TimeInDaylight]
    
    /// 특정 기간의 일광 노출 데이터 조회
    ///
    /// - Parameters:
    ///   - start: 시작 날짜
    ///   - end: 종료 날짜
    /// - Returns: 해당 기간의 TimeInDaylight 배열
    func fetchTimeInDaylight(from start: Date, to end: Date) async throws -> [TimeInDaylight]
    
    /// Background Delivery 활성화
    ///
    /// 새로운 timeInDaylight 데이터가 기록되면 앱에 알림
    func enableBackgroundDelivery() async throws
    
    /// TimeInDaylight 쓰기 권한 요청
    ///
    /// 기존 읽기 권한과 함께 쓰기 권한을 요청합니다.
    /// 이미 허용된 경우 시스템이 팝업 없이 처리합니다.
    func requestWriteAuthorization() async throws
    
    /// TimeInDaylight 샘플 저장
    ///
    /// - Parameters:
    ///   - start: 일광 노출 시작 시각
    ///   - end: 일광 노출 종료 시각
    /// - Throws: `AppError.healthKit(.saveFailed)`
    func saveTimeInDaylight(start: Date, end: Date) async throws
}
