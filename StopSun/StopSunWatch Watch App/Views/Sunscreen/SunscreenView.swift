//
//  SunscreenTimerView.swift
//  StopSunWatch Watch App
//
//  Created by J on 2/25/26.
//

import SwiftUI

/// 선크림 타이머 화면
///
/// Digital Crown으로 MED/UVI에서 전환하여 접근합니다.
///
/// ## Active 상태 인터랙션 (피트니스 앱 패턴)
/// - 기본: 카운트다운 타이머만 표시
/// - 좌로 스와이프: 컨트롤 패널 (중단 / 갱신)
///
/// 시안: 타이머_1(미도포), 타이머_2(진행 중), 타이머_3(만료)
///
struct SunscreenTimerView: View {
    
    @ObservedObject var viewModel: WatchMainViewModel
    
    var body: some View {
        ZStack {
            viewModel.timerState.gradient.ignoresSafeArea()
            
            switch viewModel.timerState {
            case .idle:    IdleContent(onStart: viewModel.applySunscreen)
            case .active:  ActivePager(viewModel: viewModel)
            case .expired: ExpiredContent(onRestart: viewModel.applySunscreen)
            }
        }
        .onAppear { viewModel.startTimer() }
        .onDisappear { viewModel.stopTimer() }
    }
}

// MARK: - Active Pager (피트니스 앱 패턴)

private extension SunscreenTimerView {
    
    /// 스와이프 가능한 Active 상태
    ///
    /// Page 0: 컨트롤 (중단 + 갱신)
    /// Page 1: 카운트다운 타이머 (기본)
    ///
    struct ActivePager: View {
        @ObservedObject var viewModel: WatchMainViewModel
        @State private var currentPage: Int = 1
        
        var body: some View {
            TabView(selection: $currentPage) {
                ControlContent(
                    onCancel: viewModel.cancelSunscreen,
                    onRefresh: {
                        viewModel.applySunscreen()
                        currentPage = 1              // ← 타이머 페이지로 전환
                    }
                )
                .tag(0)
                
                TimerContent(timerText: viewModel.timerText)
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
        }
    }
    
    /// 컨트롤 패널 (Page 0)
    struct ControlContent: View {
        let onCancel: () -> Void
        let onRefresh: () -> Void
        
        var body: some View {
            VStack(spacing: 12) {
                Spacer()
                
                Button(action: onCancel) {
                    Label(L10n.Timer.stop, systemImage: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.black.opacity(0.12))
                
                Button(action: onRefresh) {
                    Label(L10n.Timer.refresh, systemImage: "arrow.clockwise")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.gage00)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }
    
    /// 카운트다운 (Page 1, 기본)
    struct TimerContent: View {
        let timerText: String
        
        var body: some View {
            VStack {
                Spacer()
                
                Text(L10n.Timer.untilReapply)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white00)
                
                Text(timerText)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white00)
                    .monospacedDigit()
                    .padding(.bottom, 20)
                
                Spacer()
            }
        }
    }
}

// MARK: - Idle / Expired

private extension SunscreenTimerView {
    
    /// 미도포
    struct IdleContent: View {
        let onStart: () -> Void
        
        var body: some View {
            VStack {
                Spacer()
                
                Text(L10n.Timer.startPrompt)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                
                Spacer()
                SunscreenActionButton(L10n.Timer.start, action: onStart)
            }
        }
    }
    
    /// 타이머 만료 
    struct ExpiredContent: View {
        let onRestart: () -> Void
        
        var body: some View {
            VStack {
                Spacer()
                
                Text(L10n.Timer.Alert.reapply)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white00)
                
                Text("0:00")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(.white00)
                    .monospacedDigit()
                
                Spacer()
                SunscreenActionButton(L10n.Timer.restart, action: onRestart)
            }
        }
    }
}

// MARK: - Preview

#Preview("미도포") { SunscreenTimerView(viewModel: .safe) }
#Preview("진행 중") { SunscreenTimerView(viewModel: .caution) }
#Preview("만료") { SunscreenTimerView(viewModel: .warning) }
