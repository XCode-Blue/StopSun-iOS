//
//  SunscreenTimerAttributes.swift
//  StopSun
//
//  Created by donghee on 2/25/26.
//

import Foundation

#if canImport(ActivityKit)
import ActivityKit

/// 선크림 타이머 Live Activity 데이터 모델
///
/// `SunscreenApplication`과 `WarningLevel`의 값을 ActivityKit 형식으로 래핑합니다.
///
/// ## Static Data (Activity 생애 동안 변경 불가)
/// - `appliedAt`: `SunscreenApplication.appliedAt`
/// - `reapplyAt`: `SunscreenApplication.nextReapplyTime`
/// - `spfDisplayTitle`: `SPFLevel.displayTitle`
///
/// ## Dynamic Data (ContentState, 업데이트 가능)
/// - `warningLevelRawValue`: `WarningLevel.rawValue`
///
struct SunscreenTimerAttributes: ActivityAttributes {

    /// 동적 상태 (업데이트 가능)
    struct ContentState: Codable, Hashable {
        /// 현재 경고 레벨 (`WarningLevel.rawValue`)
        let warningLevelRawValue: String
        /// SED 진행률 (0.0 ~ 1.0+), 배너 바 너비에 사용
        let progress: Double
    }

    // MARK: - Static Properties

    /// 선크림 도포 시각 (`SunscreenApplication.appliedAt`)
    let appliedAt: Date

    /// 재도포 예정 시각 (`SunscreenApplication.nextReapplyTime`)
    let reapplyAt: Date

    /// SPF 표시 문자열 (`SPFLevel.displayTitle`)
    let spfDisplayTitle: String
}
#endif
