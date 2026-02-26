//
//  WatchTimerNotificationManager.swift
//  StopSunWatch Watch App
//
//  Created by StopSun Team
//

import UserNotifications
import WatchKit

/// 타이머 관련 알림을 관리하는 Manager 클래스
/// - MVVM 아키텍처: Manager는 Model Layer에 해당하며, 알림 관련 비즈니스 로직을 처리합니다.
/// - DIContainer를 통해 생성되고 주입됩니다.
/// - 타이머 완료 알림의 스케줄링, 취소, 즉시 표시 등의 기능을 제공합니다.
final class WatchTimerNotificationManager {

    // MARK: - Initializer

    /// DIContainer에서 주입받아 사용하는 생성자
    /// - Note: 싱글톤 패턴이 아닌 의존성 주입 방식으로 설계되었습니다.
    init() {}

    // MARK: - Public Methods

    /// 알림 권한을 요청하는 메서드
    /// - 사용자에게 알림, 사운드, 뱃지 권한을 요청합니다.
    /// - 권한 요청은 앱 실행 초기에 한 번만 수행하면 됩니다.
    ///
    /// - Returns: 권한 승인 여부 (true: 승인, false: 거부)
    func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(
                options: [.alert, .sound, .badge]
            )

            print("[Watch] 알림 권한 요청 결과: \(granted ? "승인" : "거부")")
            return granted
        } catch {
            print("[Watch] 알림 권한 요청 실패: \(error.localizedDescription)")
            return false
        }
    }

    /// 타이머 완료 알림을 스케줄링하는 메서드
    /// - 지정된 시간에 타이머 완료 알림을 예약합니다.
    /// - 알림은 타이머가 종료되는 정확한 시점에 사용자에게 전달됩니다.
    ///
    /// - Parameter date: 알림을 표시할 날짜 및 시간
    func scheduleTimerCompletionNotification(at date: Date) {
        // 알림 시간 간격 계산
        let timeInterval = date.timeIntervalSinceNow
        guard timeInterval > 0 else {
            print("[Watch] 유효하지 않은 알림 시간: \(timeInterval)초")
            return
        }

        // 알림 콘텐츠 생성
        let content = createTimerCompletionContent()

        // 알림 트리거 생성 (지정된 시간 후 한 번만 실행)
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )

        // 알림 요청 생성
        let request = UNNotificationRequest(
            identifier: WatchNotificationIdentifier.Request.timerCompletion,
            content: content,
            trigger: trigger
        )

        // 알림 스케줄링
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[Watch] 알림 스케줄링 실패: \(error.localizedDescription)")
            } else {
                print("[Watch] 타이머 완료 알림 예약됨: \(date)")
            }
        }
    }

    /// 예약된 타이머 알림을 취소하는 메서드
    /// - 사용자가 타이머를 중지하거나 리셋할 때 호출됩니다.
    /// - 이미 전달된 알림은 취소할 수 없으며, 대기 중인 알림만 취소됩니다.
    func cancelTimerNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [WatchNotificationIdentifier.Request.timerCompletion]
        )
        print("[Watch] 타이머 알림 취소됨")
    }

    /// 즉시 타이머 완료 알림을 표시하는 메서드
    /// - 타이머가 완료되었을 때 즉시 알림을 표시하고 싶을 때 사용합니다.
    /// - 로컬 알림은 trigger가 필수이므로 0.1초 지연을 사용합니다 (사용자가 체감할 수 없는 수준).
    func showImmediateNotification() {
        // 알림 콘텐츠 생성
        let content = createTimerCompletionContent()

        // 즉시 알림을 위한 최소 시간 간격 트리거
        // - Apple 문서: 로컬 알림은 반드시 trigger를 가져야 함
        // - 0.1초는 사용자가 체감할 수 없는 지연이며, watchOS에서 안정적으로 동작
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 0.1,
            repeats: false
        )

        // 알림 요청 생성 (즉시 알림은 별도 identifier 사용)
        let request = UNNotificationRequest(
            identifier: WatchNotificationIdentifier.Request.immediateTimerCompletion,
            content: content,
            trigger: trigger
        )

        // 알림 표시
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[Watch] 즉시 알림 표시 실패: \(error.localizedDescription)")
            } else {
                print("[Watch] 즉시 알림 표시됨 (0.1초 후)")
            }
        }
    }

    // MARK: - Private Methods

    /// 타이머 완료 알림의 콘텐츠를 생성하는 메서드
    /// - DRY 원칙: 중복 코드를 제거하고 알림 내용을 한 곳에서 관리합니다.
    /// - 알림 문구 수정 시 이 메서드만 변경하면 모든 타이머 알림에 반영됩니다.
    ///
    /// - Returns: 설정된 UNMutableNotificationContent 객체
    private func createTimerCompletionContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        // TODO: 문구는 추후 ViewModel이나 Localizable.strings로 이동 고려
        content.title = "타이머 완료"
        content.body = "설정한 시간이 완료되었습니다."
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = WatchNotificationIdentifier.Category.timerCompletion

        return content
    }
}
