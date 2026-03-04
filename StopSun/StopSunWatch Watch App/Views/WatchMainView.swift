//
//  WatchMainView.swift
//  StopSunWatch Watch App
//
//  Created by J on 2/25/26.
//

import SwiftUI

/// Watch 메인 화면
///
/// ## 네비게이션
/// - 화면 탭 → MED ↔ UVI 전환
/// - Digital Crown (수직 페이지) → 선크림 타이머
///
struct WatchMainView: View {
    
    @StateObject var viewModel: WatchMainViewModel
    @State private var showingUVI = false
    
    var body: some View {
        TabView {
            // Page 1: MED ↔ UVI (탭 전환)
            ZStack {
                if showingUVI {
                    UVIndexView(viewModel: viewModel)
                        .transition(.opacity)
                } else {
                    MEDView(viewModel: viewModel)
                        .transition(.opacity)
                }
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showingUVI.toggle()
                }
            }
            
            // Page 2: 선크림 타이머
            SunscreenTimerView(viewModel: viewModel)
        }
        .tabViewStyle(.verticalPage)
    }
}

// MARK: - Preview

#Preview("Safe") {
    WatchMainView(viewModel: .safe)
}

#Preview("Caution + Timer") {
    WatchMainView(viewModel: .caution)
}

#Preview("Warning + Expired") {
    WatchMainView(viewModel: .warning)
}

#Preview("Danger") {
    WatchMainView(viewModel: .danger)
}
