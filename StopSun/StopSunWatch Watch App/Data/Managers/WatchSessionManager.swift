//
//  WatchSessionManager.swift
//  StopSunWatch Watch App
//
//  Created by donghee on 2/21/26.
//

import Foundation
import WatchConnectivity
import SwiftUI

/// Watch 전용 WCSession 관리자
///
/// iPhone ↔ Apple Watch 간 통신을 Watch 측에서 담당합니다.
/// 싱글톤으로 구현하여 WatchAppDelegate에서 앱 시작 시 활성화합니다.
///
/// ## 통신 흐름
/// - Watch → iPhone: `requestDashboardSync()`로 대시보드 데이터 요청
/// - iPhone → Watch: `onMessageReceived` 콜백으로 데이터 수신
/// - 오프라인: `receivedApplicationContext`에서 마지막 상태 로드
///
class WatchSessionManager: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = WatchSessionManager()

    // MARK: - Published Properties

    @Published var isReachable: Bool = false

    // MARK: - Callbacks

    /// 즉시 메시지 수신 콜백
    var onMessageReceived: (([String: Any]) -> Void)?

    /// UserInfo 수신 콜백
    var onUserInfoReceived: (([String: Any]) -> Void)?

    /// Application Context 수신 콜백
    var onApplicationContextReceived: (([String: Any]) -> Void)?

    // MARK: - Private Properties

    private var session: WCSession?

    // MARK: - Initialization

    /// WatchAppDelegate에서 `_ = WatchSessionManager.shared`로 최초 호출하면
    /// init에서 자동으로 세션이 활성화됩니다.
    private override init() {
        super.init()

        guard WCSession.isSupported() else {
            Log.warning("WCSession을 지원하지 않는 기기입니다")
            return
        }

        session = WCSession.default
        session?.delegate = self
        session?.activate()
        Log.info("WCSession 활성화 요청")
    }

    // MARK: - Public Methods

    /// iPhone에 대시보드 동기화 요청
    ///
    /// - Parameter onError: 전송 실패 시 호출되는 콜백
    func requestDashboardSync(onError: (() -> Void)? = nil) {
        let message: [String: Any] = [
            WatchMessageKey.requestDashboardSync: true,
            WatchMessageKey.timestamp: Date().timeIntervalSince1970
        ]

        sendMessage(message, replyHandler: { reply in
            Log.debug("iPhone 응답 수신: \(reply)")
        }, errorHandler: { error in
            Log.error("대시보드 동기화 요청 실패: \(error.localizedDescription)")
            onError?()
        })
    }

    /// iPhone에 즉시 메시지 전송
    func sendMessage(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)? = nil,
        errorHandler: ((Error) -> Void)? = nil
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

        Log.debug("메시지 전송: \(message[WatchMessageKey.type] as? String ?? message.keys.first ?? "unknown")")
    }

    /// iPhone에 백그라운드 데이터 전송
    func transferUserInfo(_ userInfo: [String: Any]) {
        guard let session = session else {
            Log.warning("WCSession 없음 - UserInfo 전송 실패")
            return
        }

        session.transferUserInfo(userInfo)
        Log.debug("UserInfo 전송: \(userInfo[WatchMessageKey.type] as? String ?? "unknown")")
    }

    /// 마지막으로 수신한 Application Context 조회
    ///
    /// Watch 앱 실행 시 iPhone이 응답하기 전에 캐시된 최신 상태를 바로 로드할 수 있습니다.
    func loadCachedApplicationContext() -> [String: Any]? {
        guard let session = session else { return nil }

        let context = session.receivedApplicationContext
        guard !context.isEmpty else { return nil }

        Log.debug("캐시된 Application Context 로드: \(context[WatchMessageKey.type] as? String ?? "unknown")")
        return context
    }
}

// MARK: - WCSessionDelegate

extension WatchSessionManager: WCSessionDelegate {

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
            Log.info("iPhone 연결 상태 변경: \(session.isReachable)")
        }
    }

    // MARK: - Message Handling

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        DispatchQueue.main.async { [weak self] in
            Log.debug("메시지 수신 (reply 포함): \(message[WatchMessageKey.type] as? String ?? "unknown")")
            self?.onMessageReceived?(message)

            let reply: [String: Any] = [
                "status": "received",
                WatchMessageKey.timestamp: Date().timeIntervalSince1970
            ]
            replyHandler(reply)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            Log.debug("메시지 수신: \(message[WatchMessageKey.type] as? String ?? "unknown")")
            self?.onMessageReceived?(message)
        }
    }

    // MARK: - UserInfo Handling

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        DispatchQueue.main.async { [weak self] in
            Log.debug("UserInfo 수신: \(userInfo[WatchMessageKey.type] as? String ?? "unknown")")
            self?.onUserInfoReceived?(userInfo)
        }
    }

    // MARK: - Application Context Handling

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            Log.debug("Application Context 수신: \(applicationContext[WatchMessageKey.type] as? String ?? "unknown")")
            self?.onApplicationContextReceived?(applicationContext)
        }
    }
}

