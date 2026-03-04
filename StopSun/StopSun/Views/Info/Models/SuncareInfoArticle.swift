//
//  SuncareInfoArticle.swift
//  StopSun
//
//  Created by taeni on 2/28/26.
//

import Foundation

// MARK: - Root Container

/// JSON 루트 컨테이너
///
/// ```json
/// { "sunscreen_info": [ ... ] }
/// ```
struct SunscareInfoResponse: Codable {
    let sunscreenInfo: [SuncareInfoArticle]
    
    enum CodingKeys: String, CodingKey {
        case sunscreenInfo = "sunscreen_info"
    }
}

// MARK: - Article Model

/// 자외선/선크림 정보 아티클
///
/// ## 프로퍼티
/// | 프로퍼티 | 설명 |
/// |---------|------|
/// | id | 고유 식별자 |
/// | thumbnail | Asset Catalog 이미지 이름 (info1~info9) |
/// | category | 카테고리 라벨 (예: "피부 건강", "자외선 지식") |
/// | title | 글 제목 |
/// | content | 본문 내용 (`\n\n`으로 문단 구분) |
///
struct SuncareInfoArticle: Codable, Identifiable, Hashable {
    let id: Int
    let thumbnail: String
    let category: String
    let title: String
    let content: String
    
    // MARK: - Hashable (id 기반)
    
    /// content가 수천 자이므로 id 기반 해싱으로 성능 확보
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Computed
    
    /// 본문을 문단 단위로 분리
    ///
    /// JSON content 필드의 `\n\n`을 기준으로 분리하며,
    /// 빈 문단은 제거됩니다.
    var paragraphs: [String] {
        content
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
