//
//  MEDGaugeCardView.swift
//  StopSun
//
//  Created by taeni on 2/11/26.
//

import SwiftUI

struct MEDGaugeCardView: View {
    
    let percentage: Double
    let currentValue: Double
    let maxValue: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 24) {
            
            MEDGaugeView(
                percentage: percentage,
                color: color
            )
            .padding(.top, 16)
            .frame(width: 220)
            
            // 수치
            HStack {
                VStack(spacing: 4) {
                    Text(L10n.MED.Gauge.todayUV)
                        .font(.ssFont(.R4))
                        .foregroundStyle(.text03)
                    
                    HStack {
                        Text("\(currentValue, specifier: "%.1f")")
                            .font(.ssFont(.SB3))
                            .foregroundStyle(color)
                        
                        Text(L10n.MED.Gauge.unitJoule)
                            .font(.ssFont(.R4))
                            .foregroundStyle(.text03)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(L10n.MED.Gauge.maxUV)
                        .font(.ssFont(.R4))
                        .foregroundStyle(.text03)
                    
                    HStack {
                        Text("\(maxValue, specifier: "%.1f")")
                            .font(.ssFont(.SB3))
                            .foregroundStyle(color)
                        
                        Text(L10n.MED.Gauge.unitJoule)
                            .font(.ssFont(.R4))
                            .foregroundStyle(.text03)
                    }
                }
            }
            .padding(.horizontal, 24)
            
            VStack(spacing: 6) {
                Text(level.statusTitle)
                    .font(.ssFont(.R3))
                
                Text(level.statusDescription)
                    .font(.ssFont(.R3))
                    .foregroundStyle(.text03)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
        )
    }
    
    private var level: MEDLevel {
        MEDLevel.fromPercentage(percentage)
    }
}


#Preview("MED Gauge - Danger") {
    MEDGaugeCardView(
        percentage: 73,
        currentValue: 364.2,
        maxValue: 500,
        color: .gage01
    )
    .padding()
}
