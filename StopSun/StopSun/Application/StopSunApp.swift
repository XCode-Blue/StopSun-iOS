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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.localStorage, container.localStorage)
                .environment(container.permissionManager)
                .environmentObject(container.syncCoordinator)
                .environmentObject(container.errorHandler)
                .onChange(of: scenePhase) { _, newPhase in
                    handleScenePhaseChange(newPhase)
                }
        }
    }
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
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
