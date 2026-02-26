//
//  SunScreenExampleView.swift
//  StopSun
//
//  Created by donghee on 1/22/26.
//

import SwiftUI

/// 선크림 기능 사용 예제 View
/// - View는 ViewModel을 통해서만 데이터에 접근
/// - Manager/Service에 직접 접근하지 않음
struct SunScreenExampleView: View {

    // MARK: - ViewModel
    @StateObject private var viewModel = SunScreenViewModel(localStorage: DIContainer.shared.localStorage)

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    sunScreenStatusCard
                    sunScreenActionButtons
                    sunScreenDetails
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("선크림 관리")
            .onAppear { viewModel.refresh() }
        }
    }

    private var sunScreenStatusCard: some View {
        VStack(spacing: 12) {
            if viewModel.isActive {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title).foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text("선크림 효과 활성").font(.headline)
                        Text(viewModel.fetchFormattedRemainingTime() + " 남음")
                            .font(.caption).foregroundColor(.gray)
                    }
                    Spacer()
                    Text("\(viewModel.effectiveness)%")
                        .font(.title2).fontWeight(.bold)
                }
                ProgressView(value: 1.0 - viewModel.progressRate).tint(.green)
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title).foregroundColor(.orange)
                    Text("선크림을 발라주세요").font(.headline)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private var sunScreenActionButtons: some View {
        VStack(spacing: 12) {
            Button { viewModel.applySunScreen() } label: {
                Label("선크림 바르기", systemImage: "hand.raised.fill")
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.blue).foregroundColor(.white)
                    .cornerRadius(10)
            }
            if viewModel.isActive {
                Button { viewModel.removeSunScreen() } label: {
                    Label("기록 삭제", systemImage: "trash")
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.red.opacity(0.2)).foregroundColor(.red)
                        .cornerRadius(10)
                }
            }
        }
    }

    private var sunScreenDetails: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("상세 정보").font(.headline)
            DetailRow(title: "발림 시각",
                      value: viewModel.applicationTime.isEmpty ? "-" : viewModel.applicationTime)
            DetailRow(title: "효과 상태", value: viewModel.fetchEffectivenessStatus())
            DetailRow(title: "남은 시간", value: viewModel.fetchFormattedRemainingTime())
            DetailRow(title: "재발림 필요",
                      value: viewModel.needsReapplication ? "예" : "아니오")
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    var body: some View {
        HStack {
            Text(title).foregroundColor(.gray)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

#Preview { SunScreenExampleView() }
