//
//  UserProfileExampleView.swift
//  StopSun
//
//  Created by donghee on 1/22/26.
//

import SwiftUI

/// 사용자 프로필 기능 사용 예제 View
/// - View는 ViewModel을 통해서만 데이터에 접근
/// - Manager/Service에 직접 접근하지 않음
#if DEBUG
struct UserProfileExampleView: View {

    // MARK: - ViewModel
    @StateObject private var viewModel = UserProfileViewModel(localStorage: DIContainer.shared.localStorage)

    var body: some View {
        NavigationView {
            Form {
                // 피부 타입 섹션
                skinTypeSection

                // SPF 레벨 섹션
                spfLevelSection

                // 프로필 정보 섹션
                profileInfoSection

                // 액션 섹션
                actionSection
            }
            .navigationTitle("프로필 설정")
            .onAppear {
                viewModel.refresh()
            }
        }
    }

    // MARK: - Sections

    private var skinTypeSection: some View {
        Section {
            Picker("피부 타입", selection: $viewModel.skinType) {
                ForEach(viewModel.allSkinTypes) { skinType in
                    VStack(alignment: .leading) {
                        Text(skinType.title)
                        Text(skinType.summary)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .tag(skinType)
                }
            }
            .onChange(of: viewModel.skinType) { _, newValue in
                viewModel.updateSkinType(newValue)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("피부 타입 설명")
                    .font(.caption)
                    .foregroundColor(.gray)

                Text(viewModel.skinTypeDescription)
                    .font(.subheadline)

                HStack {
                    Text("최대 MED:")
                        .font(.caption)
                    Text("\(String(format: "%.0f", viewModel.maxMED))")
                        .font(.caption)
                        .fontWeight(.bold)
                }
            }
            .padding(.vertical, 4)

        } header: {
            Text("피부 타입")
        } footer: {
            Text(viewModel.skinCareAdvice)
        }
    }

    private var spfLevelSection: some View {
        Section {
            Picker("SPF 레벨", selection: $viewModel.spfLevel) {
                ForEach(viewModel.allSPFLevels) { spfLevel in
                    Text(spfLevel.displayTitle)
                        .tag(spfLevel)
                }
            }
            .onChange(of: viewModel.spfLevel) { _, newValue in
                viewModel.updateSPFLevel(newValue)
            }

            HStack {
                Text("권장 SPF")
                    .foregroundColor(.gray)
                Spacer()
                Text(viewModel.recommendedSPFLevel.displayTitle)
                    .fontWeight(.medium)
            }

            if !viewModel.isUsingSufficientSPF {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("권장 SPF보다 낮습니다")
                        .font(.caption)
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("적절한 SPF를 사용 중입니다")
                        .font(.caption)
                }
            }

        } header: {
            Text("SPF 레벨")
        }
    }

    private var profileInfoSection: some View {
        Section {
            HStack {
                Text("온보딩 완료")
                Spacer()
                Image(systemName: viewModel.isOnboardingCompleted ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundColor(viewModel.isOnboardingCompleted ? .green : .gray)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("안전 노출 시간 예시")
                    .font(.caption)
                    .foregroundColor(.gray)

                ForEach([3.0, 7.0, 11.0], id: \.self) { uvIndex in
                    HStack {
                        Text("UV \(Int(uvIndex)):")
                            .font(.caption)

                        Spacer()

                        let safeTime = viewModel.calculateSafeExposureTime(uvIndex: uvIndex, usingSunscreen: false)
                        Text("\(safeTime)분")
                            .font(.caption)
                            .fontWeight(.medium)

                        Text("(선크림 미사용)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }

        } header: {
            Text("프로필 정보")
        }
    }

    private var actionSection: some View {
        Section {
            Button(action: {
                viewModel.refresh()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("프로필 새로고침")
                }
            }

            Button(role: .destructive, action: {
                viewModel.resetProfile()
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("프로필 초기화")
                }
            }
        } header: {
            Text("관리")
        }
    }
}

#Preview {
    UserProfileExampleView()
}
#endif
