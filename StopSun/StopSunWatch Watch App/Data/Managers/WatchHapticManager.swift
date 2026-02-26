//
//  WatchHapticManager.swift
//  StopSunWatch Watch App
//
//  Created by StopSun Team
//

import WatchKit

/// Apple Watch의 햅틱 피드백을 관리하는 Manager 클래스
/// - MVVM 아키텍처: Model Layer
/// - DIContainer를 통해 주입됩니다.
/// - **포그라운드 전용**: 백그라운드에서는 WatchTimerNotificationManager의 알림 사운드 사용
@MainActor
final class WatchHapticManager {

    // MARK: - Properties

    /// WKInterfaceDevice 인스턴스를 한 번만 가져와서 재사용
    private let device = WKInterfaceDevice.current()

    // MARK: - Initializer

    /// DIContainer에서 주입받아 사용하는 생성자
    init() {}

    // MARK: - Public Methods

    /// 성공적인 작업 완료 시 햅틱 (예: 데이터 저장 성공)
    func playSuccessHaptic() {
        play(.success, logMessage: "성공 햅틱 재생")
    }

    /// 일반적인 UI 인터랙션 햅틱 (예: 버튼 탭, 스위치 토글)
    func playClickHaptic() {
        play(.click, logMessage: "클릭 햅틱 재생")
    }

    /// 앱 내 알림 표시 시 햅틱 (예: 경고 메시지)
    func playNotificationHaptic() {
        play(.notification, logMessage: "알림 햅틱 재생")
    }

    /// 에러 발생 시 햅틱 (예: 유효하지 않은 입력)
    func playErrorHaptic() {
        play(.failure, logMessage: "에러 햅틱 재생")
    }

    /// 타이머 시작 시 햅틱 (포그라운드에서 시작 버튼 탭 시)
    func playStartHaptic() {
        play(.start, logMessage: "시작 햅틱 재생")
    }

    /// 타이머 정지 시 햅틱 (포그라운드에서 정지 버튼 탭 시)
    func playStopHaptic() {
        play(.stop, logMessage: "정지 햅틱 재생")
    }

    // MARK: - Private Methods

    /// 햅틱을 재생하고 로그를 출력하는 헬퍼 메서드
    /// - DRY 원칙: 중복 코드를 제거하고 로깅 방식을 한 곳에서 관리
    /// - TODO: 추후 print를 Logger로 변경 시 이 메서드만 수정하면 됨
    ///
    /// - Parameters:
    ///   - hapticType: 재생할 햅틱 타입
    ///   - logMessage: 로그 메시지
    private func play(_ hapticType: WKHapticType, logMessage: String) {
        device.play(hapticType)
        print("[Watch] \(logMessage)")
    }
}
