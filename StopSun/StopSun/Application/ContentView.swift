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
    
    @State private var isOnboardingCompleted = false
    
    var body: some View {
        ZStack {
            if isOnboardingCompleted {
                AppTabView()
            } else {
                OnboardingContainerView()
            }
        }
        .onAppear {
            isOnboardingCompleted = localStorage.loadOnboardingCompleted()
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
