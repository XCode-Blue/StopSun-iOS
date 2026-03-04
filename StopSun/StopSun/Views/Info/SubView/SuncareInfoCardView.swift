//
//  SuncareInfoCardView.swift
//  StopSun
//
//  Created by taeni on 3/2/26.
//

import SwiftUI

/// 정보 아티클 카드
///
/// ## 레이아웃
/// ```
/// ┌─────────────────────────────┐
/// │      썸네일 이미지 영역        │
/// ├─────────────────────────────┤
/// │ [카테고리 뱃지]               │
/// │ 제목 (SB3)                   │
/// │ 부제 (R3, 2줄 제한)           │
/// └─────────────────────────────┘
/// ```
///
struct SuncareInfoCardView: View {
    
    let article: SuncareInfoArticle
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            thumbnailSection
            textSection
        }
        .background(Color.white00)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Thumbnail
    
    private var thumbnailSection: some View {
        Image(article.thumbnail)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .clipped()
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 20,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 20
                )
            )
    }
    
    // MARK: - Text Content
    
    private var textSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            categoryBadge
            
            Text(article.title)
                .font(.ssFont(.SB2))
                .foregroundStyle(Color.text00)
                .lineLimit(2)
            
            Text(subtitle)
                .font(.ssFont(.R2))
                .foregroundStyle(Color.text04)
                .lineLimit(2)
        }
        .padding(16)
    }
    
    // MARK: - Category Badge
    
    private var categoryBadge: some View {
        Text(article.category)
            .font(.ssFont(.SB1))
            .foregroundStyle(Color.key00)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.key00.opacity(0.1))
            )
    }
    
    // MARK: - Computed
    
    /// 본문 첫 문단에서 부제 추출
    private var subtitle: String {
        article.paragraphs.first ?? ""
    }
}

// MARK: - Preview

#Preview("Info Card") {
    SuncareInfoCardView(
        article: SuncareInfoArticle(
            id: 1,
            thumbnail: "info1",
            category: "피부",
            title: "피츠패트릭이란 무엇일까요?",
            content: "피츠패트릭을 왜 알아야하고,\n또 멜라닌은 우리 피부에 어떤 영향을 미치는걸까요?\n\n자세한 내용은 본문을 확인하세요."
        )
    )
    .padding(20)
    .background(Color.white01)
}
