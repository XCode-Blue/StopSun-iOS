//
//  MEDGaugeView.swift
//  StopSun
//
//  Created by taeni on 2/11/26.
//

import SwiftUI

/// MED 퍼센트를 표시하는 반원 게이지 뷰
///
/// ## 기능
/// - 0-100% 값을 반원 게이지로 시각화
/// - 색상이 퍼센트에 따라 변경 (안전→주의→위험)
/// - 부드러운 애니메이션 지원
///
/// ## 사용 예시
/// ```swift
/// MEDGaugeView(
///     percentage: 73,
///     color: .orange
/// )
/// ```
struct MEDGaugeView: View {
    
    let percentage: Double
    let color: Color
    
    private let lineWidth: CGFloat = 12
    
    private var clampedPercentage: Double {
        min(max(percentage, 0), 100) // 0 이상, 100 이하로 고정
    }
    
    var body: some View {
        ZStack {
            
            // 배경 반원
            HalfArcShape(progress: 1.0)
                .strokeBorder(
                    .gray00.opacity(0.2),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
            
            // 진행 반원
            HalfArcShape(progress: clampedPercentage / 100)
                .strokeBorder(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .animation(.easeInOut(duration: 0.3), value: percentage)
            
            // 중앙 텍스트
            VStack(spacing: 4) {
                Spacer()
                
                Text(L10n.MED.Gauge.title)
                    .font(.ssFont(.R3))
                    .foregroundStyle(.text03)
                
                Text(L10n.MED.Gauge.percentage(Int(percentage)))
                    .font(.ssFont(.B2))
                    .foregroundStyle(color)
                    .contentTransition(.numericText())
            }
        }
        .aspectRatio(2, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }
}


// MARK: - Preview

#Preview("MED Gauge - Safe") {
    MEDGaugeView(
        percentage: 31,
        color: .gage00
    )
    .padding()
}

#Preview("MED Gauge - Caution") {
    MEDGaugeView(
        percentage: 73,
        color: .gage01
    )
    .padding()
}

#Preview("MED Gauge - Danger") {
    MEDGaugeView(
        percentage: 97,
        color: .gage02
    )
    .padding()
}
