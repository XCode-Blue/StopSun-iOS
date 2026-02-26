//
//  WatchAppDelegate.swift
//  StopSunWatch Watch App
//
//  Created by StopSun Team
//

import Foundation
import UserNotifications
import WatchKit

/// Watch 앱의 라이프사이클을 관리하는 델리게이트 클래스
/// - WKExtensionDelegate: Watch 앱의 생명주기 이벤트를 처리
/// - 알림 이벤트 처리는 WatchNotificationDelegate가 담당
class WatchAppDelegate: NSObject, WKExtensionDelegate {

    /// 앱이 처음 실행될 때 호출되는 메서드 (앱 생애주기 동안 딱 한 번만 실행됨 보장)
    /// - 알림 델리게이트 설정
    /// - 알림 권한 요청
    /// - 알림 카테고리 등록
    func applicationDidFinishLaunching() {
        // WatchNotificationDelegate를 알림 델리게이트로 설정
        UNUserNotificationCenter.current().delegate = WatchNotificationDelegate.shared

        // WatchSessionManager 싱글톤 초기화 (init에서 WCSession 자동 활성화)
        _ = WatchSessionManager.shared

        requestNotificationPermission()
        registerNotificationCategories()
    }

    /// 알림 권한 요청
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error = error {
                print("[Watch] 알림 권한 요청 실패: \(error.localizedDescription)")
            } else {
                print("[Watch] 알림 권한 요청 결과: \(granted ? "승인됨" : "거부됨")")
            }
        }
    }

    /// 알림 카테고리 등록
    /// - 자외선 차단제 확인 카테고리: "예", "아니오" 버튼
    /// - 타이머 완료 카테고리: WatchTimerNotificationManager에서 사용
    private func registerNotificationCategories() {
        // 자외선 차단제 확인 카테고리
        let yesAction = UNNotificationAction(
            identifier: WatchNotificationIdentifier.Action.sunscreenYes,
            title: "예",
            options: []
        )
        let noAction = UNNotificationAction(
            identifier: WatchNotificationIdentifier.Action.sunscreenNo,
            title: "아니오",
            options: []
        )
        let sunscreenCategory = UNNotificationCategory(
            identifier: WatchNotificationIdentifier.Category.sunscreen,
            actions: [yesAction, noAction],
            intentIdentifiers: [],
            options: []
        )

        // 타이머 완료 카테고리
        let timerCategory = UNNotificationCategory(
            identifier: WatchNotificationIdentifier.Category.timerCompletion,
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([sunscreenCategory, timerCategory])
        print("[Watch] 알림 카테고리 등록 완료")
    }
}
