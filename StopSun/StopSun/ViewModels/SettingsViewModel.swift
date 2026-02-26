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
@MainActor
@Observable
final class SettingsViewModel {
    
    // MARK: - Constants
    
    /// 외부 URL 상수
    /// - Note: URL 확정 시 실제 주소로 교체
    enum ExternalURL {
        static let privacy = URL(string: "https://thin-frigate-1a3.notion.site/Privacy-Policy-3044acec465d8053b8e9f6672d1eb47b?source=copy_link")!
        static let support = URL(string: "https://thin-frigate-1a3.notion.site/StopSun-Customer-Support-30b4acec465d8049840ddf6a2c1bb581?source=copy_link")!
    }
    
    // MARK: - Properties
    
    private(set) var skinType: SkinType
    private(set) var spfLevel: SPFLevel
    
    // MARK: - Dependencies
    
    private let localStorage: any LocalStorageManagerProtocol
    private let permissionManager: PermissionManager
    
    // MARK: - Initializer
    
    init(
        localStorage: any LocalStorageManagerProtocol,
        permissionManager: PermissionManager
    ) {
        self.localStorage = localStorage
        self.permissionManager = permissionManager
        
        let profile = localStorage.loadUserProfileOrDefault()
        self.skinType = profile.skinType
        self.spfLevel = profile.spfLevel
        
        Log.debug("SettingsViewModel initialized")
    }
    
    // MARK: - Profile Update
    
    /// 피부 타입 변경
    func updateSkinType(_ skinType: SkinType) {
        localStorage.updateSkinType(skinType)
        self.skinType = skinType
        Log.info("Settings: Skin type updated to \(skinType.title)")
    }
    
    /// SPF 레벨 변경
    func updateSPFLevel(_ spfLevel: SPFLevel) {
        localStorage.updateSunscreenSPF(spfLevel)
        self.spfLevel = spfLevel
        Log.info("Settings: SPF updated to \(spfLevel.displayTitle)")
    }
    
    /// 프로필 데이터 새로고침
    func refresh() {
        let profile = localStorage.loadUserProfileOrDefault()
        self.skinType = profile.skinType
        self.spfLevel = profile.spfLevel
        Log.debug("Settings: Profile refreshed")
    }
    
    // MARK: - Display Helpers
    
    /// 현재 피부 타입 표시 텍스트 (예: "4형")
    var skinTypeDisplayText: String {
        skinType.title
    }
    
    /// 현재 SPF 표시 텍스트 (예: "SPF 30")
    var spfDisplayText: String {
        spfLevel.displayTitle
    }
    
    // MARK: - App Info
    
    /// 개인정보 처리 방침 URL
    var privacyURL: URL { ExternalURL.privacy }
    
    /// 앱 정보 및 지원 URL
    var supportURL: URL { ExternalURL.support }
    
    /// 앱 이름 표시 텍스트 (예: "그만해 - StopSun")
    var appNameText: String {
        let displayName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "-"
        let bundleName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "-"
        return "\(displayName) - \(bundleName)"
    }
    
    /// 앱 버전 표시 텍스트 (예: "v1.0.0")
       var appVersionText: String {
           let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
           return "v\(version)"
       }
    
    // MARK: - Navigation
    
    /// iOS 설정 앱 → 앱 권한 페이지로 이동
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
