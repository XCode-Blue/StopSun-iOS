//
//  SunscreenTimerCardView.swift
//  StopSun
//
//  Created by J on 2/21/26.
//

import SwiftUI

/// 선크림 타이머 카드
///
/// - 비활성 상태: "선크림을 다시 바를 수 있도록 알려줄게요" + 도포 버튼
/// - 활성 상태: 남은 시간 카운트다운 + 종료 버튼
struct SunscreenTimerCardView: View {

    let remainingTime: String
    let isTimerActive: Bool
    let onStart: () -> Void
    let onStop: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "cloud.sun")
                    .font(.system(size: 32))
                    .foregroundStyle(.key00)

                Text(isTimerActive ? remainingTime : L10n.Sunscreen.Card.inactive)
                    .font(isTimerActive ? .ssFont(.SB5) : .ssFont(.SB1))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.key00)
            }

            if isTimerActive {
                SSButton(L10n.Sunscreen.Card.stop, style: .secondary) {
                    onStop()
                }
                .padding(.horizontal, 20)
            } else {
                SSButton(L10n.Sunscreen.Card.start, style: .primary) {
                    onStart()
                }
                .padding(.horizontal, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

#Preview("Timer 비활성") {
    SunscreenTimerCardView(
        remainingTime: "00:00",
        isTimerActive: false,
        onStart: {},
        onStop: {}
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Timer 활성") {
    SunscreenTimerCardView(
        remainingTime: "01:32",
        isTimerActive: true,
        onStart: {},
        onStop: {}
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}
