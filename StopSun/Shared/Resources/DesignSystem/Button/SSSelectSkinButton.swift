//
//  SSSelectSkinButton.swift
//  StopSun
//
//  Created by taeni on 1/9/26.
//

import SwiftUI

struct SSSelectSkinButton: View {
    
    let skinType: SkinType
    let isSelected: Bool
    let action: () -> Void
    
    // MARK: - Initializer
    
    init(
        skinType: SkinType,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) {
        self.skinType = skinType
        self.isSelected = isSelected
        self.action = action
    }

    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 16) {
                colorIndicator
                textContent
                Spacer()
            }
            .padding(20)
            .background(isSelected ? Color.white00 : Color.white01)
            .cornerRadius(12)
            .overlay(selectionBorder)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(skinType.title)
        .accessibilityHint(skinType.summary)
    }
    
    // MARK: - Subviews
    
    private var colorIndicator: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(skinType.color)
            .frame(width: 48, height: 48)
    }
    
    private var textContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(skinType.title)
                .font(.ssFont(.SB2))
                .foregroundStyle(Color.text00)
            
            Text(skinType.fullDescription)
                .font(.ssFont(.R2))
                .foregroundStyle(Color.text01)
                .multilineTextAlignment(.leading)
        }
    }
    
    private var selectionBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(
                isSelected ? Color.key00 : Color.clear,
                lineWidth: 1.5
            )
    }
}

// MARK: - Preview

#Preview("Skin Type Selection") {
    struct PreviewWrapper: View {
        @State private var selectedType: SkinType = .type1
        
        var body: some View {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(SkinType.allCases) { type in
                        SSSelectSkinButton(
                            skinType: type,
                            isSelected: selectedType == type
                        ) {
                            selectedType = type
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    return PreviewWrapper()
}
