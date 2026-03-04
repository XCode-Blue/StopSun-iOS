//
//  WatchMessageKey.swift
//  StopSun
//
//  Created by donghee on 2/23/26.
//

import Foundation

/// iPhone ↔ Watch 간 메시지 키 상수
///
/// 양쪽에서 동일한 키를 사용하여 불일치를 방지합니다.
///
/// ```swift
/// // 전송 시
/// let data: [String: Any] = [
///     WatchMessageKey.type: WatchMessageKey.TypeValue.dashboardData,
///     WatchMessageKey.uvIndex: 5.0
/// ]
///
/// // 수신 시
/// if let uv = data[WatchMessageKey.uvIndex] as? Double { ... }
/// ```
///
enum WatchMessageKey {

    // MARK: - Common

    static let type = "type"
    static let timestamp = "timestamp"

    // MARK: - Type Values

    enum TypeValue {
        static let dashboardData = "dashboard_data"
        static let userProfile = "user_profile"
        static let sunscreenApplication = "sunscreen_application"
        static let sunscreenCancellation = "sunscreen_cancellation"
        static let medStatus = "med_status"
    }

    // MARK: - Request

    static let requestDashboardSync = "request_dashboard_sync"

    // MARK: - Dashboard Data

    static let uvIndex = "uvIndex"
    static let temperature = "temperature"
    static let cityName = "cityName"
    static let totalSED = "totalSED"
    static let maxSED = "maxSED"
    static let warningLevel = "warningLevel"

    // MARK: - Sunscreen

    static let sunscreenSPF = "sunscreenSPF"
    static let sunscreenAppliedAt = "sunscreenAppliedAt"
    static let reapplyMinutes = "reapplyMinutes"

    // MARK: - User Profile

    static let skinType = "skinType"
    static let spfLevel = "spfLevel"
}
