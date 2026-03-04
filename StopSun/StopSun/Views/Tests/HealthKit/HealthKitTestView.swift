//
//  HealthKitTestView.swift
//  StopSun
//
//  Created by J on 1/29/26.
//

import SwiftUI

///  테스트용 - 나중에 삭제
import SwiftUI

#if DEBUG
struct HealthKitTestView: View {
    @StateObject private var viewModel = HealthKitTestViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - 상태
                Section("상태") {
                    HStack {
                        Text("HealthKit 사용 가능")
                        Spacer()
                        Text(viewModel.isAvailable ? "✅" : "❌")
                    }
                    
                    HStack {
                        Text("권한 요청됨")
                        Spacer()
                        Text(viewModel.isAuthorized ? "✅" : "❌")
                    }
                    
                    HStack {
                        Text("Background Delivery")
                        Spacer()
                        Text(viewModel.isBackgroundDeliveryEnabled ? "✅" : "❌")
                    }
                }
                
                // MARK: - Background Delivery 모니터링
                Section("Background Delivery 모니터링") {
                    HStack {
                        Text("수신 횟수")
                        Spacer()
                        Text("\(viewModel.backgroundDeliveryCount)회")
                            .foregroundStyle(.blue)
                    }
                    
                    HStack {
                        Text("마지막 수신")
                        Spacer()
                        if let time = viewModel.lastBackgroundDeliveryTime {
                            Text(formatDateTime(time))
                                .foregroundStyle(.green)
                        } else {
                            Text("없음")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // MARK: - 액션
                Section("액션") {
                    Button("권한 요청") {
                        Task {
                            await viewModel.requestAuthorization()
                        }
                    }
                    .disabled(viewModel.isAuthorized)
                    
                    Button("오늘 데이터 조회") {
                        Task {
                            await viewModel.fetchTodayData()
                        }
                    }
                    .disabled(!viewModel.isAuthorized)
                }
                
                // MARK: - 기간별 조회
                Section("기간별 조회") {
                    DatePicker("시작일", selection: $viewModel.startDate, displayedComponents: .date)
                    DatePicker("종료일", selection: $viewModel.endDate, displayedComponents: .date)
                    
                    Button("기간 데이터 조회") {
                        Task {
                            await viewModel.fetchPeriodData()
                        }
                    }
                    .disabled(!viewModel.isAuthorized)
                }
                
                // MARK: - 에러
                if let errorMessage = viewModel.errorMessage {
                    Section("에러") {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
                
                // MARK: - 오늘 데이터
                Section("오늘 TimeInDaylight (\(viewModel.todayData.count)건)") {
                    if viewModel.isLoading {
                        ProgressView()
                    } else if viewModel.todayData.isEmpty {
                        Text("데이터 없음")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.todayData) { item in
                            timeInDaylightRow(item)
                        }
                    }
                }
                
                // MARK: - 기간 데이터
                Section("기간별 TimeInDaylight (\(viewModel.periodData.count)건)") {
                    if viewModel.isLoading {
                        ProgressView()
                    } else if viewModel.periodData.isEmpty {
                        Text("데이터 없음")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.periodData) { item in
                            timeInDaylightRow(item)
                        }
                    }
                }
            }
            .navigationTitle("HealthKit 테스트")
        }
    }
    
    // MARK: - Helper
    
    @ViewBuilder
    private func timeInDaylightRow(_ item: TimeInDaylight) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(formatDate(item.startTime)) ~ \(formatTime(item.endTime))")
                .font(.subheadline)
            Text("노출 시간: \(String(format: "%.1f", item.durationMinutes))분")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

#Preview {
    HealthKitTestView()
}
#endif
