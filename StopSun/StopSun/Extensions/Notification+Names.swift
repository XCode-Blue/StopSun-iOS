//
//  Notification+Names.swift
//  StopSun
//
//  Created by J on 2/9/26.
//

import Foundation

// MARK: - Notification Names

extension Notification.Name {
    
    // MARK: - HealthKit
    
    /// HealthKit 데이터 업데이트
    ///
    /// HealthKit Background Delivery로 새 데이터 수신 시 발송
    static let healthKitDataDidUpdate = Notification.Name("healthKitDataDidUpdate")
    
    // MARK: - Location
    
    /// 위치 변경됨
    ///
    /// Significant Location Changes 감지 시 발송
    static let locationDidChange = Notification.Name("locationDidChange")
    
    // MARK: - Push Notification Actions
    
    /// 푸시 알림에서 "바르기" 버튼 탭
    ///
    /// NotificationManager delegate에서 apply 액션 수신 시 발송
    static let didTapApplySunscreenNotification = Notification.Name("didTapApplySunscreenNotification")
    
    // MARK: - User Profile
    
    /// 사용자 프로필 변경됨
    ///
    /// 피부 타입, SPF 등 프로필 정보 변경 시 발송
    /// - Note: `UserProfileManager`, `LocalStorageManager`에서 프로필 변경 시 발송
    static let userProfileDidChange = Notification.Name("userProfileDidChange")
    
    // MARK: - Sync
    
    /// 동기화 완료
    static let syncDidComplete = Notification.Name("syncDidComplete")
    
    /// 동기화 실패
    static let syncDidFail = Notification.Name("syncDidFail")
    
    // MARK: - Warning
    
    /// 경고 레벨 변경됨
    static let warningLevelDidChange = Notification.Name("warningLevelDidChange")
}

// MARK: - UserInfo Keys

enum NotificationUserInfoKey {
    static let location = "location"
    static let error = "error"
    static let level = "level"
}
