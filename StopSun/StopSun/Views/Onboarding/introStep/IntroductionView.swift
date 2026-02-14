//
//  IntroductionView.swift
//  StopSun
//
//  Created by taeni on 2/10/26.
//

import SwiftUI

/// 온보딩 Introduction Phase: 서비스 설명 (3페이지)
///
/// ## 페이지 구성
/// 1. 일광 노출 추적 - Apple Watch에서 수집된 일광량을 모니터링
/// 2. 실시간 자외선 알림 - 현재 위치와 날씨 데이터 기반 알림
/// 3. 개인 맞춤 추천 - UV 지수, 날씨, 개인 활동 패턴 분석
///
/// ## UI
/// - 스와이프로 페이지 이동 가능
/// - 페이지 인디케이터 표시
/// - "다음" 버튼 (마지막 페이지에서는 "기본 설정하기")
/// - "건너뛰기" 버튼 (항상 표시)
///
struct IntroductionView: View {
    
    // MARK: - Data Down
    
    @Binding var currentPage: IntroductionPage
    let isLastPage: Bool
    let canGoBack: Bool
    
    // MARK: - Actions Up
    
    let onBack: () -> Void
    let onNext: () -> Void
    let onSkip: () -> Void
    let onStart: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            
            TabView(selection: $currentPage) {
                ForEach(IntroductionPage.allCases, id: \.self) { page in
                    IntroductionPageView(page: page)
                        .tag(page)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)
            
            pageIndicator
                .padding(.bottom, 24)
            
            buttonSection
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
        }
    }
    
    // MARK: - Navigation Bar
    
    private var navigationBar: some View {
        HStack {
            if canGoBack {
                Button {
                    onBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.text00)
                }
            }
            Spacer()
        }
        .frame(height: 44)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Page Indicator
    
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(IntroductionPage.allCases, id: \.self) { page in
                Circle()
                    .fill(page == currentPage ? Color.key00 : Color.gray00)
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }
    
    // MARK: - Buttons
    
    private var buttonSection: some View {
        VStack(spacing: 12) {
            if isLastPage {
                SSButton(L10n.Onboarding.Introduction.startSetup, style: .primary) {
                    onStart()
                }
            } else {
                SSButton(L10n.Button.next, style: .primary) {
                    onNext()
                }
                Button {
                    onSkip()
                } label: {
                    Text(L10n.Button.skip)
                        .font(.ssFont(.R2))
                        .foregroundStyle(Color.text01)
                }
            }
        }
    }
}

// MARK: - Introduction Page View

/// 개별 서비스 설명 페이지
private struct IntroductionPageView: View {
    
    let page: IntroductionPage
    
    var body: some View {
        VStack(spacing: 0) {
            titleSection
                .padding(.top, 32)
                .padding(.horizontal, 20)
            
            Spacer()
            
            imageSection
            
            Spacer()
        }
    }
    
    // MARK: - Title
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(page.title)
                .font(.ssFont(.B2))
                .foregroundStyle(Color.text00)
            
            Text(page.subtitle)
                .font(.ssFont(.R3))
                .foregroundStyle(Color.text01)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Image
    
    @ViewBuilder
    private var imageSection: some View {
        if page == .personalRecommend {
            IntroductionAnimatedGaugeView()
                .padding(.horizontal, 40)
        } else {
            Image(page.imageResource)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
        }
    }
    
}

// MARK: - IntroductionPage Extension

extension IntroductionPage {
    
    var title: String {
        switch self {
        case .trackExposure:
            return L10n.Onboarding.Introduction.TrackExposure.title
        case .realTimeAlert:
            return L10n.Onboarding.Introduction.RealTimeAlert.title
        case .personalRecommend:
            return L10n.Onboarding.Introduction.PersonalRecommend.title
        }
    }
    
    var subtitle: String {
        switch self {
        case .trackExposure:
            return L10n.Onboarding.Introduction.TrackExposure.subtitle
        case .realTimeAlert:
            return L10n.Onboarding.Introduction.RealTimeAlert.subtitle
        case .personalRecommend:
            return L10n.Onboarding.Introduction.PersonalRecommend.subtitle
        }
    }
    
    var imageResource: ImageResource {
        switch self {
        case .trackExposure:
            return .imgOnboardingExpalin1
        case .realTimeAlert:
            return .imgOnboardingExplain2
        case .personalRecommend:
            return .imgOnboardingExplain30
        }
    }
}

// MARK: - Preview

#Preview("Introduction") {
    @Previewable @State var currentPage: IntroductionPage = .trackExposure
    
    IntroductionView(
        currentPage: $currentPage,
        isLastPage: false,
        canGoBack: false,
        onBack: {},
        onNext: {},
        onSkip: {},
        onStart: {}
    )
}
