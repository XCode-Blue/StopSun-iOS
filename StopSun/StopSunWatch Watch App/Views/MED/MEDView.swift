//
//  MEDView.swift
//  StopSunWatch Watch App
//
//  Created by J on 2/25/26.
//

import SwiftUI

/// MED 진행률 화면
struct MEDView: View {
    
    @ObservedObject var viewModel: WatchMainViewModel
    
    private var level: WarningLevel { viewModel.warningLevel }
    
    var body: some View {
        ZStack {
            level.watchBackground.ignoresSafeArea()
            
            // 퍼센트 + 상태
            VStack {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(viewModel.medPercentage)")
                        .font(.system(size: 64, weight: .bold))
                    Text("%")
                        .font(.system(size: 48, weight: .bold))
                }
                .foregroundStyle(level.watchText)
                 
                Text(level.title)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 32)
            
            // 하단 설명
            VStack {
                Spacer()
                
                Text(level.statusDescription)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
            }
            .padding(.bottom, 12)
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - Preview

#Preview("안전") {
    MEDView(viewModel: .safe)
}

#Preview("주의") {
    MEDView(viewModel: .caution)
}

#Preview("위험") {
    MEDView(viewModel: .warning)
}

#Preview("나쁨") {
    MEDView(viewModel: .danger)
}
