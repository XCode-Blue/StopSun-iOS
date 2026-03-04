//
//  LiveActivityManager.swift
//  StopSun
//
//  Created by donghee on 2/25/26.
//

import ActivityKit
import Foundation

/// Live Activity 관리자
///
/// ActivityKit을 사용하여 선크림 타이머 Live Activity를 관리합니다.
///
/// - Important: 동시에 1개의 Live Activity만 유지합니다.
///   새로 시작 시 기존 Activity는 자동 종료됩니다.
///
@MainActor
final class LiveActivityManager: LiveActivityManagerProtocol {

    // MARK: - Properties

    private var currentActivity: Activity<SunscreenTimerAttributes>?
    private var stateMonitorTask: Task<Void, Never>?

    var isActivityActive: Bool {
        currentActivity != nil
    }

    // MARK: - Initialization

    /// 앱 재실행 시 기존 Live Activity 복구
    init() {
        if let existing = Activity<SunscreenTimerAttributes>.activities.first {
            currentActivity = existing
            observeActivityState(existing)
            Log.info("기존 Live Activity 복구: \(existing.id)")
        }
    }

    // MARK: - Start

    func startActivity(
        appliedAt: Date,
        reapplyAt: Date,
        spfDisplayTitle: String,
        warningLevel: WarningLevel,
        progress: Double
    ) {
        // 기존 Activity 종료 (Race condition 방지: 동기적으로 nil 처리 후 비동기 종료)
        if let activity = currentActivity {
            stateMonitorTask?.cancel()
            currentActivity = nil
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            Log.warning("Live Activity가 비활성화되어 있습니다")
            return
        }

        let attributes = SunscreenTimerAttributes(
            appliedAt: appliedAt,
            reapplyAt: reapplyAt,
            spfDisplayTitle: spfDisplayTitle
        )

        let initialState = SunscreenTimerAttributes.ContentState(
            warningLevelRawValue: warningLevel.rawValue,
            progress: progress
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: reapplyAt),
                pushType: nil
            )
            currentActivity = activity
            observeActivityState(activity)
            Log.info("Live Activity 시작: \(activity.id)")
        } catch {
            Log.error("Live Activity 시작 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - Update

    func updateWarningLevel(_ warningLevel: WarningLevel, progress: Double) {
        guard let activity = currentActivity else { return }

        let contentState = SunscreenTimerAttributes.ContentState(
            warningLevelRawValue: warningLevel.rawValue,
            progress: progress
        )

        Task {
            await activity.update(.init(state: contentState, staleDate: nil))
            Log.debug("Live Activity 업데이트: \(warningLevel.title), progress: \(progress)")
        }
    }

    // MARK: - End

    func endActivity() {
        guard let activity = currentActivity else { return }

        stateMonitorTask?.cancel()
        currentActivity = nil

        let finalState = SunscreenTimerAttributes.ContentState(
            warningLevelRawValue: WarningLevel.safe.rawValue,
            progress: 0
        )

        Task {
            await activity.end(
                .init(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
            Log.info("Live Activity 종료: \(activity.id)")
        }
    }

    // MARK: - State Monitoring

    /// 사용자가 잠금화면에서 직접 Activity를 밀어서 종료했을 때 동기화
    private func observeActivityState(_ activity: Activity<SunscreenTimerAttributes>) {
        stateMonitorTask?.cancel()
        stateMonitorTask = Task { [weak self] in
            for await state in activity.activityStateUpdates {
                if state == .dismissed || state == .ended {
                    self?.currentActivity = nil
                    Log.debug("Live Activity 외부 종료 감지: \(state)")
                    break
                }
            }
        }
    }
}
