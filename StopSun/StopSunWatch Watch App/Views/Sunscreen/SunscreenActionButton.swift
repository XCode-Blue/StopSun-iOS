//
//  SunscreenActionButton.swift
//  StopSunWatch Watch App
//
//  Created by J on 2/25/26.
//

import SwiftUI

/// 선크림 타이머 하단 액션 버튼
///
/// 시작 / 갱신 / 재시작에 공통으로 사용됩니다.
///
struct SunscreenActionButton: View {
    
    private let title: String
    private let action: () -> Void
    
    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.black.opacity(0.12))
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}
