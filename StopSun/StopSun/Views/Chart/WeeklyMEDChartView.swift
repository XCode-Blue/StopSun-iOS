//
//  WeeklyMEDChartView.swift
//  StopSun
//
//  Created by J on 2/26/26.
//

import SwiftUI

// MARK: - Constants

private enum ChartLayout {
    static let barCornerRadius: CGFloat = 10
    static let barSpacing: CGFloat = 10
    static let chartHeight: CGFloat = 140
    static let minBarHeight: CGFloat = 10
    static let cardCornerRadius: CGFloat = 20
    static let horizontalPadding: CGFloat = 16
    static let verticalPadding: CGFloat = 18
    static let labelBarGap: CGFloat = 10
    static let overLabelBarGap: CGFloat = 4
}

// MARK: - 주간 MED 차트 뷰

/// 최근 7일간의 MED 데이터를 바 차트로 표시하는 뷰
///
/// ViewModel에서 정렬된 7개의 `WeeklyBarItem`을 받아 그대로 렌더링합니다.
/// View는 정렬/계산 없이 그리기만 담당합니다.
///
/// ## 컬러셋
/// - `chart00`: 배경 바 (#F2F2F7)
/// - `chart01`: 기본 바 (#CDCED3)
/// - `chart02`: 초과 바 (#636366)
///
struct WeeklyMEDChartView: View {
    
    let items: [WeeklyBarItem]
    
    private var maxPercent: Double {
        let dataMax = items.compactMap(\.percent).max() ?? 0
        return max(dataMax, 100)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            bars
                .padding(.bottom, ChartLayout.labelBarGap)
            dayLabels
        }
        .padding(.horizontal, ChartLayout.horizontalPadding)
        .padding(.vertical, ChartLayout.verticalPadding)
        .background(.white00)
        .clipShape(RoundedRectangle(cornerRadius: ChartLayout.cardCornerRadius))
    }
}

// MARK: - Subviews

private extension WeeklyMEDChartView {
    
    var header: some View {
        HStack {
            Text("주간 자외선 노출 요약")
                .font(.ssFont(.SB2))
                .foregroundStyle(.text00)
            
            Spacer()
            
            Text("최근 7일")
                .font(.ssFont(.M1))
                .foregroundStyle(.text04)
        }
        .padding(.bottom, ChartLayout.verticalPadding)
    }
    
    var bars: some View {
        HStack(spacing: ChartLayout.barSpacing) {
            ForEach(items) { item in
                ChartBarColumn(
                    item: item,
                    maxPercent: maxPercent
                )
            }
        }
    }
    
    var dayLabels: some View {
        HStack(spacing: ChartLayout.barSpacing) {
            ForEach(items) { item in
                Text(item.dayLabel)
                    .font(.ssFont(.R1))
                    .foregroundStyle(dayLabelColor(for: item))
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    func dayLabelColor(for item: WeeklyBarItem) -> Color {
        if item.isToday { return .text00 }
        if item.percent != nil { return .text04 }
        return .text05
    }
}

// MARK: - 개별 바 컬럼

/// 초과 라벨 + 바 한 쌍을 담당하는 뷰
private struct ChartBarColumn: View {
    
    let item: WeeklyBarItem
    let maxPercent: Double
    
    private var isOver: Bool {
        (item.percent ?? 0) >= 100
    }
    
    var body: some View {
        VStack(spacing: ChartLayout.overLabelBarGap) {
            overLabel
            barShape
        }
    }
    
    @ViewBuilder
    private var overLabel: some View {
        if let percent = item.percent {
            Text("\(Int(percent))%")
                .font(.ssFont(.M1))
                .foregroundStyle(isOver ? .text00 : .text04)
        } else {
            Text(" ")
                .font(.ssFont(.M1))
                .hidden()
        }
    }
    
    private var barShape: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: ChartLayout.barCornerRadius)
                    .fill(.chart00)
                
                if let percent = item.percent, percent > 0 {
                    RoundedRectangle(cornerRadius: ChartLayout.barCornerRadius)
                        .fill(isOver ? .chart02 : .chart01)
                        .frame(height: barHeight(in: geo.size.height))
                }
            }
        }
        .frame(height: ChartLayout.chartHeight)
    }
    
    private func barHeight(in totalHeight: CGFloat) -> CGFloat {
        guard let percent = item.percent, percent > 0 else { return 0 }
        let ratio = min(percent / maxPercent, 1.0)
        return max(ratio * totalHeight, ChartLayout.minBarHeight)
    }
}

// MARK: - Preview

#Preview("풀 데이터") {
    WeeklyMEDChartView(items: [
        .init(dayLabel: "금", percent: 24, isToday: false),
        .init(dayLabel: "토", percent: 92, isToday: false),
        .init(dayLabel: "일", percent: 128, isToday: false),
        .init(dayLabel: "월", percent: 45, isToday: false),
        .init(dayLabel: "화", percent: 86, isToday: false),
        .init(dayLabel: "수", percent: 39, isToday: false),
        .init(dayLabel: "목", percent: 67, isToday: true),
    ])
    .padding()
    .background(.white01)
}

#Preview("설치 3일째") {
    WeeklyMEDChartView(items: [
        .init(dayLabel: "금", percent: nil, isToday: false),
        .init(dayLabel: "토", percent: nil, isToday: false),
        .init(dayLabel: "일", percent: nil, isToday: false),
        .init(dayLabel: "월", percent: nil, isToday: false),
        .init(dayLabel: "화", percent: 72, isToday: false),
        .init(dayLabel: "수", percent: 45, isToday: false),
        .init(dayLabel: "목", percent: 30, isToday: true),
    ])
    .padding()
    .background(.white01)
}

#Preview("첫날") {
    WeeklyMEDChartView(items: [
        .init(dayLabel: "금", percent: nil, isToday: false),
        .init(dayLabel: "토", percent: nil, isToday: false),
        .init(dayLabel: "일", percent: nil, isToday: false),
        .init(dayLabel: "월", percent: nil, isToday: false),
        .init(dayLabel: "화", percent: nil, isToday: false),
        .init(dayLabel: "수", percent: nil, isToday: false),
        .init(dayLabel: "목", percent: 18, isToday: true),
    ])
    .padding()
    .background(.white01)
}
