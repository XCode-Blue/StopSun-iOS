//
//  DesignSystemSampleView.swift
//  StopSun
//
//  Created by taeni on 1/8/26.
//

import SwiftUI

#if DEBUG
struct DesignSystemSampleView: View {
    
    @State private var selectedSkinType: SkinType = .type1
    @State private var isButtonEnabled = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    
                    buttonStyleSection
                    
                    Divider()
                    
                    ssButtonSection
                    
                    Divider()
                    
                    skinTypeSection
                    
                    Divider()
                    
                    l10nUsageSection
                }
                .padding(20)
            }
            .navigationTitle("Design System")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Section 1: ButtonStyle
    
    private var buttonStyleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("1. ButtonStyle (Apple 권장)")
            
            Text("Button + .buttonStyle() 조합")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Primary
            VStack(alignment: .leading, spacing: 8) {
                Text("Primary").font(.subheadline).bold()
                
                Button { } label: { Text(L10n.Button.next) }
                    .buttonStyle(.ssPrimary)
                
                Button { } label: { Text("Disabled Primary") }
                    .buttonStyle(.ssPrimary)
                    .disabled(true)
            }
            
            // Secondary
            VStack(alignment: .leading, spacing: 8) {
                Text("Secondary").font(.subheadline).bold()
                
                Button { } label: { Text(L10n.Button.cancel) }
                    .buttonStyle(.ssSecondary)
                
                Button { } label: { Text("Disabled Secondary") }
                    .buttonStyle(.ssSecondary)
                    .disabled(true)
            }
            
            // Ghost
            VStack(alignment: .leading, spacing: 8) {
                Text("Ghost").font(.subheadline).bold()
                
                Button { } label: { Text(L10n.Button.skip) }
                    .buttonStyle(.ssGhost)
            }
            
            // Custom
            VStack(alignment: .leading, spacing: 8) {
                Text("Custom Style").font(.subheadline).bold()
                
                Button { } label: { Text("Custom Background & Radius") }
                    .buttonStyle(
                        SSPrimaryButtonStyle()
                            .backgroundColor(.orange)
                            .cornerRadius(20)
                    )
            }
            
            // Toggle Test
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Button Enabled", isOn: $isButtonEnabled)
                
                Button { } label: { Text("Toggle Test Button") }
                    .buttonStyle(.ssPrimary)
                    .disabled(!isButtonEnabled)
            }
        }
    }
    
    // MARK: - Section 2: SSButton
    
    private var ssButtonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("2. SSButton (Convenience Wrapper)")
            
            Text("SSButton은 Button + ButtonStyle의 단순 래퍼입니다.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            SSButton(L10n.Button.next) {
                print("Continue tapped")
            }
            
            SSButton(L10n.Button.cancel, style: .secondary) {
                print("Cancel tapped")
            }
            
            SSButton(L10n.Button.skip, style: .ghost) {
                print("Skip tapped")
            }
        }
    }
    
    // MARK: - Section 3: SkinType
    
    private var skinTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("3. SkinType (L10n 사용)")
            
            Text("SkinType 모델이 L10n을 통해 localized 값 반환")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // 선택된 SkinType 정보
            VStack(alignment: .leading, spacing: 8) {
                Text("Selected: \(selectedSkinType.title)")
                    .font(.headline)
                
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedSkinType.color)
                        .frame(width: 40, height: 40)
                    
                    VStack(alignment: .leading) {
                        Text(selectedSkinType.summary)
                            .font(.subheadline)
                        Text(selectedSkinType.skinDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text(selectedSkinType.maxMEDFormatted)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            // SSSelectSkinButton
            Text("SSSelectSkinButton").font(.subheadline).bold()
            
            ForEach(SkinType.allCases) { type in
                SSSelectSkinButton(
                    skinType: type,
                    isSelected: selectedSkinType == type
                ) {
                    selectedSkinType = type
                }
            }
        }
    }
    
    // MARK: - Section 4: L10n Usage
    
    private var l10nUsageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("4. L10n 사용 방법")
            
            VStack(alignment: .leading, spacing: 12) {
                // 방법 1: L10n.Button
                VStack(alignment: .leading, spacing: 4) {
                    Text("L10n.Button").font(.subheadline).bold()
                    
                    Text("L10n.Button.continue")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.blue)
                    
                    Text(L10n.Button.next)
                        .padding(8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(6)
                }
                
                // 방법 2: L10n.SkinType
                VStack(alignment: .leading, spacing: 4) {
                    Text("L10n.SkinType").font(.subheadline).bold()
                    
                    Text("L10n.SkinType.title(1)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.blue)
                    
                    Text(L10n.SkinType.title(1))
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                }
                
                // 방법 3: L10n.SkinType.maxMED
                VStack(alignment: .leading, spacing: 4) {
                    Text("L10n.SkinType.maxMED (format)").font(.subheadline).bold()
                    
                    Text("L10n.SkinType.maxMED(150)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.blue)
                    
                    Text(L10n.SkinType.maxMED(150))
                        .padding(8)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(6)
                }
                
                // 방법 4: String.localized
                VStack(alignment: .leading, spacing: 4) {
                    Text("String.localized (직접 사용)").font(.subheadline).bold()
                    
                    Text("String.localized(\"onboarding.title\")")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.blue)
                    
                    Text(String.localized("onboarding.title"))
                        .padding(8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                }
            }
        }
    }
    
    // MARK: - Helper
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title2)
            .bold()
    }
}

// MARK: - Preview

#Preview("Design System Sample") {
    DesignSystemSampleView()
}

#Preview("Button Styles Only") {
    VStack(spacing: 16) {
        Button { } label: { Text(L10n.Button.next) }
            .buttonStyle(.ssPrimary)
        
        Button { } label: { Text(L10n.Button.cancel) }
            .buttonStyle(.ssSecondary)
        
        Button { } label: { Text(L10n.Button.skip) }
            .buttonStyle(.ssGhost)
        
        Button { } label: { Text("Disabled") }
            .buttonStyle(.ssPrimary)
            .disabled(true)
    }
    .padding()
}

#Preview("Skin Type Selection") {
    struct Wrapper: View {
        @State private var selected: SkinType = .type1
        
        var body: some View {
            
            ScrollView {
                VStack(spacing: 12) {
                    Text(L10n.Onboarding.title)
                        .textStyle(.B1)
                    
                    ForEach(SkinType.allCases) { type in
                        SSSelectSkinButton(
                            skinType: type,
                            isSelected: selected == type
                        ) {
                            selected = type
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    return Wrapper()
}
#endif
