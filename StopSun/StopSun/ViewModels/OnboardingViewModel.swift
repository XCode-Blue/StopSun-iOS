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
///
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
    private let userProfileManager = UserProfileManager.shared
    
    // MARK: - Initializer
    
    init(
        healthKit: any HealthKitManagerProtocol,
        location: any LocationManagerProtocol,
        notification: any NotificationManagerProtocol,
        watchConnectivity: any WatchConnectivityManagerProtocol,
        permissionManager: PermissionManager
    ) {
        self.healthKit = healthKit
        self.location = location
        self.notification = notification
        self.watchConnectivity = watchConnectivity
        self.permissionManager = permissionManager
        
        Log.debug("OnboardingViewModel 초기화")
    }
    
    // MARK: - Computed Properties (Introduction)
    
    /// Introduction 마지막 페이지 여부
    var isLastIntroPage: Bool {
        currentIntroPage == IntroductionPage.allCases.last
    }
    
    /// Introduction에서 뒤로가기 가능 여부
    var canGoBackInIntro: Bool {
        currentIntroPage.rawValue > 0
    }
    
    // MARK: - Computed Properties (Setup)
    
    /// Setup 진행률 (0.0 ~ 1.0)
    var setupProgress: Double {
        Double(currentSetupStep.rawValue + 1) / Double(SetupStep.allCases.count)
    }
    
    /// Setup에서 뒤로가기 가능 여부
    var canGoBackInSetup: Bool {
        currentSetupStep.rawValue > 0
    }
    
    // MARK: - Introduction Navigation
    
    /// Introduction 이전 페이지로 이동
    func moveToPreviousIntroPage() {
        guard let prev = IntroductionPage(rawValue: currentIntroPage.rawValue - 1) else { return }
        currentIntroPage = prev
    }
    
    /// Introduction 다음 페이지로 이동
    func moveToNextIntroPage() {
        guard let next = IntroductionPage(rawValue: currentIntroPage.rawValue + 1) else { return }
        currentIntroPage = next
    }
    
    /// Introduction → Setup Phase로 이동 ("기본 설정하기" 또는 "건너뛰기")
    func startSetupPhase() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPhase = .setup
        }
        Log.info("Introduction 완료 → Setup Phase 시작")
    }
    
    // MARK: - Setup Navigation
    
    /// Setup에서 뒤로가기 처리
    /// - 첫 번째 단계(watchCheck)면 → Introduction 마지막 페이지로
    /// - 그 외 단계면 → 이전 Setup 단계로
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
    
    /// Setup 이전 단계로 이동
    func moveToPreviousSetupStep() {
        guard let prev = SetupStep(rawValue: currentSetupStep.rawValue - 1) else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentSetupStep = prev
        }
    }
    
    /// Setup 다음 단계로 이동
    private func moveToNextSetupStep() {
        guard let next = SetupStep(rawValue: currentSetupStep.rawValue + 1) else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentSetupStep = next
        }
    }
    
    // MARK: - Step 1: Watch Check
    
    /// "네, 보유 중이에요" 탭
    func handleHasWatch() {
        // TODO: watchConnectivity.isPaired 확인
        moveToNextSetupStep()
//        if watchConnectivity.isPaired {
//            Log.info("Apple Watch 페어링 확인됨 → 다음 단계")
//            moveToNextSetupStep()
//        } else {
//            Log.warning("Apple Watch 페어링 감지 안 됨")
//            watchAlertType = .notPaired
//            showWatchAlert = true
//        }
    }
    
    /// "아니오, 없어요" 탭
    func handleNoWatch() {
        Log.info("Apple Watch 미보유 선택")
        watchAlertType = .noWatch
        showWatchAlert = true
    }
    
    // MARK: - Step 2: Permission Request
    
    /// "계속" 탭 → HealthKit → Location → Notification 순차 요청
    func handleRequestPermissions() async {
        guard !isRequesting else { return }
        isRequesting = true
        defer { isRequesting = false }
        
        // 1. HealthKit
        do {
            try await healthKit.requestAuthorization()
            permissionManager.markHealthKitRequested()
            Log.info("HealthKit 권한 요청 완료")
        } catch {
            Log.warning("HealthKit 권한 요청 에러 (계속 진행): \(error)")
        }
        
        // 2. Location
        await location.requestAuthorization()
        Log.info("위치 권한 요청 완료")
        
        // 3. Notification
        do {
            try await notification.requestAuthorization()
            Log.info("알림 권한 요청 완료")
        } catch {
            Log.warning("알림 권한 거부 (계속 진행): \(error)")
        }
        
        // 권한 상태 갱신
        await permissionManager.checkAllStatuses()
        
        moveToNextSetupStep()
    }
    
    // MARK: - Step 3: Skin Type
    
    /// 피부 타입 선택
    func selectSkinType(_ skinType: SkinType) {
        selectedSkinType = skinType
    }
    
    /// "시작하기" 탭 → 온보딩 완료
    func completeOnboarding() {
        guard let skinType = selectedSkinType else { return }
        
        let profile = UserProfile(skinType: skinType, spfLevel: .spf30)
        userProfileManager.saveProfile(profile)
        userProfileManager.saveOnboardingCompleted(true)
        
        Log.info("온보딩 완료 — 피부 타입: \(skinType.title)")
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isCompleted = true
        }
    }
}
