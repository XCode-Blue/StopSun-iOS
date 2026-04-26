//
//  DaylightRecordView.swift
//  StopSun
//
//  Created by taeni on 4/26/26.
//


//
//  DaylightRecordView.swift
//  StopSun
//
//  Created by taein on 4/26/26.
//

import SwiftUI

/// 일광 노출 시간 수동 입력 화면
///
/// Watch 미보유 사용자가 야외 활동 시간을 직접 입력하면
/// HealthKit에 TimeInDaylight 샘플을 저장하고 SED를 즉시 재계산합니다.
///
/// ## 화면 구성
/// 1. 날짜 선택 (최대 30일 전 ~ 오늘)
/// 2. 해당 날짜의 기존 일광 기록 목록
/// 3. 새 기록 입력 (시작/종료 시각 + 선크림 여부)
/// 4. 저장 (중복 시 Alert)
///
struct DaylightRecordView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: DaylightRecordViewModel
    
    // MARK: - Initializer
    
    init(viewModel: DaylightRecordViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    
    var body: some View {
        @Bindable var vm = viewModel
        
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                
                heading
                    .padding(.bottom, 28)
                
                // 날짜 선택
                datePicker(vm: $vm)
                    .padding(.bottom, 24)
                
                // 기존 기록 목록
                sectionLabel(L10n.DaylightRecord.sectionExisting(viewModel.selectedDateTitle))
                    .padding(.bottom, 12)
                
                existingRecordsList
                    .padding(.bottom, 32)
                
                // 새 기록 입력
                sectionLabel(L10n.DaylightRecord.sectionNewEntry)
                    .padding(.bottom, 12)
                
                timePickerCard(vm: $vm)
                    .padding(.bottom, 8)
                
                if viewModel.isValidTimeRange && !viewModel.durationText.isEmpty {
                    durationLabel
                        .padding(.bottom, 24)
                } else {
                    Spacer().frame(height: 32)
                }
                
                sectionLabel(L10n.DaylightRecord.sectionSunscreen)
                    .padding(.bottom, 12)
                
                sunscreenCard(vm: $vm)
                    .padding(.bottom, 32)
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.ssFont(.R1))
                        .foregroundStyle(.red)
                        .padding(.bottom, 12)
                }
                
                SSButton(
                    L10n.DaylightRecord.save,
                    style: (viewModel.isSaving || !viewModel.isValidTimeRange) ? .notAllowed : .primary
                ) {
                    viewModel.trySave()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .background(Color.white00)
        .navigationTitle(L10n.DaylightRecord.navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.requestWriteAuthorization()
            await viewModel.loadRecordsForSelectedDate()
        }
        // 중복 Alert
        .alert(L10n.DaylightRecord.overlapAlertTitle, isPresented: $vm.showOverlapAlert) {
            Button(L10n.Button.cancel, role: .cancel) {}
        } message: {
            Text(L10n.DaylightRecord.overlapAlertMessage(viewModel.overlapSummary))
        }
        // 저장 성공 Alert
        .alert(L10n.DaylightRecord.successTitle, isPresented: $vm.showSuccessAlert) {
            Button(L10n.Button.confirm) {}
        } message: {
            Text(L10n.DaylightRecord.successMessage)
        }
    }
    
    // MARK: - Heading
    
    private var heading: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.DaylightRecord.heading)
                .font(.ssFont(.B2))
                .foregroundStyle(Color.text00)
            
            Text(L10n.DaylightRecord.subtitle)
                .font(.ssFont(.R1))
                .foregroundStyle(Color.text03)
        }
    }
    
    // MARK: - Date Picker
    
    private func datePicker(vm: Bindable<DaylightRecordViewModel>) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(L10n.DaylightRecord.selectDate)
                    .font(.ssFont(.SB2))
                    .foregroundStyle(Color.text00)
                
                Spacer()
                
                DatePicker(
                    "",
                    selection: vm.selectedDate,
                    in: viewModel.selectableDateRange,
                    displayedComponents: .date
                )
                .labelsHidden()
                .tint(Color.key00)
                .onChange(of: viewModel.selectedDate) { _, _ in
                    Task { await viewModel.onDateChanged() }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white00))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.gray00, lineWidth: 1))
    }
    
    // MARK: - Existing Records List
    
    @ViewBuilder
    private var existingRecordsList: some View {
        if viewModel.isLoadingRecords {
            HStack {
                Spacer()
                ProgressView()
                    .tint(Color.key00)
                Spacer()
            }
            .padding(.vertical, 20)
        } else if viewModel.existingRecords.isEmpty {
            emptyRecordsPlaceholder
        } else {
            VStack(spacing: 8) {
                ForEach(viewModel.existingRecords) { record in
                    existingRecordRow(record)
                }
            }
        }
    }
    
    private var emptyRecordsPlaceholder: some View {
        HStack {
            Spacer()
            VStack(spacing: 6) {
                Image(systemName: "sun.slash")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.text03)
                Text(L10n.DaylightRecord.emptyRecords)
                    .font(.ssFont(.R1))
                    .foregroundStyle(Color.text03)
            }
            .padding(.vertical, 20)
            Spacer()
        }
    }
    
    private func existingRecordRow(_ record: TimeInDaylight) -> some View {
        HStack(spacing: 12) {
            // 시간 아이콘
            Image(systemName: "clock")
                .font(.system(size: 14))
                .foregroundStyle(Color.key00)
                .frame(width: 20)
            
            // 시작 ~ 종료
            Text("\(record.startTime.formatted(date: .omitted, time: .shortened)) ~ \(record.endTime.formatted(date: .omitted, time: .shortened))")
                .font(.ssFont(.SB2))
                .foregroundStyle(Color.text00)
            
            Spacer()
            
            // 총 시간
            let minutes = Int(record.durationMinutes)
            Text(minutes >= 60
                 ? "\(minutes / 60)\(L10n.DaylightRecord.unitHour) \(minutes % 60)\(L10n.DaylightRecord.unitMinute)"
                 : "\(minutes)\(L10n.DaylightRecord.unitMinute)")
                .font(.ssFont(.R1))
                .foregroundStyle(Color.text03)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white00))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.gray00, lineWidth: 1))
    }
    
    // MARK: - Time Picker Card
    
    private func timePickerCard(vm: Bindable<DaylightRecordViewModel>) -> some View {
        VStack(spacing: 0) {
            timePickerRow(
                label: L10n.DaylightRecord.startTime,
                selection: vm.startTime,
                range: viewModel.timePickerRange,
                onChange: { newStart in
                    // 시작 시각이 종료 이후로 이동하면 종료 자동 보정
                    if viewModel.endTime <= newStart {
                        viewModel.endTime = min(
                            newStart.addingTimeInterval(60 * 30),
                            viewModel.timePickerRange.upperBound
                        )
                    }
                }
            )
            
            Divider().padding(.horizontal, 16)
            
            timePickerRow(
                label: L10n.DaylightRecord.endTime,
                selection: vm.endTime,
                range: viewModel.timePickerRange,
                onChange: { _ in }
            )
        }
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white00))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.gray00, lineWidth: 1))
    }
    
    private func timePickerRow(
        label: String,
        selection: Binding<Date>,
        range: ClosedRange<Date>,
        onChange: @escaping (Date) -> Void
    ) -> some View {
        HStack {
            Text(label)
                .font(.ssFont(.SB2))
                .foregroundStyle(Color.text00)
            
            Spacer()
            
            DatePicker("", selection: selection, in: range, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(Color.key00)
                .onChange(of: selection.wrappedValue) { _, new in
                    onChange(new)
                }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Duration Label
    
    private var durationLabel: some View {
        HStack {
            Spacer()
            Text(viewModel.durationText)
                .font(.ssFont(.R1))
                .foregroundStyle(Color.text03)
        }
        .padding(.top, 6)
    }
    
    // MARK: - Sunscreen Card
    
    private func sunscreenCard(vm: Bindable<DaylightRecordViewModel>) -> some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.DaylightRecord.sunscreenToggleTitle)
                        .font(.ssFont(.SB2))
                        .foregroundStyle(Color.text00)
                    
                    Text(L10n.DaylightRecord.sunscreenToggleDesc)
                        .font(.ssFont(.R1))
                        .foregroundStyle(Color.text03)
                }
                
                Spacer()
                
                Toggle("", isOn: vm.appliedSunscreen)
                    .tint(Color.key00)
                    .labelsHidden()
                    .onChange(of: viewModel.appliedSunscreen) { _, applied in
                        if !applied { viewModel.selectedSPF = viewModel.defaultSPF }
                    }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            if viewModel.appliedSunscreen {
                Divider().padding(.horizontal, 16)
                
                HStack {
                    Text(L10n.DaylightRecord.sunscreenSPFTitle)
                        .font(.ssFont(.SB2))
                        .foregroundStyle(Color.text00)
                    
                    Spacer()
                    
                    Picker("SPF", selection: vm.selectedSPF) {
                        ForEach(SPFLevel.pickerCases) { level in
                            Text(level.displayTitle).tag(level)
                        }
                    }
                    .tint(Color.key00)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white00))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.gray00, lineWidth: 1))
        .animation(.easeInOut(duration: 0.2), value: viewModel.appliedSunscreen)
    }
    
    // MARK: - Section Label
    
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.ssFont(.R5))
            .foregroundStyle(Color.text03)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("DaylightRecord") {
    let vm = DIContainer.preview.makeDaylightRecordViewModel()
    NavigationStack {
        DaylightRecordView(viewModel: vm)
    }
}
#endif