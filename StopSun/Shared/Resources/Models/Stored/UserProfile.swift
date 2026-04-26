//
//  UserProfile.swift
//  TarTanning
//
//  Created by Jun on 7/14/25.
//

import Foundation

/// 사용자 프로필
///
/// 피부 타입과 선호 SPF 설정을 저장합니다.
///
/// ## 저장 정보
/// - 저장 위치: UserDefaults
/// - 저장 키: `stopsun.userProfile`
///
/// ```swift
/// let profile = UserProfile(skinType: .type2, preferredSPF: .spf30)
/// let maxMED = profile.skinType.maxDailyMEDinSED  // 2.5 SED
/// ```
///
struct UserProfile: Codable, Equatable {
    
    /// 고유 식별자
    let id: UUID
    
    /// 피부 타입
    ///
    /// MED 한계치 계산에 사용됩니다.
    var skinType: SkinType
    
    /// 선호 SPF
    ///
    /// 선크림 도포 시 기본 선택값입니다.
    var spfLevel: SPFLevel

    /// Apple Watch 보유 여부
    ///
    /// `false`인 경우 Watch 자동 추적 대신
    /// iPhone 수동 선크림 타이머 모드로 동작합니다.
    var hasWatch: Bool

    /// 프로필 생성 일시
    let createdAt: Date

    init(
        id: UUID = UUID(),
        skinType: SkinType,
        spfLevel: SPFLevel = .spf30,
        hasWatch: Bool = true,
        createdAt: Date = Date()) {
        self.id = id
        self.skinType = skinType
        self.spfLevel = spfLevel
        self.hasWatch = hasWatch
        self.createdAt = createdAt
    }
}

// MARK: - Codable (하위 호환)

extension UserProfile {

    enum CodingKeys: String, CodingKey {
        case id, skinType, spfLevel, hasWatch, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        skinType = try container.decode(SkinType.self, forKey: .skinType)
        spfLevel = try container.decode(SPFLevel.self, forKey: .spfLevel)
        hasWatch = try container.decodeIfPresent(Bool.self, forKey: .hasWatch) ?? true
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}

// MARK: - Mock

extension UserProfile {
    static let mockUser = UserProfile(skinType: .type3, spfLevel: .spf30)
    
    /// 기본 사용자 프로필 (온보딩 완료 전)
    static let defaultUser = UserProfile(skinType: .type3, spfLevel: .spf30)
}
