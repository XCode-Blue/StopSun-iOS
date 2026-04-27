//
//  SettingsViewModel.swift
//  StopSun
//
//  Created by taeni on 2/23/26.
//

import Foundation
import UIKit

/// 설정 화면 ViewModel
///
/// 사용자 프로필 데이터(SkinType, SPFLevel)를 조회/수정하고,
/// iOS 설정 앱 이동을 처리합니다.
///
/// - Important: 데이터 변경 후 반드시 `SyncCoordinator`를 통해 수행됩니다.
///
@MainActor
@Observable
final class SettingsViewModel {
    
    // MARK: - Constants
    
    enum ExternalURL {
        static let privacy = URL(string: "https://thin-frigate-1a3.notion.site/Privacy-Policy-3044acec465d8053b8e9f6672d1eb47b?source=copy_link")!
        static let support = URL(string: "https://thin-frigate-1a3.notion.site/StopSun-Customer-Support-30b4acec465d8049840ddf6a2c1bb581?source=copy_link")!
    }
    
    // MARK: - Properties
    
    private(set) var skinType: SkinType
    private(set) var spfLevel: SPFLevel
    
    // MARK: - Watch
    
    /// Watch 연동 확인 결과
    enum WatchConnectionResult {
        case alreadyConnected   // 확인 전부터 이미 연결 상태
        case nowConnected       // 확인 후 새로 연결됨
        case notPaired          // 페어링된 워치 없음
    }
    
    /// Watch 연동 확인 진행 중 여부
    private(set) var isCheckingWatch: Bool = false
    private(set) var watchConnectionResult: WatchConnectionResult?
    var showWatchConnectionAlert: Bool = false
    
    // MARK: - Dependencies
    
    private let syncCoordinator: any SyncCoordinatorProtocol
    private let permissionManager: PermissionManager
    
    // MARK: - Initializer
    
    init(
        syncCoordinator: any SyncCoordinatorProtocol,
        permissionManager: PermissionManager
    ) {
        self.syncCoordinator = syncCoordinator
        self.permissionManager = permissionManager
        
        let profile = syncCoordinator.userProfile
        self.skinType = profile?.skinType ?? .type3
        self.spfLevel = profile?.spfLevel ?? .spf30
        
        Log.debug("SettingsViewModel initialized")
    }
    
    // MARK: - Profile Update
    
    /// 피부 타입 변경
    ///
    /// `SyncCoordinator`를 통해 변경하여
    /// localStorage 저장 + 경고 레벨 재계산 + Watch 동기화를 보장합니다.
    func updateSkinType(_ skinType: SkinType) {
        syncCoordinator.updateSkinType(skinType)
        self.skinType = skinType
        Log.info("Settings: Skin type updated to \(skinType.title)")
    }
    
    /// SPF 레벨 변경
    func updateSPFLevel(_ spfLevel: SPFLevel) {
        syncCoordinator.updateSunScreenSPF(spfLevel)
        self.spfLevel = spfLevel
        Log.info("Settings: SPF updated to \(spfLevel.displayTitle)")
    }
    
    /// 프로필 데이터 새로고침
    func refresh() {
        let profile = syncCoordinator.userProfile
        self.skinType = profile?.skinType ?? .type3
        self.spfLevel = profile?.spfLevel ?? .spf30
        Log.debug("Settings: Profile refreshed")
    }
    
    /// Apple Watch 연동 확인
    ///
    /// 온보딩과 동일하게 `activateAndWait()` → `isPaired` 체크 후
    /// `UserProfile.hasWatch`에 저장합니다.
    func checkWatchConnection() async {
        guard !isCheckingWatch else { return }
        isCheckingWatch = true
        defer { isCheckingWatch = false }
        
        let wasConnected = hasWatch  // 체크 전 상태 캡처
        
        await syncCoordinator.checkAndUpdateWatchConnection()
        
        // hasWatch는 checkAndUpdateWatchConnection() 완료 후 자동 반영 (@Observable)
        if hasWatch {
            watchConnectionResult = wasConnected ? .alreadyConnected : .nowConnected
        } else {
            watchConnectionResult = .notPaired
        }
        showWatchConnectionAlert = true
        
        Log.info("Settings: Watch 연동 확인 완료 — \(hasWatch ? "연결됨" : "미연결")")
    }
    
    // MARK: - Display Helpers
    
    var skinTypeDisplayText: String { skinType.title }
    var spfDisplayText: String { spfLevel.displayTitle }
    
    // MARK: - App Info
    
    var privacyURL: URL { ExternalURL.privacy }
    var supportURL: URL { ExternalURL.support }
    
    var appNameText: String {
        let displayName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "-"
        let bundleName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "-"
        return "\(displayName) - \(bundleName)"
    }
    
    var appVersionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return "v\(version) (\(build))"
    }
    
    /// Apple Watch 미보유 여부
    var hasWatch: Bool {
        syncCoordinator.userProfile?.hasWatch ?? true
    }
    
    /// 설정 앱으로 이동
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    
    /// 건강 앱 (일광 시간) 열기
    func openHealthApp() {
        guard let url = URL(string: "x-apple-health://") else { return }
        UIApplication.shared.open(url)
    }
}
