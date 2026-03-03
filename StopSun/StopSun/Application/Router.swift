//
//  Router.swift
//  StopSun
//
//  Created by J on 2/15/26.
//

import Foundation
import SwiftUI

/// 네비게이션 라우터
///
/// NavigationStack의 path를 관리하여 화면 전환을 처리합니다.
/// 온보딩 완료 이후의 화면 전환만 담당합니다.
///
/// ## 구조
/// ```
/// ContentView
/// ├── 온보딩 미완료 → OnboardingContainerView (Router 미사용)
/// └── 온보딩 완료 → NavigationStack(path: router.path)
///                     └── DashboardView (root)
///                         ├── push(.settings) → SettingsView
///                         └── ...
/// ```
///
/// ## 사용법
/// ```swift
/// // View에서
/// @Environment(Router.self) private var router
///
/// Button("설정") {
///     router.push(.settings)
/// }
/// ```
///
@MainActor
@Observable
final class Router {

    // MARK: - Properties
    
    /// NavigationStack에 바인딩할 path
    var path = NavigationPath()

    // MARK: - Navigation

    /// 화면 push
    func push(_ route: Route) {
        path.append(route)
    }

    /// 이전 화면으로 pop
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// 루트 화면으로 이동
    func popToRoot() {
        path.removeLast(path.count)
    }
}
