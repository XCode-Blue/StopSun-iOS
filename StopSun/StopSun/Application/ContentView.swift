//
//  ContentView.swift
//  StopSun
//
//  Created by taeni on 9/16/25.
//

import SwiftUI

struct ContentView: View {
    
    @State private var showSplash = true
    
    @State private var isOnboardingCompleted =
        UserProfileManager.shared.fetchOnboardingCompleted()
    
    var body: some View {
        ZStack {
            
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                if isOnboardingCompleted {
                    DashboardView()
                } else {
                    OnboardingContainerView()
                }
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.easeInOut(duration: 0.4)) {
                showSplash = false
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UserProfileManager.userProfileDidChangeNotification
            )
        ) { _ in
            isOnboardingCompleted =
                UserProfileManager.shared.fetchOnboardingCompleted()
        }
    }
}
