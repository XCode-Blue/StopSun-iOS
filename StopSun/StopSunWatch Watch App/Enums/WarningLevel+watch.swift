//
//  WarningLevel+watch.swift
//  StopSunWatch Watch App
//
//  Created by J on 2/26/26.
//

import Foundation
import SwiftUI

/// Watch 화면용 WarningLevel 확장
extension WarningLevel {
    
    /// MED 화면 배경 그라데이션
    ///
    /// 시안 기준:
    /// - safe: 짙은 네이비 → 검정
    /// - caution: 짙은 앰버 → 검정
    /// - warning: 짙은 빨강 → 검정
    /// - danger: 매우 짙은 빨강 → 검정
    var watchBackground: LinearGradient {
        let startColor: Color = switch self {
        case .safe:    .medBg00
        case .caution: .medBg01
        case .warning: .medBg02
        case .danger:  .medBg03
        }
        
        return LinearGradient(
            colors: [startColor, .medBgBase],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    
    var watchText: Color {
        switch self {
        case .safe:    Color(red: 0.0, green: 0.533, blue: 1.0)       // #0088FF
        case .caution: Color(red: 0.863, green: 0.208, blue: 0.008)   // #DC3502
        case .warning: Color(red: 0.851, green: 0.0, blue: 0.0)       // #D90000
        case .danger:  Color(red: 0.851, green: 0.0, blue: 0.0)       // #D90000
        }
    }
}
