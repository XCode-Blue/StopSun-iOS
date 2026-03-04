//
//  SuncareInfoDetailView.swift
//  StopSun
//
//  Created by taeni on 3/2/26.
//

import SwiftUI

/// 정보 아티클 상세 화면
///
/// ## 레이아웃
/// ```
/// ┌──────────────────────────┐
/// │ < (뒤로)    제목 (navBar)  │
/// ├──────────────────────────┤
/// │     [히어로 이미지]        │
/// │                          │
/// │ 제목 (SB3, key00)         │
/// │                          │
/// │ 문단 1 텍스트...           │
/// │ 문단 2 텍스트...           │
/// └──────────────────────────┘
/// ```
///
struct SuncareInfoDetailView: View {
    
    // MARK: - Properties
    
    let article: SuncareInfoArticle
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                heroImage
                contentSection
            }
        }
        .background(Color.white00)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(article.title)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                backButton
            }
        }
    }
    
    // MARK: - Back Button
    
    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.text00)
        }
    }
    
    // MARK: - Hero Image
    
    private var heroImage: some View {
        Image(article.thumbnail)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 20)
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            // 섹션 제목
            Text(article.title)
                .font(.ssFont(.SB3))
                .foregroundStyle(Color.key00)
                .padding(.top, 16)
            
            // 본문 문단들
            ForEach(Array(article.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                paragraphView(paragraph)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - Paragraph Rendering
    
    @ViewBuilder
    private func paragraphView(_ text: String) -> some View {
        if text.contains("**") {
            Text(parseBoldMarkdown(text))
                .font(.ssFont(.R3))
                .foregroundStyle(Color.text00)
                .lineSpacing(6)
        } else {
            Text(text)
                .font(.ssFont(.R4))
                .foregroundStyle(Color.text00)
                .lineSpacing(6)
        }
    }
    
    private func parseBoldMarkdown(_ text: String) -> AttributedString {
        let parts = text.components(separatedBy: "**")
        
        let delimiterCount = parts.count - 1
        guard delimiterCount > 0 && delimiterCount % 2 == 0 else {
            return AttributedString(text)
        }
        
        var result = AttributedString()
        
        for (index, part) in parts.enumerated() {
            guard !part.isEmpty else { continue }
            
            var attributed = AttributedString(part)
            
            if index % 2 == 1 {
                attributed.font = .ssFont(.SB2)
                attributed.foregroundColor = Color.text00
            }
            
            result.append(attributed)
        }
        
        return result
    }
}

// MARK: - Preview

#Preview("Detail View") {
    NavigationStack {
        SuncareInfoDetailView(
            article: SuncareInfoArticle(
                id: 1,
                thumbnail: "info1",
                category: "피부",
                title: "피츠패트릭이란 무엇일까요?",
                content: "**피츠패트릭 스킨타입(Fitzpatrick Skin Type)**은 피부가 자외선(태양광)에 어떻게 반응하는가를 기준으로 6단계로 분류한 피부 유형 구분 체계예요.\n\n분류 기준은 피부색(멜라닌의 양), 햇빛 노출 시 화상(일광화상) 또는 태닝이 잘 생기는지, 유전적 특성을 종합적으로 판단합니다."
            )
        )
    }
}

