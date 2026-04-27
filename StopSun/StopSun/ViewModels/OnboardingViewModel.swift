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
/// ## Apple Watch 선택
/// Watch 미보유 시에도 안내 후 다음 단계로 진행 가능합니다.
@MainActor
@Observable
final class OnboardingViewModel {
    
    // MARK: - Phase & Navigation
    
    enum NavigationDirection {
        case forward
        case backward
    }

    var navigationDirection: NavigationDirection = .forward
    
    var currentPhase: OnboardingPhase = .introduction
    var currentIntroPage: IntroductionPage = .trackExposure
    var currentSetupStep: SetupStep = .watchCheck
    
    // MARK: - State
    
    var selectedSkinType: SkinType? = nil
    var hasWatch: Bool = true
    var isRequesting: Bool = false
    var isCompleted: Bool = false
    
    // MARK: - Alert State
    
    var showWatchAlert: Bool = false
    var watchAlertType: WatchAlertType = .noWatch
    
    /// 권한 거부 안내 Alert
    var showPermissionDeniedAlert: Bool = false
    
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
        navigationDirection = .backward
        withAnimation(.easeInOut(duration: 0.3)) {
            currentSetupStep = prev
        }
    }
    
    private func moveToNextSetupStep() {
        guard let next = SetupStep(rawValue: currentSetupStep.rawValue + 1) else { return }
        navigationDirection = .forward
        withAnimation(.easeInOut(duration: 0.3)) {
            currentSetupStep = next
        }
    }
    
    // MARK: - Step 1: Watch Check
    
    /// "네, 보유 중이에요" 탭 시 호출
    ///
    /// `activateAndWait()`로 세션 활성화 완료를 대기한 후
    /// `isPaired`를 체크합니다.
    ///
    /// - 페어링됨 → Step 2로 이동
    /// - 미페어링 → notPaired Alert 표시
    func handleHasWatch() async {
        // 세션 활성화 완료까지 대기 (타이밍 이슈 방지)
        await watchConnectivity.activateAndWait()
        
        if watchConnectivity.isPaired {
            Log.info("Apple Watch 페어링 확인됨 → Step 2 이동")
            moveToNextSetupStep()
        } else {
            Log.info("Apple Watch 미페어링 감지")
            watchAlertType = .notPaired
            showWatchAlert = true
        }
    }
    
    func handleNoWatch() {
        Log.info("Apple Watch 미보유 선택")
        watchAlertType = .noWatch
        showWatchAlert = true
    }

    /// Watch 미보유 Alert에서 "확인" 탭 시 호출
    func continueWithoutWatch() {
        hasWatch = false
        showWatchAlert = false
        moveToNextSetupStep()
    }
    
    // MARK: - Step 2: Permission Request
    
    /// 권한 요청 실행
    ///
    /// HealthKit → Location → Notification 순서로 시스템 팝업을 표시합니다.
    /// 각 권한의 허용/거부와 무관하게 완료 후 Step 3으로 이동합니다.
    /// 핵심 권한(위치)이 거부된 경우 안내 Alert를 표시합니다.
    ///
    /// - Note: HealthKit 플래그는 `HealthKitManager.requestAuthorization()` 내부에서
    ///   자동 세팅되므로 별도 `markHealthKitRequested()` 호출이 불필요합니다.
    func handleRequestPermissions() async {
        guard !isRequesting else { return }
        isRequesting = true
        defer { isRequesting = false }
        
        // 1. HealthKit
        do {
            try await healthKit.requestAuthorization()
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
        
        // 4. 최종 상태 갱신
        await permissionManager.checkAllStatuses()
        
        // 5. 핵심 권한 거부 시 안내 (진행은 허용)
        if location.isDenied {
            Log.warning("위치 권한 거부됨 — 안내 Alert 표시")
            showPermissionDeniedAlert = true
            // Alert dismiss 후 continueAfterPermissionDenied() → moveToNextSetupStep()
        } else {
            moveToNextSetupStep()
        }
    }
    
    /// 권한 거부 안내 Alert에서 "계속" 탭 시 호출
    func continueAfterPermissionDenied() {
        showPermissionDeniedAlert = false
        moveToNextSetupStep()
    }
    
    // MARK: - Step 3: Skin Type
    
    func selectSkinType(_ skinType: SkinType) {
        selectedSkinType = skinType
    }
    
    func completeOnboarding() {
        guard let skinType = selectedSkinType else { return }

        let profile = UserProfile(skinType: skinType, spfLevel: .spf30, hasWatch: hasWatch)
        localStorage.saveUserProfile(profile)
        localStorage.saveOnboardingCompleted(true)
        
        Log.info("온보딩 완료 — 피부 타입: \(skinType.title)")
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isCompleted = true
        }
    }
}
