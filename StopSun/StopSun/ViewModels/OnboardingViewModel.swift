//
//  OnboardingViewModel.swift
//  StopSun
//
//  Created by taeni on 2/8/26.
//

import SwiftUI

// MARK: - OnboardingViewModel

/// 온보딩 ViewModel
///
/// ## 전체 플로우
/// ```
/// Introduction (서비스 설명 1,2,3)
///     ↓ "기본 설정하기" 또는 "건너뛰기"
/// Setup Step 1: Watch 확인
///     ↓
/// Setup Step 2: 권한 요청
///     ↓
/// Setup Step 3: 피부 타입
///     ↓
/// 완료
/// ```
///
/// ## Apple Watch 필수
/// Watch 미보유 시 진행이 차단됩니다.
@MainActor
@Observable
final class OnboardingViewModel {
    
    // MARK: - Phase & Navigation
    
    var currentPhase: OnboardingPhase = .introduction
    var currentIntroPage: IntroductionPage = .trackExposure
    var currentSetupStep: SetupStep = .watchCheck
    
    // MARK: - State
    
    var selectedSkinType: SkinType? = nil
    var isRequesting: Bool = false
    var isCompleted: Bool = false
    
    // MARK: - Alert State
    
    var showWatchAlert: Bool = false
    var watchAlertType: WatchAlertType = .noWatch
    
    // MARK: - Dependencies
    
    private let healthKit: any HealthKitManagerProtocol
    private let location: any LocationManagerProtocol
    private let notification: any NotificationManagerProtocol
    private let watchConnectivity: any WatchConnectivityManagerProtocol
    private let permissionManager: PermissionManager
    private let localStorage: any LocalStorageManagerProtocol
    
    // MARK: - Initializer
    
    init(
        healthKit: any HealthKitManagerProtocol,
        location: any LocationManagerProtocol,
        notification: any NotificationManagerProtocol,
        watchConnectivity: any WatchConnectivityManagerProtocol,
        permissionManager: PermissionManager,
        localStorage: any LocalStorageManagerProtocol
    ) {
        self.healthKit = healthKit
        self.location = location
        self.notification = notification
        self.watchConnectivity = watchConnectivity
        self.permissionManager = permissionManager
        self.localStorage = localStorage
        
        Log.debug("OnboardingViewModel 초기화")
    }
    
    // MARK: - Computed Properties (Introduction)
    
    var isLastIntroPage: Bool {
        currentIntroPage == IntroductionPage.allCases.last
    }
    
    var canGoBackInIntro: Bool {
        currentIntroPage.rawValue > 0
    }
    
    // MARK: - Computed Properties (Setup)
    
    var setupProgress: Double {
        Double(currentSetupStep.rawValue + 1) / Double(SetupStep.allCases.count)
    }
    
    var canGoBackInSetup: Bool {
        currentSetupStep.rawValue > 0
    }
    
    // MARK: - Introduction Navigation
    
    func moveToPreviousIntroPage() {
        guard let prev = IntroductionPage(rawValue: currentIntroPage.rawValue - 1) else { return }
        currentIntroPage = prev
    }
    
    func moveToNextIntroPage() {
        guard let next = IntroductionPage(rawValue: currentIntroPage.rawValue + 1) else { return }
        currentIntroPage = next
    }
    
    func startSetupPhase() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPhase = .setup
        }
        Log.info("Introduction 완료 → Setup Phase 시작")
    }
    
    // MARK: - Setup Navigation
    
    func backFromSetup() {
        if currentSetupStep == .watchCheck {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentPhase = .introduction
                currentIntroPage = .personalRecommend
            }
        } else {
            moveToPreviousSetupStep()
        }
    }
    
    func moveToPreviousSetupStep() {
        guard let prev = SetupStep(rawValue: currentSetupStep.rawValue - 1) else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentSetupStep = prev
        }
    }
    
    private func moveToNextSetupStep() {
        guard let next = SetupStep(rawValue: currentSetupStep.rawValue + 1) else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentSetupStep = next
        }
    }
    
    // MARK: - Step 1: Watch Check
    
    func handleHasWatch() {
        moveToNextSetupStep()
    }
    
    func handleNoWatch() {
        Log.info("Apple Watch 미보유 선택")
        watchAlertType = .noWatch
        showWatchAlert = true
    }
    
    // MARK: - Step 2: Permission Request
    
    func handleRequestPermissions() async {
        guard !isRequesting else { return }
        isRequesting = true
        defer { isRequesting = false }
        
        do {
            try await healthKit.requestAuthorization()
            permissionManager.markHealthKitRequested()
            Log.info("HealthKit 권한 요청 완료")
        } catch {
            Log.warning("HealthKit 권한 요청 에러 (계속 진행): \(error)")
        }
        
        await location.requestAuthorization()
        Log.info("위치 권한 요청 완료")
        
        do {
            try await notification.requestAuthorization()
            Log.info("알림 권한 요청 완료")
        } catch {
            Log.warning("알림 권한 거부 (계속 진행): \(error)")
        }
        
        await permissionManager.checkAllStatuses()
        moveToNextSetupStep()
    }
    
    // MARK: - Step 3: Skin Type
    
    func selectSkinType(_ skinType: SkinType) {
        selectedSkinType = skinType
    }
    
    func completeOnboarding() {
        guard let skinType = selectedSkinType else { return }
        
        let profile = UserProfile(skinType: skinType, spfLevel: .spf30)
        localStorage.saveUserProfile(profile)
        localStorage.saveOnboardingCompleted(true)
        
        Log.info("온보딩 완료 — 피부 타입: \(skinType.title)")
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isCompleted = true
        }
    }
}
