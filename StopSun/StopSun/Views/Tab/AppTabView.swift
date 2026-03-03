//
//  AppTabView.swift
//  StopSun
//
//  Created by J on 2/23/26.
//

import SwiftUI

struct AppTabView: View {
    
    @State private var selectedTab: AppTab = .dashboard
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            // MARK: - 대시보드
            
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                tabLabel(for: .dashboard)
            }
            .tag(AppTab.dashboard)
            
            // MARK: - 정보
            
            NavigationStack {
                InfoPlaceholderView()
            }
            .tabItem {
                tabLabel(for: .info)
            }
            .tag(AppTab.info)
            
            // MARK: - 설정
            
            NavigationStack {
                SettingsPlaceholderView()
            }
            .tabItem {
                tabLabel(for: .settings)
            }
            .tag(AppTab.settings)
        }
         .tint(.text00)
         .onAppear {
             let appearance = UITabBarAppearance()
             appearance.backgroundColor = UIColor(.white00)
             appearance.shadowColor = UIColor(.gray01)
             UITabBar.appearance().standardAppearance = appearance
             UITabBar.appearance().scrollEdgeAppearance = appearance
         }
    }
    
    // MARK: - Tab Label
    
    @ViewBuilder
    private func tabLabel(for tab: AppTab) -> some View {
        let icon = selectedTab == tab ? tab.selectedIconName : tab.iconName
        Image(icon)
        Text(tab.title)
    }
}

// MARK: - Placeholder Views

/// 정보 탭 placeholder (추후 실제 화면으로 교체)
struct InfoPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.white01.ignoresSafeArea()
            
            VStack(spacing: 12) {
                Image(systemName: "info.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.text04)
                
                Text("정보")
                    .font(.ssFont(.SB4))
                    .foregroundStyle(.text00)
                
                Text("자외선 정보성 글이 여기 표시됩니다.")
                    .font(.ssFont(.R3))
                    .foregroundStyle(.text04)
            }
        }
    }
}

/// 설정 탭 placeholder (추후 실제 화면으로 교체)
struct SettingsPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.white01.ignoresSafeArea()
            
            VStack(spacing: 12) {
                Image(systemName: "gearshape")
                    .font(.system(size: 48))
                    .foregroundStyle(.text04)
                
                Text("설정")
                    .font(.ssFont(.SB4))
                    .foregroundStyle(.text00)
                
                Text("앱 설정이 여기에 표시됩니다")
                    .font(.ssFont(.R3))
                    .foregroundStyle(.text04)
                
                NavigationLink(value: Route.skinTypeSettings) {
                    Text("스킨타입 설정")
                }
                
                NavigationLink("스킨타입 설정(라우터없이)") {
                    EmptyView()
                }
            }
        }
        .navigationDestination(for: Route.self) { route in
            switch route {
            case .skinTypeSettings:
                EmptyView()
            }
        }
    }
}

#Preview {
    AppTabView()
}
