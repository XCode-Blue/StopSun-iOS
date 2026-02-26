//
//  SunScreenManagerProtocol.swift
//  StopSun
//
//  Created by J on 2/18/26.
//

import Foundation

/// SunscreenApplication 저장/관리 프로토콜
///
/// UserDefaults 기반의 현재 활성 선크림 데이터 CRUD를 담당합니다.
///
protocol SunScreenManagerProtocol: AnyObject {
    
    /// 선크림 정보 저장
    @discardableResult
    func saveSunScreen(_ sunScreen: SunscreenApplication) -> Bool
    
    /// 저장된 선크림 정보 조회
    func fetchSunScreen() -> SunscreenApplication?
    
    /// 활성 선크림 조회 (만료 시 nil)
    func fetchActiveSunScreen() -> SunscreenApplication?
    
    /// SPF 레벨 업데이트
    @discardableResult
    func updateSPFLevel(_ spfLevel: SPFLevel) -> Bool
    
    /// 선크림 정보 삭제
    func deleteSunScreen()
    
    /// 선크림 저장 여부
    func hasSunScreen() -> Bool
    
    /// 선크림 활성 여부
    func isActive() -> Bool
    
    /// 만료까지 남은 시간 (분)
    func fetchRemainingMinutes() -> Int
}
