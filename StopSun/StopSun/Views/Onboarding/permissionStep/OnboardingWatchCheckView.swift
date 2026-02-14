//
//  OnboardingWatchCheckView.swift
//  StopSun
//
//  Created by taeni on 2/8/26.
//

import SwiftUI

/// 온보딩 Step 1: Apple Watch 보유 여부 확인
///
/// ## 분기
/// - "네, 보유 중이에요" → `WCSession.isPaired` 확인
///   - 페어링됨 → Step 2 이동
///   - 미감지 → Alert "기기 모델을 확인해주세요"
/// - "아니오, 없어요" → Alert "Apple Watch 보유를 권장해요!" (진행 차단)
///
struct OnboardingWatchCheckView: View {
    
    // MARK: - Data Down
    
    let alertType: WatchAlertType
    @Binding var showAlert: Bool
    
    // MARK: - Actions Up
    
    let onHasWatch: () -> Void
    let onNoWatch: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            titleSection
                .padding(.top, 32)
                .padding(.horizontal, 20)
            
            Spacer()
            
            Image(.imgOnboardingWatch)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                
            Spacer()
            
            buttonSection
                .padding(.horizontal, 20)
        }
        .padding(.bottom, 40)
        .alert(isPresented: $showAlert) {
            watchAlert
        }
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Onboarding.Watch.title)
                .font(.ssFont(.B2))
                .foregroundStyle(Color.text00)
                .multilineTextAlignment(.leading)
            
            Text(L10n.Onboarding.Watch.subtitle)
                .font(.ssFont(.R3))
                .foregroundStyle(Color.text01)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Buttons
    
    private var buttonSection: some View {
        HStack(spacing: 12) {
            SSButton(L10n.Onboarding.Watch.noWatch, style: .notAllowed) {
                onNoWatch()
            }
            SSButton(L10n.Onboarding.Watch.hasWatch, style: .primary) {
                onHasWatch()
            }
        }
    }
    
    // MARK: - Alert
    
    private var watchAlert: Alert {
        switch alertType {
        case .noWatch:
            Alert(
                title: Text(L10n.Onboarding.Watch.Alert.noWatchTitle),
                message: Text(L10n.Onboarding.Watch.Alert.noWatchMessage),
                dismissButton: .default(Text(L10n.Button.confirm))
            )
        case .notPaired:
            Alert(
                title: Text(L10n.Onboarding.Watch.Alert.notPairedTitle),
                message: Text(L10n.Onboarding.Watch.Alert.notPairedMessage),
                dismissButton: .default(Text(L10n.Button.confirm))
            )
        }
    }
}

// MARK: - Preview

#Preview("Step 1: Watch Check") {
    @Previewable @State var showAlert = false
    
    OnboardingWatchCheckView(
        alertType: .noWatch,
        showAlert: $showAlert,
        onHasWatch: {},
        onNoWatch: { showAlert = true }
    )
}
