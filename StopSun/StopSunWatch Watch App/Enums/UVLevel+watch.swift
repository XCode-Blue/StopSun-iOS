//
//  UVLevel+watch.swift
//  StopSunWatch Watch App
//
//  Created by J on 2/26/26.
//

import Foundation
import SwiftUI

/// Watch 화면용 UVLevel 확장
///
/// Watch xcassets에 등록된 색상 에셋을 사용합니다.
///
/// ## 에셋 매핑
/// - low: `uvi00` (초록)
/// - moderate: `uvi01` (파랑)
/// - high / veryHigh / extreme: `uvi02` (빨강)
///
extension UVLevel {
    
    /// UVI 화면 배경색
    var watchBackground: Color {
        switch self {
        case .low: .uvi00
        case .moderate: .uvi01
        case .high, .veryHigh, .extreme: .uvi02
        }
    }
}
