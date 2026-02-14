//
//  OnboardingContainerView.swift
//  StopSun
//
//  Created by taeni on 2/8/26.
//

import SwiftUI

/// 온보딩 컨테이너 뷰
///
/// ## Phase 기반 플로우
/// ```
/// Phase.introduction (서비스 설명 1,2,3)
///     ↓ "기본 설정하기" 또는 "건너뛰기"
/// Phase.setup (워치 → 권한 → 스킨타입)
///     ↓ "시작하기"
/// 완료 → 메인 화면
/// ```
///
struct OnboardingContainerView: View {
    
    @State private var viewModel: OnboardingViewModel
    
    // MARK: - Initializer
    
    /// 기본 생성자 — `DIContainer.shared`에서 ViewModel 생성
    init() {
        _viewModel = State(wrappedValue: DIContainer.shared.makeOnboardingViewModel())
    }
    
    /// Preview / 테스트용 생성자 — ViewModel 직접 주입
    init(viewModel: OnboardingViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    
    var body: some View {
        @Bindable var vm = viewModel
        
        Group {
            switch viewModel.currentPhase {
            case .introduction:
                IntroductionView(
                    currentPage: $vm.currentIntroPage,
                    isLastPage: viewModel.isLastIntroPage,
                    canGoBack: viewModel.canGoBackInIntro,
                    onBack: { viewModel.moveToPreviousIntroPage() },
                    onNext: { viewModel.moveToNextIntroPage() },
                    onSkip: { viewModel.startSetupPhase() },
                    onStart: { viewModel.startSetupPhase() }
                )
                
            case .setup:
                setupPhaseContent(vm: $vm)
            }
        }
        .background(Color.white00)
    }
    
    // MARK: - Setup Phase Content
    
    private func setupPhaseContent(vm: Bindable<OnboardingViewModel>) -> some View {
        VStack(spacing: 0) {
            setupNavigationBar
            setupProgressBar
            setupStepContent(vm: vm)
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentSetupStep)
        }
    }
    
    // MARK: - Setup Navigation Bar
    
    private var setupNavigationBar: some View {
        HStack {
            Button {
                viewModel.backFromSetup()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.text00)
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .frame(height: 44)
    }
    
    // MARK: - Setup Progress Bar
    
    private var setupProgressBar: some View {
        HStack(spacing: 5) {
            ForEach(SetupStep.allCases, id: \.rawValue) { step in
                RoundedRectangle(cornerRadius: 2)
                    .fill(step.rawValue <= viewModel.currentSetupStep.rawValue
                          ? Color.key00
                          : Color.gray00)
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentSetupStep)
            }
        }
        .padding(.top, 32)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Setup Step Content
    
    /// Setup 단계별 뷰 (스와이프 차단을 위해 TabView 미사용)
    @ViewBuilder
    private func setupStepContent(vm: Bindable<OnboardingViewModel>) -> some View {
        switch viewModel.currentSetupStep {
        case .watchCheck:
            OnboardingWatchCheckView(
                alertType: viewModel.watchAlertType,
                showAlert: vm.showWatchAlert,
                onHasWatch: { viewModel.handleHasWatch() },
                onNoWatch: { viewModel.handleNoWatch() }
            )
            .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            ))
            
        case .permission:
            OnboardingPermissionView(
                isRequesting: viewModel.isRequesting,
                onContinue: {
                    Task { await viewModel.handleRequestPermissions() }
                }
            )
            .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            ))
            
        case .skinType:
            OnboardingSkinTypeView(
                selectedSkinType: viewModel.selectedSkinType,
                onSelectSkinType: { viewModel.selectSkinType($0) },
                onStart: { viewModel.completeOnboarding() }
            )
            .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            ))
        }
    }
}

// MARK: - Preview

#Preview("Onboarding - Introduction") {
    let vm = DIContainer.preview.makeOnboardingViewModel()
    OnboardingContainerView(viewModel: vm)
}

#Preview("Onboarding - Setup") {
    let vm = DIContainer.preview.makeOnboardingViewModel()
    vm.currentPhase = .setup
    return OnboardingContainerView(viewModel: vm)
}
