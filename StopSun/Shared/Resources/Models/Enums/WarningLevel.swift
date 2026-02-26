//
//  WarningLevel.swift
//  StopSun
//
//  Created by J on 2/8/26.
//

import SwiftUI

/// SED/MED 진행률 기반 경고 레벨
///
/// 일일 권장 자외선 노출량 대비 현재 진행률에 따른 경고 단계입니다.
///
/// ## 경고 단계
///
/// | 레벨 | 진행률 | 퍼센트 | 권장 행동 |
/// |------|--------|--------|----------|
/// | safe | 0~0.3 | 0~30% | 정상 활동 |
/// | caution | 0.3~0.5 | 30~50% | 선크림 확인 |
/// | warning | 0.5~0.7 | 50~70% | 그늘 권장 |
/// | danger | 0.7+ | 70%+ | 실내 이동 |
///
/// ## 사용 예시
///
/// ```swift
/// // progress 기반 (0.0 ~ 1.0+)
/// let level = WarningLevel.from(progress: 0.6)  // .warning
///
/// // percentage 기반 (0 ~ 100+)
/// let level = WarningLevel.fromPercentage(73)    // .danger
///
/// // UI에서 사용
/// Text(level.statusTitle)
///     .foregroundStyle(level.color)
/// ```
///
enum WarningLevel: String, CaseIterable, Sendable, Equatable {
    
    /// 0~30%: 안전
    case safe
    
    /// 30~50%: 주의
    case caution
    
    /// 50~70%: 경고
    case warning
    
    /// 70%+: 위험
    case danger
    
    // MARK: - Factory
    
    /// 진행률로부터 경고 레벨 생성
    ///
    /// - Parameter progress: SED 진행률 (0.0 ~ 1.0+)
    /// - Returns: 해당하는 경고 레벨
    ///
    /// ```swift
    /// WarningLevel.from(progress: 0.2)  // .safe
    /// WarningLevel.from(progress: 0.4)  // .caution
    /// WarningLevel.from(progress: 0.6)  // .warning
    /// WarningLevel.from(progress: 0.85) // .danger
    /// ```
    static func from(progress: Double) -> WarningLevel {
        switch progress {
        case ..<0.3:
            return .safe
        case 0.3..<0.5:
            return .caution
        case 0.5..<0.7:
            return .warning
        default:
            return .danger
        }
    }
    
    /// 퍼센트 값으로부터 경고 레벨 생성
    ///
    /// - Parameter percentage: MED 누적 퍼센트 (0 ~ 100+)
    /// - Returns: 해당하는 경고 레벨
    ///
    /// ```swift
    /// WarningLevel.fromPercentage(10)   // .safe
    /// WarningLevel.fromPercentage(40)   // .caution
    /// WarningLevel.fromPercentage(60)   // .warning
    /// WarningLevel.fromPercentage(85)   // .danger
    /// ```
    static func fromPercentage(_ percentage: Double) -> WarningLevel {
        from(progress: percentage / 100.0)
    }
    
    // MARK: - Display Properties
    
    /// 경고 레벨 제목 (L10n 기반)
    var title: String {
        switch self {
        case .safe:
            return L10n.MED.Status.Safe.title
        case .caution:
            return L10n.MED.Status.Caution.title
        case .warning:
            return L10n.MED.Status.Warning.title
        case .danger:
            return L10n.MED.Status.Danger.title
        }
    }
    
    /// 경고 레벨 설명 (L10n 기반)
    var statusDescription: String {
        switch self {
        case .safe:
            return L10n.MED.Status.Safe.description
        case .caution:
            return L10n.MED.Status.Caution.description
        case .warning:
            return L10n.MED.Status.Warning.description
        case .danger:
            return L10n.MED.Status.Danger.description
        }
    }
    
    /// 경고 레벨 색상
    var color: Color {
        switch self {
        case .safe: .gage00
        case .caution: .gage01
        case .warning: .gage02
        case .danger: .gage03
        }
    }
    
    // MARK: - Onboarding Demo
    
    /// 각 레벨의 대표 퍼센트 값 (온보딩 게이지 애니메이션용)
    var demoPercentage: Double {
        switch self {
        case .safe: 15
        case .caution: 40
        case .warning: 60
        case .danger: 85
        }
    }
    
    /// 다음 레벨 (온보딩 애니메이션 순환용)
    var next: WarningLevel {
        switch self {
        case .safe: .caution
        case .caution: .warning
        case .warning: .danger
        case .danger: .safe
        }
    }
    
    // MARK: - Notification Triggers
    
    /// 알림을 보내야 하는 레벨인지 확인
    var shouldNotify: Bool {
        switch self {
        case .safe:
            return false
        case .caution, .warning, .danger:
            return true
        }
    }
    
    /// 알림 우선순위 (높을수록 긴급)
    var notificationPriority: Int {
        switch self {
        case .safe: 0
        case .caution: 1
        case .warning: 2
        case .danger: 3
        }
    }
}
