//
//  WatchConnectivityManager.swift
//  StopSun
//
//  Created by J on 1/27/26.
//

import Foundation
import WatchConnectivity

/// Watch Connectivity 관리자
///
/// iPhone ↔ Apple Watch 간 데이터 동기화를 담당합니다.
/// WCSession을 통해 메시지 송수신, UserInfo 전송, Application Context 업데이트를 지원합니다.
///
/// ## 전송 방식
/// - `sendMessage`: 즉시 전송 (양쪽 앱 실행 중 필요)
/// - `transferUserInfo`: 백그라운드 전송 (큐에 저장, 보장된 전송)
/// - `updateApplicationContext`: 최신 상태만 유지 (이전 데이터 덮어쓰기)
///
final class WatchConnectivityManager: NSObject, ObservableObject, WatchConnectivityManagerProtocol {

    // MARK: - Published Properties

    var isPaired: Bool { session?.isPaired ?? false }
    @Published private(set) var isReachable: Bool = false

    // MARK: - Callbacks

    var onMessageReceived: (([String: Any]) -> Void)?
    var onUserInfoReceived: (([String: Any]) -> Void)?

    // MARK: - Private Properties

    private var session: WCSession?

    // MARK: - Initialization

    override init() {
        super.init()
    }

    // MARK: - Session

    func activate() {
        guard WCSession.isSupported() else {
            Log.warning("WCSession을 지원하지 않는 기기입니다")
            return
        }

        session = WCSession.default
        session?.delegate = self
        session?.activate()
        Log.info("WCSession 활성화 요청")
    }

    // MARK: - Domain Methods

    func sendUserProfile(_ profile: UserProfile) {
        let userInfo: [String: Any] = [
            WatchMessageKey.type: WatchMessageKey.TypeValue.userProfile,
            WatchMessageKey.skinType: profile.skinType.rawValue,
            WatchMessageKey.spfLevel: profile.spfLevel.rawValue
        ]

        transferUserInfo(userInfo)
        Log.info("UserProfile 전송: skinType=\(profile.skinType.title), spf=\(profile.spfLevel.displayTitle)")
    }

    func sendSunscreenApplication(_ application: SunscreenApplication) {
        let message: [String: Any] = [
            WatchMessageKey.type: WatchMessageKey.TypeValue.sunscreenApplication,
            WatchMessageKey.sunscreenSPF: application.spfLevel.rawValue,
            WatchMessageKey.sunscreenAppliedAt: application.appliedAt.timeIntervalSince1970,
            WatchMessageKey.reapplyMinutes: application.reapplyIntervalMinutes
        ]

        sendMessage(message, replyHandler: nil, errorHandler: nil)
        Log.info("SunscreenApplication 전송: SPF \(application.spfLevel.displayTitle)")
    }

    func sendMEDStatus(totalSED: Double, maxMED: Double) {
        let message: [String: Any] = [
            WatchMessageKey.type: WatchMessageKey.TypeValue.medStatus,
            WatchMessageKey.totalSED: totalSED,
            WatchMessageKey.maxSED: maxMED
        ]

        sendMessage(message, replyHandler: nil, errorHandler: nil)
        Log.info("MED 상태 전송: \(String(format: "%.2f", totalSED))/\(String(format: "%.1f", maxMED))")
    }

    // MARK: - Generic Methods

    func sendMessage(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)?,
        errorHandler: ((Error) -> Void)?
    ) {
        guard let session = session, session.isReachable else {
            Log.warning("WCSession 연결 불가 - 메시지 전송 실패")
            errorHandler?(NSError(
                domain: "WatchConnectivity",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Session is not reachable"]
            ))
            return
        }

        session.sendMessage(message, replyHandler: replyHandler) { error in
            Log.error("메시지 전송 실패: \(error.localizedDescription)")
            errorHandler?(error)
        }

        Log.debug("메시지 전송: \(message["type"] as? String ?? "unknown")")
    }

    func transferUserInfo(_ userInfo: [String: Any]) {
        guard let session = session else {
            Log.warning("WCSession 없음 - UserInfo 전송 실패")
            return
        }

        session.transferUserInfo(userInfo)
        Log.debug("UserInfo 전송: \(userInfo["type"] as? String ?? "unknown")")
    }

    func updateApplicationContext(_ context: [String: Any]) throws {
        guard let session = session else {
            throw AppError.watchConnectivity(.sessionInactive)
        }

        do {
            try session.updateApplicationContext(context)
            Log.debug("Application Context 업데이트 완료")
        } catch {
            Log.error("Application Context 업데이트 실패: \(error.localizedDescription)")
            throw AppError.watchConnectivity(.transferFailed)
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {

    // MARK: - Session State

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        DispatchQueue.main.async { [weak self] in
            if let error = error {
                Log.error("WCSession 활성화 실패: \(error.localizedDescription)")
                return
            }

            switch activationState {
            case .activated:
                Log.info("WCSession 활성화 완료")
                self?.isReachable = session.isReachable
            case .inactive:
                Log.warning("WCSession 비활성 상태")
                self?.isReachable = false
            case .notActivated:
                Log.warning("WCSession 미활성화 상태")
                self?.isReachable = false
            @unknown default:
                Log.warning("WCSession 알 수 없는 상태")
                self?.isReachable = false
            }
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            self?.isReachable = session.isReachable
            Log.info("Watch 연결 상태 변경: \(session.isReachable)")
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        Log.warning("WCSession 비활성화됨")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        Log.warning("WCSession 비활성화 완료 - 재활성화 중...")
        session.activate()
    }
    #endif

    // MARK: - Message Handling

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        DispatchQueue.main.async { [weak self] in
            Log.debug("메시지 수신 (reply 포함): \(message["type"] as? String ?? "unknown")")
            self?.onMessageReceived?(message)

            let reply: [String: Any] = [
                "status": "received",
                "timestamp": Date().timeIntervalSince1970
            ]
            replyHandler(reply)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            Log.debug("메시지 수신: \(message["type"] as? String ?? "unknown")")
            self?.onMessageReceived?(message)
        }
    }

    // MARK: - UserInfo Handling

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        DispatchQueue.main.async { [weak self] in
            Log.debug("UserInfo 수신: \(userInfo["type"] as? String ?? "unknown")")
            self?.onUserInfoReceived?(userInfo)
        }
    }

    // MARK: - Application Context Handling

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            Log.debug("Application Context 수신: \(applicationContext)")
        }
    }
}
