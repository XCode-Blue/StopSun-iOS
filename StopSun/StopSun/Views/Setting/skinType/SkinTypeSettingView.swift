//
//  SkinTypeSettingView.swift
//  StopSun
//
//  Created by taeni on 2/23/26.
//

import SwiftUI

/// 설정 > 피부 타입 재설정 화면
///
/// 온보딩의 `SSSelectSkinButton`을 재사용합니다.
/// 다른 타입 선택 시에만 "확인" 버튼이 활성화됩니다.
///
struct SkinTypeSettingView: View {
    
    // MARK: - State
    
    @State private var selectedSkinType: SkinType?
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Data Down
    
    let currentSkinType: SkinType
    
    // MARK: - Actions Up
    
    let onComplete: (SkinType) -> Void
    
    // MARK: - Init
    
    init(
        currentSkinType: SkinType,
        onComplete: @escaping (SkinType) -> Void
    ) {
        self.currentSkinType = currentSkinType
        self.onComplete = onComplete
        self._selectedSkinType = State(initialValue: currentSkinType)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            titleSection
                .padding(.top, 24)
            
            Spacer()
                .frame(height: 24)
            
            skinTypeList
            
            confirmButton
                .padding(.top, 20)
                .padding(.bottom, 40)
        }
        .padding(.horizontal, 20)
        .background(Color.white00)
        .navigationTitle(L10n.Settings.SkinTypeSetting.navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
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
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.text00)
        }
    }
    
    // MARK: - Title
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Settings.SkinTypeSetting.heading)
                .font(.ssFont(.B1))
                .foregroundStyle(Color.text00)
            
            Text(L10n.Settings.SkinTypeSetting.subtitle)
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
                        selectedSkinType = skinType
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }
    
    // MARK: - Confirm Button
    
    private var confirmButton: some View {
        SSButton(L10n.Button.confirm, style: .primary) {
            guard let selected = selectedSkinType else { return }
            onComplete(selected)
            dismiss()
        }
        .disabled(selectedSkinType == currentSkinType)
    }
}

// MARK: - Preview

#Preview("Skin Type Setting") {
    NavigationStack {
        SkinTypeSettingView(
            currentSkinType: .type3,
            onComplete: { _ in }
        )
    }
}
