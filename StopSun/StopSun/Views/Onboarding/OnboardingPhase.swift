//
//  OnboardingPhase.swift
//  StopSun
//
//  Created by taeni on 2/10/26.
//

import Foundation

// MARK: - Onboarding Phase

/// 온보딩 단계 (2개 Phase)
///
/// | Phase | 내용 | UI |
/// |-------|------|-----|
/// | introduction | 서비스 설명 (3페이지) | 페이지 인디케이터, 건너뛰기 |
/// | setup | 워치 → 권한 → 스킨타입 | 프로그레스 바, 뒤로가기 |
///
enum OnboardingPhase {
    case introduction
    case setup
}

// MARK: - Introduction Page

/// 서비스 설명 페이지 (3페이지)
enum IntroductionPage: Int, CaseIterable {
    case trackExposure = 0      // 일광 노출 추적
    case realTimeAlert = 1      // 실시간 자외선 알림
    case personalRecommend = 2  // 개인 맞춤 추천
}

// MARK: - Setup Step

/// 설정 단계 (3단계)
///
/// | 단계 | Progress | 내용 |
/// |------|----------|------|
/// | watchCheck | 1/3 | Apple Watch 보유 여부 확인 |
/// | permission | 2/3 | HealthKit → Location → Notification 권한 요청 |
/// | skinType | 3/3 | 피부 타입 선택 |
///
enum SetupStep: Int, CaseIterable {
    case watchCheck = 0
    case permission = 1
    case skinType = 2
}

// MARK: - Watch Alert Type

/// Watch 관련 Alert 분기
enum WatchAlertType {
    /// "아니오" 선택 → Watch 보유 권장
    case noWatch
    /// "네" 선택했으나 페어링 감지 안 됨 (미지원 모델 또는 미페어링)
    case notPaired
}
