//
//  OnboardingSkinTypeView.swift
//  StopSun
//
//  Created by taeni on 2/8/26.
//

import SwiftUI

/// 온보딩 Step 3: 피부 타입 설정하기
///
/// `SSSelectSkinButton`으로 6개 피부 타입을 나열합니다.
/// 미선택 시 "시작하기" 버튼이 비활성화됩니다.
///
struct OnboardingSkinTypeView: View {
    
    // MARK: - Data Down
    
    let selectedSkinType: SkinType?
    
    // MARK: - Actions Up
    
    let onSelectSkinType: (SkinType) -> Void
    let onStart: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            titleSection
                .padding(.top, 32)
            
            Spacer()
                .frame(height: 24)
            
            skinTypeList
            
            startButton
                .padding(.top, 20)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
    
    // MARK: - Title
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Onboarding.SkinTypeStep.title)
                .font(.ssFont(.B2))
                .foregroundStyle(Color.text00)
            
            Text(L10n.Onboarding.SkinTypeStep.subtitle)
                .font(.ssFont(.R3))
                .foregroundStyle(Color.text01)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Skin Type List
    
    private var skinTypeList: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(SkinType.allCases) { skinType in
                    SSSelectSkinButton(
                        skinType: skinType,
                        isSelected: selectedSkinType == skinType
                    ) {
                        onSelectSkinType(skinType)
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }
    
    // MARK: - Start Button
    
    private var startButton: some View {
        SSButton(L10n.Onboarding.SkinTypeStep.startButton, style: .primary) {
            onStart()
        }
        .disabled(selectedSkinType == nil)
    }
}

// MARK: - Preview

#Preview("Step 3: Skin Type") {
    OnboardingSkinTypeView(
        selectedSkinType: .type2,
        onSelectSkinType: { _ in },
        onStart: {}
    )
}
