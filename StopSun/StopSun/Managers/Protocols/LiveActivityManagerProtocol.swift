//
//  LiveActivityManagerProtocol.swift
//  StopSun
//
//  Created by donghee on 2/25/26.
//

import Foundation

/// Live Activity 관리 프로토콜
///
/// 선크림 타이머 Live Activity의 시작, 업데이트, 종료를 관리합니다.
///
/// ## 라이프사이클
/// 1. `startActivity` — 선크림 도포 시 호출
/// 2. `updateWarningLevel` — 경고 레벨 변경 시 호출
/// 3. `endActivity` — 타이머 만료 또는 수동 종료 시 호출
///
@MainActor
protocol LiveActivityManagerProtocol: AnyObject {

    /// Live Activity가 현재 활성 상태인지
    var isActivityActive: Bool { get }

    /// Live Activity 시작
    ///
    /// - Parameters:
    ///   - appliedAt: `SunscreenApplication.appliedAt`
    ///   - reapplyAt: `SunscreenApplication.nextReapplyTime`
    ///   - spfDisplayTitle: `SPFLevel.displayTitle`
    ///   - warningLevel: 현재 경고 레벨
    ///   - progress: SED 진행률 (0.0 ~ 1.0+)
    func startActivity(
        appliedAt: Date,
        reapplyAt: Date,
        spfDisplayTitle: String,
        warningLevel: WarningLevel,
        progress: Double
    )

    /// 경고 레벨 및 진행률 업데이트
    ///
    /// - Parameters:
    ///   - warningLevel: 새로운 경고 레벨
    ///   - progress: SED 진행률 (0.0 ~ 1.0+)
    func updateWarningLevel(_ warningLevel: WarningLevel, progress: Double)

    /// Live Activity 종료
    func endActivity()
}
