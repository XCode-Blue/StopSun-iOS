//
//  HalfArcShape.swift
//  StopSun
//
//  Created by taeni on 2/11/26.
//

import SwiftUI

// 반원 Shape
struct HalfArcShape: InsettableShape {
    
    var progress: Double        // 0.0 ~ 1.0
    var insetAmount: CGFloat = 0
    
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let rect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let radius = rect.width / 2
        
        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(180 + 180 * progress),
            clockwise: false
        )
        
        return path
    }
    
    func inset(by amount: CGFloat) -> some InsettableShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}
