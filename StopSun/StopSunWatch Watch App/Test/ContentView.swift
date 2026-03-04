//
//  ContentView.swift
//  StopSunWatch Watch App
//
//  Created by taeni on 9/16/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: WatchViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {

                // MARK: - 연결 상태
                HStack {
                    Circle()
                        .fill(viewModel.isPhoneConnected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(viewModel.isPhoneConnected ? "연결됨" : "연결 끊김")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // MARK: - 위치 & 날씨
                VStack(spacing: 4) {
                    Text(viewModel.cityName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.temperatureText)
                        .font(.title3)
                }

                // MARK: - UV Index
                VStack(spacing: 4) {
                    Text("UV Index")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(viewModel.uvIndexText)
                        .font(.title2)
                        .fontWeight(.bold)
                }

                // MARK: - SED 진행률
                VStack(spacing: 4) {
                    Text("오늘 자외선 노출")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.totalSEDText) / \(viewModel.maxSEDText) SED")
                        .font(.caption)

                    ProgressView(value: min(viewModel.sedProgress, 1.0))
                        .tint(viewModel.warningLevelColor)

                    Text(viewModel.warningLevelTitle)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(viewModel.warningLevelColor)
                }
                .padding(.horizontal, 4)

                // MARK: - 선크림 상태
                HStack {
                    Image(systemName: "sun.max.trianglebadge.exclamationmark")
                        .font(.caption)
                    Text(viewModel.sunscreenStatusText)
                        .font(.caption)
                }
                .foregroundColor(.secondary)

                // MARK: - 동기화 버튼
                Button {
                    viewModel.requestDashboardSync()
                } label: {
                    Label("동기화", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)

                // MARK: - 동기화 상태
                if viewModel.syncFailed {
                    Text("동기화 실패 - iPhone 앱을 확인해주세요")
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                } else {
                    Text(viewModel.lastSyncText)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
}

#if DEBUG
#Preview {
    ContentView(viewModel: .preview)
}
#endif
