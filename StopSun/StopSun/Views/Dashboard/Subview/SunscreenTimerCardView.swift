//
//  SunscreenTimerCardView.swift
//  StopSun
//
//  Created by J on 2/21/26.
//

import SwiftUI

struct SunscreenTimerCardView:
    View {
    
    let remainingTime: String
    let isTimerActive: Bool
    
    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            VStack {
                // 날씨 아이콘
                Image(systemName: "cloud.sun")
                    .font(.system(size: 32))
                    .foregroundStyle(.key00)
                
                // 타이머
                Text(remainingTime)
                    .font(.ssFont(.SB5))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.key00)
            }

            // 안내 문구
            Text("선크림 타이머를\n워치에서 작동시켜주세요")
                .font(.ssFont(.M2))
                .multilineTextAlignment(.center)
                .foregroundStyle(.text02)
            
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

#Preview("Timer 비활성") {
    SunscreenTimerCardView(
        remainingTime: "00:00",
        isTimerActive: false
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Timer 활성") {
    SunscreenTimerCardView(
        remainingTime: "01:32",
        isTimerActive: true
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}
