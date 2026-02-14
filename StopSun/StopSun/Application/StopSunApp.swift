//
//  StopSunApp.swift
//  StopSun
//
//  Created by taeni on 9/16/25.
//

import SwiftUI

@main
struct StopSunApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
    
    private let container = DIContainer.shared
    
    /// 온보딩 완료 여부
    ///
    /// `UserProfileManager`의 저장값을 기준으로 판단합니다.
    @State private var isOnboardingCompleted = UserProfileManager.shared.fetchOnboardingCompleted()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(container.permissionManager)
                .environmentObject(container.syncCoordinator)
                .environmentObject(container.errorHandler)
                .onChange(of: scenePhase) { _, newPhase in
                    handleScenePhaseChange(newPhase)
                }
        }
    }
    
    // MARK: - Scene Phase
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // 설정 앱에서 변경한 권한 반영
            Task {
                await container.permissionManager.checkAllStatuses()
            }
        case .background, .inactive:
            break
        @unknown default:
            break
        }
    }
}
