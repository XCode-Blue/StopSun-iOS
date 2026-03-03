//
//  Route.swift
//  StopSun
//
//  Created by J on 2/15/26.
//

import Foundation

/// NavigationStack push 대상 화면
///
/// 탭 안에서 화면을 push할 때 사용합니다.
/// 탭 선택 자체는 `AppTab`이 담당합니다.
///
/// ## 사용 예시
/// ```swift
/// router.push(.recordDetail(id: "2026-02-23"))
/// router.push(.profileEdit)
/// ```
///
enum Route: Hashable {
    // TODO: 탭 내부 push 화면 추가 시 여기에 정의
    case skinTypeSettings
}
