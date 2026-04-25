//
//  NotificationManager.swift
//  StopSun
//
//  Created by J on 1/27/26.
//

import Foundation
import UserNotifications

/// 알림 관리자
///
/// UNUserNotificationCenter를 사용하여 로컬 알림을 관리합니다.
///
/// ## 주요 기능
/// - 알림 권한 요청
/// - 재도포 알림 예약 (2시간 후)
/// - MED 경고 알림 (50%, 80%, 100%)
/// - 스누즈 (15분)
///
/// ## 알림 카테고리
/// - `reapply`: 재도포 알림 (바르기/스누즈/닫기 액션)
/// - `medWarning`: MED 경고 알림 (닫기 액션)
///
/// ## 스레드 안전성
/// `_isAuthorized`는 `@MainActor` 격리가 아닌 내부 캐시이므로,
/// `refreshAuthorizationStatus()`를 통해 명시적으로 갱신합니다.
///
final class NotificationManager: NSObject, NotificationManagerProtocol {
    
    // MARK: - Properties
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    /// 권한 허용 여부 (캐시)
    ///
    /// `init()` 시점에는 `false`이며, `refreshAuthorizationStatus()` 호출 후 갱신됩니다.
    /// `requestAuthorization()` 성공 시에도 갱신됩니다.
    private var _isAuthorized: Bool = false
    var isAuthorized: Bool { _isAuthorized }
    
    /// MED 경고 발송 이력 (중복 방지)
    private var sentMEDWarnings: Set<Int> = []
    
    /// 스누즈 시간 (분)
    private let snoozeMinutes: Int = 15
    
    // MARK: - Initializer
    
    override init() {
        super.init()
        notificationCenter.delegate = self
        registerCategories()
        
        Task {
            await refreshAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization Status
    
    var authorizationStatus: UNAuthorizationStatus {
        get async {
            let settings = await notificationCenter.notificationSettings()
            return settings.authorizationStatus
        }
    }
    
    func refreshAuthorizationStatus() async {
        let status = await authorizationStatus
        _isAuthorized = (status == .authorized || status == .provisional)
        Log.debug("알림 권한 상태 갱신: \(_isAuthorized) (status: \(status.rawValue))")
    }
    
    // MARK: - Request Authorization
    
    func requestAuthorization() async throws {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge, .providesAppNotificationSettings]
            )
            
            _isAuthorized = granted
            
            if !granted {
                throw AppError.notification(.authorizationDenied)
            }
            
            Log.info("알림 권한 획득: \(granted)")
        } catch let error as AppError {
            throw error
        } catch {
            Log.error("알림 권한 요청 실패: \(error)")
            throw AppError.notification(.authorizationDenied)
        }
    }
    
    // MARK: - Register Categories
    
    /// 알림 카테고리 및 액션 등록
    private func registerCategories() {
        let applyAction = UNNotificationAction(
            identifier: NotificationAction.apply,
            title: L10n.Notification.Action.apply,
            options: [.foreground]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: NotificationAction.snooze,
            title: L10n.Notification.Action.snooze,
            options: []
        )
        
        let dismissAction = UNNotificationAction(
            identifier: NotificationAction.dismiss,
            title: L10n.Notification.Action.dismiss,
            options: [.destructive]
        )
        
        let reapplyCategory = UNNotificationCategory(
            identifier: NotificationCategory.reapply,
            actions: [applyAction, snoozeAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        let medCategory = UNNotificationCategory(
            identifier: NotificationCategory.medWarning,
            actions: [applyAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([reapplyCategory, medCategory])
        Log.debug("알림 카테고리 등록 완료")
    }
    
    // MARK: - Reapply Reminder
    
    func scheduleReapplyReminder(at date: Date) async throws {
        guard date > Date() else {
            throw AppError.notification(.invalidDate)
        }
        
        // 기존 알림 취소 후 새로 예약
        cancelReapplyReminder()
        
        let content = UNMutableNotificationContent()
        content.title = L10n.Notification.Reapply.title
        content.body = L10n.Notification.Reapply.body
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.reapply
        content.interruptionLevel = .active

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: NotificationIdentifier.reapply,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            Log.info("재도포 알림 예약: \(date)")
        } catch {
            Log.error("재도포 알림 예약 실패: \(error)")
            throw AppError.notification(.scheduleFailed)
        }
    }
    
    func cancelReapplyReminder() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [NotificationIdentifier.reapply]
        )
        Log.debug("재도포 알림 취소")
    }
    
    func snoozeReapplyReminder() async throws {
        let snoozeDate = Date().addingTimeInterval(TimeInterval(snoozeMinutes * 60))
        try await scheduleReapplyReminder(at: snoozeDate)
        Log.info("재도포 알림 스누즈: \(snoozeMinutes)분 후")
    }
    
    // MARK: - MED Warning
    
    func sendMEDWarning(percentage: Double) {
        let threshold: Int
        if percentage >= 1.0 {
            threshold = 100
        } else if percentage >= 0.7 {
            threshold = 70
        } else if percentage >= 0.5 {
            threshold = 50
        } else if percentage >= 0.3 {
            threshold = 30
        } else {
            return
        }
        
        // 중복 방지
        guard !sentMEDWarnings.contains(threshold) else { return }
        sentMEDWarnings.insert(threshold)
        
        let content = UNMutableNotificationContent()
        content.categoryIdentifier = NotificationCategory.medWarning
        content.sound = .default
        
        switch threshold {
        case 30:
            content.title = L10n.Notification.MED.title30
            content.body = L10n.Notification.MED.body30
            content.interruptionLevel = .active
            
        case 50:
            content.title = L10n.Notification.MED.title50
            content.body = L10n.Notification.MED.body50
            content.interruptionLevel = .active

        case 70:
            content.title = L10n.Notification.MED.title70
            content.body = L10n.Notification.MED.body70
            content.interruptionLevel = .active

        case 100:
            content.title = L10n.Notification.MED.title100
            content.body = L10n.Notification.MED.body100
            content.interruptionLevel = .active

        default:
            return
        }
        
        let identifier = "stopsun.notification.med.\(threshold)"
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 0.1,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        Task {
            do {
                try await notificationCenter.add(request)
                Log.info("MED 경고 알림 발송: \(threshold)%")
            } catch {
                Log.error("MED 경고 알림 발송 실패: \(error)")
            }
        }
    }
    
    func resetMEDWarningHistory() {
        sentMEDWarnings.removeAll()
        Log.debug("MED 경고 이력 초기화")
    }
    
    // MARK: - Management
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        sentMEDWarnings.removeAll()
        Log.info("모든 알림 취소")
    }
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    
    /// 앱이 포그라운드일 때 알림 표시 방식
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }
    
    /// 알림 액션 처리
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let actionIdentifier = response.actionIdentifier
        let categoryIdentifier = response.notification.request.content.categoryIdentifier
        
        Log.debug("알림 액션: \(actionIdentifier), 카테고리: \(categoryIdentifier)")
        
        switch actionIdentifier {
        case NotificationAction.apply:
            // 선크림 바르기 → SyncCoordinator에서 처리
            NotificationCenter.default.post(
                name: .didTapApplySunscreenNotification,
                object: nil
            )
            
        case NotificationAction.snooze:
            try? await snoozeReapplyReminder()
            
        case NotificationAction.dismiss,
             UNNotificationDismissActionIdentifier:
            break
            
        case UNNotificationDefaultActionIdentifier:
            // 알림 탭 → 앱 열기
            break
            
        default:
            break
        }
    }
}
