//
//  SPFLevel.swift
//  StopSun
//
//  Created by J on 7/22/25.
//

import Foundation

/// 선크림 자외선 차단 지수
///
/// SPF 값에 따른 자외선 차단 효과를 나타냅니다.
/// SED 계산 시 ``protectionFactor``로 나누어 실제 피부 도달량을 계산합니다.
///
/// ```swift
/// // SED 계산 공식
/// let sed = (uvIndex * minutes / 60) / spf.protectionFactor
/// ```
///
/// - Important: 선크림 효과는 도포 후 2시간까지만 유효합니다.
enum SPFLevel: Int, CaseIterable, Identifiable, Codable {
    
    /// 선크림 미사용 (protectionFactor = 1.0)
    case none = 1
    
    /// SPF 10
    case spf10 = 10
    
    /// SPF 15
    case spf15 = 15
    
    /// SPF 20
    case spf20 = 20
    
    /// SPF 25
    case spf25 = 25
    
    /// SPF 30
    case spf30 = 30
    
    /// SPF 35
    case spf35 = 35
    
    /// SPF 40
    case spf40 = 40
    
    /// SPF 45
    case spf45 = 45
    
    /// SPF 50
    case spf50 = 50
    
    /// SPF 50+ (대표값 55)
    case spf50Plus = 55
    
    var id: Int { rawValue }
    
    // MARK: - Picker Cases
    
    /// 설정 Picker에 표시할 케이스 (none 제외)
    static var pickerCases: [SPFLevel] {
        allCases.filter { $0 != .none }
    }

    // MARK: - Display
    
    /// 화면 표시용 이름 (Localized)
    var displayTitle: String {
        switch self {
        case .none: return L10n.SPF.none
        case .spf50Plus: return L10n.SPF.fiftyPlus
        default: return L10n.SPF.level(rawValue)
        }
    }
    
    // MARK: - Data Properties
    
    /// 자외선 차단 계수
    ///
    /// SED 계산 시 이 값으로 나눕니다.
    var protectionFactor: Double {
        Double(rawValue)
    }
    
    /// UV 차단율 (%)
    ///
    /// 공식: (1 - 1/SPF) × 100
    var uvBlockingPercentage: Double {
        guard self != .none else { return 0.0 }
        return (1.0 - 1.0 / Double(rawValue)) * 100.0
    }
    
    /// 권장 재도포 시간 (분)
    var recommendedReapplicationMinutes: Int {
        switch self {
        case .none: return 0
        default: return 120
        }
    }
}
