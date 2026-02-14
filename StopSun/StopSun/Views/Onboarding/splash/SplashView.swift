//
//  SplashView.swift
//  StopSun
//
//  Created by taeni on 2/11/26.
//

import SwiftUI

struct SplashView: View {
    
    var body: some View {
        ZStack {
            Image(.imgBackground)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }
}
