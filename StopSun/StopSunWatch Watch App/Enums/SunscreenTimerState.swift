//
//  SunscreenTimerState.swift
//  StopSunWatch Watch App
//
//  Created by J on 2/26/26.
//

import SwiftUI

/// 선크림 타이머 상태
enum SunscreenTimerState {
    case idle
    case active
    case expired
    
    /// 상태별 배경 그라데이션
    var gradient: LinearGradient {
        let colors: [Color] = switch self {
        case .idle:    [.timerBgIdle00, .timerBgIdle01]
        case .active:  [.timerBgActive00, .timerBgActive01]
        case .expired: [.timerBgExpired00, .timerBgExpired01]
        }
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
