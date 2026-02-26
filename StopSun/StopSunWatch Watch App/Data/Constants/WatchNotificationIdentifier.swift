//
//  WatchNotificationIdentifier.swift
//  StopSunWatch Watch App
//
//  Created by donghee on 2/23/26.
//

import Foundation

/// Watch 앱 알림 식별자 중앙 관리
///
/// WatchAppDelegate, WatchNotificationDelegate, WatchTimerNotificationManager 등에서
/// 동일한 식별자를 사용하여 불일치를 방지합니다.
enum WatchNotificationIdentifier {

    // MARK: - Category Identifiers

    enum Category {
        static let sunscreen = "SUNSCREEN_CATEGORY"
        static let timerCompletion = "TIMER_COMPLETION"
    }

    // MARK: - Action Identifiers

    enum Action {
        static let sunscreenYes = "SUNSCREEN_YES"
        static let sunscreenNo = "SUNSCREEN_NO"
    }

    // MARK: - Request Identifiers

    enum Request {
        static let timerCompletion = "watchTimerCompletion"
        static let immediateTimerCompletion = "immediateTimerCompletion"
    }
}
