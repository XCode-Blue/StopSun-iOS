//
//  IntroductionAnimatedGaugeView.swift
//  StopSun
//
//  Created by taeni on 2/11/26.
//

import SwiftUI
import Combine

/// 온보딩 전용 MED 게이지 애니메이션 뷰
struct IntroductionAnimatedGaugeView: View {
    
    @State private var currentLevel: WarningLevel = .safe
    @State private var animatedPercentage: Double = WarningLevel.safe.demoPercentage
    
    /// .common RunLoop → TabView 스와이프 중에도 타이머 동작 보장
    private let timerPublisher = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 32) {
            
            // 게이지
            MEDGaugeView(
                percentage: animatedPercentage,
                color: currentLevel.color
            )
            
            // 상태 텍스트 영역 (레이아웃 고정)
            VStack(spacing: 12) {
                
                Text(currentLevel.title)
                    .font(.ssFont(.B1))
                    .foregroundStyle(currentLevel.color)
                    .animation(.easeInOut(duration: 0.4), value: currentLevel)
                
                Text(currentLevel.statusDescription)
                    .font(.ssFont(.R2))
                    .foregroundStyle(.text02)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44) // 텍스트 길이로 인한 흔들림 방지
                    .animation(.easeInOut(duration: 0.4), value: currentLevel)
            }
        }
        .onAppear {
            currentLevel = .safe
            animatedPercentage = WarningLevel.safe.demoPercentage
        }
        .onReceive(timerPublisher) { _ in
            let nextLevel = currentLevel.next
            withAnimation(.easeInOut(duration: 0.5)) {
                currentLevel = nextLevel
                animatedPercentage = nextLevel.demoPercentage
            }
        }
    }
}
