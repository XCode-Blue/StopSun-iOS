//
//  WatchNotificationDelegate.swift
//  StopSunWatch Watch App
//
//  Created by StopSun Team
//

import UserNotifications
import WatchKit

/// 알림 관련 이벤트를 전담 처리하는 델리게이트 클래스
/// - 싱글톤 패턴으로 구현하여 앱 전체에서 단일 인스턴스를 사용합니다.
/// - WatchAppDelegate와 분리하여 관심사의 분리(Separation of Concerns)를 실현합니다.
/// - MVVM 아키텍처: Delegate는 View Layer에 해당하며, 비즈니스 로직은 포함하지 않습니다.
final class WatchNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    /// 싱글톤 인스턴스
    /// - 앱 전체에서 하나의 알림 델리게이트만 사용하도록 보장합니다.
    static let shared = WatchNotificationDelegate()

    /// 외부에서 인스턴스 생성을 방지하는 private 생성자
    private override init() {
        super.init()
    }

    /// 앱이 포그라운드에 있을 때 알림이 도착했을 때 호출되는 메서드
    /// - 일반적으로 앱이 실행 중이면 알림이 표시되지 않지만, 이 메서드에서 명시적으로 표시 옵션을 설정할 수 있습니다.
    /// - 타이머나 중요한 알림은 앱 사용 중에도 표시되어야 하므로 banner와 sound 옵션을 반환합니다.
    ///
    /// - Parameters:
    ///   - center: UNUserNotificationCenter 인스턴스
    ///   - notification: 도착한 알림 객체
    ///   - completionHandler: 알림 표시 방식을 결정하는 핸들러
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let identifier = notification.request.identifier
        print("[Watch] 포그라운드 알림 수신: \(identifier)")

        // 앱이 활성 상태일 때도 알림을 배너와 사운드로 표시
        // - banner: 화면 상단에 배너 형태로 알림 표시
        // - sound: 알림 사운드 재생
        completionHandler([.banner, .sound])
    }

    /// 사용자가 알림을 탭하거나 알림의 액션 버튼을 눌렀을 때 호출되는 메서드
    /// - 알림 탭 이벤트를 감지하고 해당 알림의 종류에 따라 적절한 화면으로 이동합니다.
    /// - 비즈니스 로직은 포함하지 않으며, Coordinator를 통한 화면 전환만 수행합니다.
    ///
    /// - Parameters:
    ///   - center: UNUserNotificationCenter 인스턴스
    ///   - response: 사용자의 알림 응답 정보
    ///   - completionHandler: 작업 완료 후 호출해야 하는 핸들러
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        let notificationIdentifier = response.notification.request.identifier

        print("[Watch] 알림 응답 수신 - 알림 ID: \(notificationIdentifier), 액션: \(actionIdentifier)")

        // 알림 액션에 따른 처리
        switch actionIdentifier {
        case WatchNotificationIdentifier.Action.sunscreenYes:
            print("[Watch] 사용자가 자외선 차단제를 발랐습니다.")
            // TODO: ViewModel/Coordinator를 통한 비즈니스 로직 처리
            // 예: viewModel.recordSunscreenApplication()

        case WatchNotificationIdentifier.Action.sunscreenNo:
            print("[Watch] 사용자가 자외선 차단제를 바르지 않았습니다.")
            // TODO: ViewModel/Coordinator를 통한 비즈니스 로직 처리
            // 예: viewModel.recordSunscreenSkip()

        case UNNotificationDefaultActionIdentifier:
            print("[Watch] 알림 본문이 탭되었습니다.")
            // TODO: Coordinator를 통한 화면 네비게이션 구현
            // 예: coordinator.navigate(to: .timer) 또는 coordinator.navigate(to: .sunscreenReminder)

        case UNNotificationDismissActionIdentifier:
            print("[Watch] 알림이 닫혔습니다.")

        default:
            print("[Watch] 알 수 없는 액션: \(actionIdentifier)")
        }

        completionHandler()
    }
}
