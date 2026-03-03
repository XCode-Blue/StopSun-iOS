//
//  ContentView.swift
//  StopSun
//
//  Created by taeni on 9/16/25.
//

import SwiftUI

struct ContentView: View {
    
    // MARK: - Dependencies
    
    @Environment(\.localStorage) private var localStorage
    
    // MARK: - State
    
    @State private var showSplash = true
    @State private var isOnboardingCompleted = false
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                if isOnboardingCompleted {
                    AppTabView()
                } else {
                    OnboardingContainerView()
                }
            }
        }
        .onAppear {
            isOnboardingCompleted = localStorage.loadOnboardingCompleted()
        }
        .task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.easeInOut(duration: 0.4)) {
                showSplash = false
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: .userProfileDidChange
            )
        ) { _ in
            isOnboardingCompleted = localStorage.loadOnboardingCompleted()
        }
    }
}
