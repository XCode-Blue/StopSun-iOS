//
//  DashboardView.swift
//  StopSun
//
//  Created by taeni on 9/16/25.
//

import SwiftUI

struct DashboardView: View {
    
    @State private var viewModel: DashboardViewModel
    @Environment(\.scenePhase) private var scenePhase
#if DEBUG
    @State private var showDebugSheet = false
#endif
    
    init(viewModel: DashboardViewModel? = nil) {
        self._viewModel = State(wrappedValue: viewModel ?? DIContainer.shared.makeDashboardViewModel())
    }
    
    var body: some View {
        ZStack {
            Color.white01.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection
                    
                    cardCarousel
                        .padding(.vertical, 32)
                    
                    pageIndicator
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 40)
                    
                    weatherSection
                    
                    chartSection
                        .padding(.top, 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
        }
        .task {
            await viewModel.onAppear()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await viewModel.onAppear() }
            }
        }
#if DEBUG
        .safeAreaInset(edge: .bottom) {
            Button {
                showDebugSheet = true
            } label: {
                Text("🐛 Debug")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.black.opacity(0.7)))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showDebugSheet) {
            DashboardDebugView(syncCoordinator: viewModel.debugSyncCoordinator)
        }
#endif
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.formattedDate)
                .font(.ssFont(.R3))
                .foregroundStyle(.text00)
            
            VStack(alignment: .leading, spacing: 4) {
                (
                    Text(L10n.MED.Status.prefix)
                        .foregroundStyle(.text00) +
                    Text(viewModel.warningLevel.title)
                        .foregroundStyle(viewModel.warningLevel.color) +
                    Text(L10n.MED.Status.suffix)
                        .foregroundStyle(viewModel.warningLevel.color)
                )
                .font(.ssFont(.SB4))
                
                Text(viewModel.warningLevel.statusDescription)
                    .font(.ssFont(.R5))
                    .foregroundStyle(.text04)
            }
        }
    }
    
    // MARK: - Card Carousel
    
    private var cardCarousel: some View {
        TabView(selection: $viewModel.currentPage) {
            DashboardMEDCardView(
                percentage: viewModel.medPercentage,
                currentValue: viewModel.currentMED,
                maxValue: viewModel.maxMED,
                color: viewModel.warningLevel.color
            )
            .padding(.horizontal, 20)
            .tag(0)
            
            sunscreenTimerCard
                .padding(.horizontal, 20)
                .tag(1)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 265)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white00)
        )
    }
    
    /// 선크림 타이머 카드 (TimelineView로 1초 갱신)
    private var sunscreenTimerCard: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            SunscreenTimerCardView(
                remainingTime: viewModel.timerRemaining(at: context.date),
                isTimerActive: viewModel.isTimerActive
            )
        }
    }
    
    // MARK: - Page Indicator
    
    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<2, id: \.self) { index in
                Circle()
                    .fill(index == viewModel.currentPage ? Color.key00 : Color.gray00)
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.currentPage)
            }
        }
    }
    
    // MARK: - Weekly Chart
    
    private var chartSection: some View {
        WeeklyMEDChartView(items: viewModel.weeklyChartItems)
    }
    
    // MARK: - Weather
    
    private var weatherSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Dashboard.Weather.title(viewModel.locationName))
                .font(.ssFont(.M4))
                .foregroundStyle(.text00)
            
            HStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text(L10n.Dashboard.Weather.uvIndex)
                        .font(.ssFont(.R1))
                        .foregroundStyle(.text03)
                    
                    Text("\(viewModel.uvIndex)")
                        .font(.ssFont(.SB4))
                        .foregroundStyle(.text00)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 40)
                
                VStack(spacing: 8) {
                    Text(L10n.Dashboard.Weather.temperature)
                        .font(.ssFont(.R1))
                        .foregroundStyle(.text03)
                    
                    Text("\(Int(viewModel.temperature))°C")
                        .font(.ssFont(.SB4))
                        .foregroundStyle(.text00)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white00)
            )
        }
    }
}

// MARK: - Preview

#Preview("Safe (0~30%)") {
    DashboardView(viewModel: DashboardViewModel(
        syncCoordinator: .preview(totalSED: 0.8, uvIndex: 3)
    ))
}

#Preview("Caution (30~50%)") {
    DashboardView(viewModel: DashboardViewModel(
        syncCoordinator: .preview(totalSED: 1.6, uvIndex: 6)
    ))
}

#Preview("Warning (50~70%)") {
    DashboardView(viewModel: DashboardViewModel(
        syncCoordinator: .preview(totalSED: 2.4, uvIndex: 8)
    ))
}

#Preview("Danger (70%+)") {
    DashboardView(viewModel: DashboardViewModel(
        syncCoordinator: .preview(totalSED: 3.5, uvIndex: 9, temperature: 32)
    ))
}

#Preview("선크림 활성") {
    DashboardView(viewModel: DashboardViewModel(
        syncCoordinator: .preview(
            totalSED: 1.0,
            uvIndex: 7,
            activeSunscreen: SunscreenApplication(spfLevel: .spf50)
        )
    ))
}
