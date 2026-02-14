//
//  PermissionManager.swift
//  StopSun
//
//  Created by taeni on 2/9/26.
//

import Foundation
import UserNotifications
import CoreLocation
import HealthKit

/// 권한 상태
enum PermissionStatus: String, Equatable, Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted
}

/// 권한 관리자
///
/// 앱에서 필요한 시스템 권한의 상태를 관리합니다.
///
/// ## 온보딩과의 관계
/// 권한 **요청**은 온보딩 Step 2에서 `OnboardingViewModel`이 직접 수행합니다.
/// `PermissionManager`는 권한 **상태 조회/갱신**을 담당합니다.
///
/// ## 사용 시점
/// - 앱 시작 시: `checkAllStatuses()` → 현재 상태 파악
/// - `scenePhase == .active`: 설정 앱에서 변경한 권한 반영
/// - 서비스 초기화: 권한 상태에 따라 HealthKit/Location 서비스 활성화
///
@MainActor
@Observable
final class PermissionManager {
    
    // MARK: - Properties
    
    private(set) var notificationStatus: PermissionStatus = .notDetermined
    private(set) var healthKitStatus: PermissionStatus = .notDetermined
    private(set) var locationStatus: PermissionStatus = .notDetermined
    
    // MARK: - Dependencies
    
    private let notification: any NotificationManagerProtocol
    private let healthKit: any HealthKitManagerProtocol
    private let location: any LocationManagerProtocol
    
    // MARK: - Constants
    
    private static let healthKitRequestedKey = "stopsun.permission.healthKitRequested"
    
    // MARK: - Computed Properties
    
    /// 모든 필수 권한이 허용됨
    var allPermissionsGranted: Bool {
        notificationStatus == .authorized &&
        healthKitStatus == .authorized &&
        locationStatus == .authorized
    }
    
    // MARK: - Initializer
    
    init(
        notification: any NotificationManagerProtocol,
        healthKit: any HealthKitManagerProtocol,
        location: any LocationManagerProtocol
    ) {
        self.notification = notification
        self.healthKit = healthKit
        self.location = location
    }
    
    // MARK: - Check All Statuses
    
    /// 모든 권한 상태를 시스템에서 조회하여 갱신
    ///
    /// 앱 진입 시, `scenePhase` 변경 시 호출합니다.
    func checkAllStatuses() async {
        await checkNotificationStatus()
        checkHealthKitStatus()
        checkLocationStatus()
        
        Log.info(
            "권한 상태 — 알림: \(notificationStatus), " +
            "HealthKit: \(healthKitStatus), " +
            "위치: \(locationStatus)"
        )
    }
    
    // MARK: - HealthKit 요청 완료 기록
    
    /// 온보딩에서 HealthKit 요청이 완료되었음을 기록
    ///
    /// HealthKit read 권한은 granted/denied 구분이 불가하므로,
    /// 요청 여부만 UserDefaults에 기록합니다.
    func markHealthKitRequested() {
        UserDefaults.standard.set(true, forKey: Self.healthKitRequestedKey)
    }
    
    // MARK: - Private Status Checks
    
    private func checkNotificationStatus() async {
        let status = await notification.authorizationStatus
        
        switch status {
        case .notDetermined:
            notificationStatus = .notDetermined
        case .denied:
            notificationStatus = .denied
        case .authorized, .provisional, .ephemeral:
            notificationStatus = .authorized
        @unknown default:
            notificationStatus = .notDetermined
        }
    }
    
    private func checkHealthKitStatus() {
        guard healthKit.isAvailable else {
            healthKitStatus = .restricted
            return
        }
        
        let hasRequested = UserDefaults.standard.bool(forKey: Self.healthKitRequestedKey)
        healthKitStatus = hasRequested ? .authorized : .notDetermined
    }
    
    private func checkLocationStatus() {
        locationStatus = location.isAuthorized ? .authorized : .notDetermined
    }
}
