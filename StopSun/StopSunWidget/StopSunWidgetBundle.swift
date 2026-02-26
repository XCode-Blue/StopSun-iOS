//
//  StopSunWidgetBundle.swift
//  StopSunWidget
//
//  Created by taeni on 2/23/26.
//

import WidgetKit
import SwiftUI

@main
struct StopSunWidgetBundle: WidgetBundle {
    var body: some Widget {
        StopSunWidget()
        StopSunWidgetControl()
        StopSunWidgetLiveActivity()
    }
}
