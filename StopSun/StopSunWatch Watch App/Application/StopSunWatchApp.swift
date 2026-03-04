//
//  StopSunWatchApp.swift
//  StopSunWatch Watch App
//
//  Created by taeni on 9/16/25.
//

import SwiftUI
import WatchKit

@main
struct StopSunWatch_Watch_AppApp: App {
    @WKExtensionDelegateAdaptor(WatchAppDelegate.self) var delegate
    
    @StateObject private var viewModel = WatchMainViewModel()

    var body: some Scene {
        WindowGroup {
            WatchMainView(viewModel: viewModel)
        }
    }
}
