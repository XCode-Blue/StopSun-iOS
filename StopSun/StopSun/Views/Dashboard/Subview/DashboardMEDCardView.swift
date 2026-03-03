//
//  DashboardMEDCardView.swift
//  StopSun
//
//  Created by J on 2/21/26.
//

import SwiftUI

struct DashboardMEDCardView: View {
    
    let percentage: Double
    let currentValue: Double
    let maxValue: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            
            MEDGaugeView(
                percentage: percentage,
                color: color
            )
            .frame(maxWidth: 208)
            
            HStack(alignment: .top, spacing: 24) {
                VStack(spacing: 4) {
                    Text(L10n.MED.Gauge.todayUV)
                        .font(.ssFont(.R1))
                        .foregroundStyle(.text01)
                    
                    HStack(alignment: .bottom) {
                        Text("\(currentValue, specifier: "%.1f")")
                            .font(.ssFont(.SB3))
                            .foregroundStyle(color)
                        
                        Text(L10n.MED.Gauge.unitJoule)
                            .font(.ssFont(.R5))
                            .foregroundStyle(.text01)
                    }
                }
                
                VStack(spacing: 4){
                    Text(L10n.MED.Gauge.maxUV)
                        .font(.ssFont(.R1))
                        .foregroundStyle(.text01)
                    
                    HStack(alignment: .bottom) {
                        Text("\(maxValue, specifier: "%.0f")")
                            .font(.ssFont(.SB3))
                            .foregroundStyle(color)
                        
                        Text(L10n.MED.Gauge.unitJoule)
                            .font(.ssFont(.R5))
                            .foregroundStyle(.text01)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

#Preview("Dashboard MED Card") {
    DashboardMEDCardView(
        percentage: 73,
        currentValue: 364.2,
        maxValue: 500,
        color: .gage01
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}
