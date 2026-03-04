//
//  UVIndexView.swift
//  StopSunWatch Watch App
//
//  Created by J on 2/25/26.
//

import SwiftUI

/// UV Index 화면
struct UVIndexView: View {
    
    @ObservedObject var viewModel: WatchMainViewModel
    
    private var level: UVLevel { viewModel.uvLevel }
    
    var body: some View {
        ZStack {
            level.watchBackground.ignoresSafeArea()
            
            VStack {
                Text("\(Int(viewModel.currentUVIndex))")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(.white00)
                
                // "자외선" 라벨
                Text("자외선")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white00)
            }
            .padding(.bottom, 32)
            
            // 하단 설명
            VStack {
                Spacer()
                
                Text(level.displayTitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.white00)
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

#Preview("낮음 · UV 2") { UVIndexView(viewModel: .safe) }

#Preview("보통 · UV 5") { UVIndexView(viewModel: .caution) }

#Preview("높음 · UV 8") { UVIndexView(viewModel: .warning) }

#Preview("위험 · UV 11") { UVIndexView(viewModel: .danger) }




































