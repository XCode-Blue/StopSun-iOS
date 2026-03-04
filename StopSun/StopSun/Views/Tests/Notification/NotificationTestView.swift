//
//  NotificationTestView.swift
//  StopSun
//
//  Created by taeni on 2/9/26.
//

import SwiftUI
import UserNotifications

#if DEBUG
struct NotificationTestView: View {

    private let manager: NotificationManagerProtocol = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    @State private var pendingCount: Int = 0
    @State private var authStatus: UNAuthorizationStatus?

    var body: some View {
        VStack(spacing: 16) {

            Group {
                Text("Authorization Status")
                Text(authStatusText)
                    .font(.caption)
            }

            Button("알림 권한 요청") {
                Task {
                    try? await manager.requestAuthorization()
                    await refreshStatus()
                }
            }

            Button("재도포 알림 (10초 후)") {
                Task {
                    let date = Date().addingTimeInterval(10)
                    try? await manager.scheduleReapplyReminder(at: date)
                    await refreshPending()
                }
            }

            Button("재도포 알림 스누즈 (15분)") {
                Task {
                    try? await manager.snoozeReapplyReminder()
                    await refreshPending()
                }
            }

            Button("재도포 알림 취소") {
                manager.cancelReapplyReminder()
            }

            Divider()

            Button("MED 30% (10초 후)") {
                scheduleMEDDebug(threshold: 30)
            }

            Button("MED 50% (10초 후)") {
                scheduleMEDDebug(threshold: 50)
            }

            Button("MED 70% (10초 후)") {
                scheduleMEDDebug(threshold: 70)
            }

            Button("MED 100% (10초 후)") {
                scheduleMEDDebug(threshold: 100)
            }

            Button("MED 경고 이력 리셋") {
                manager.resetMEDWarningHistory()
            }

            Divider()

            Button("모든 알림 취소") {
                manager.cancelAllNotifications()
                Task { await refreshPending() }
            }

            Text("대기 중 알림: \(pendingCount)")
                .font(.caption)
        }
        .padding()
        .task {
            await refreshStatus()
            await refreshPending()
        }
    }

    // MARK: - MED Debug Scheduler (TestView 전용)

    private func scheduleMEDDebug(threshold: Int) {
        let content = UNMutableNotificationContent()
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.medWarning

        switch threshold {
        case 30:
            content.title = L10n.Notification.MED.title30
            content.body = L10n.Notification.MED.body30
        case 50:
            content.title = L10n.Notification.MED.title50
            content.body = L10n.Notification.MED.body50
        case 70:
            content.title = L10n.Notification.MED.title70
            content.body = L10n.Notification.MED.body70
        case 100:
            content.title = L10n.Notification.MED.title100
            content.body = L10n.Notification.MED.body100
        default:
            return
        }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 10,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "debug.med.\(threshold).\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        Task {
            try? await center.add(request)
            await refreshPending()
        }
    }

    // MARK: - Status

    private var authStatusText: String {
        guard let authStatus else { return "Unknown" }
        switch authStatus {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .notDetermined: return "Not Determined"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }

    private func refreshStatus() async {
        await manager.refreshAuthorizationStatus()
        authStatus = await manager.authorizationStatus
    }

    private func refreshPending() async {
        let requests = await manager.getPendingNotifications()
        pendingCount = requests.count
    }
}

#Preview {
    NotificationTestView()
}
#endif
