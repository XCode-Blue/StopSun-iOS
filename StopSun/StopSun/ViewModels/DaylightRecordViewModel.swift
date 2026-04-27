//
//  DaylightRecordViewModel.swift
//  StopSun
//
//  Created by taeni on 4/26/26.
//

import SwiftUI

/// 일광 시간 직접 기록 ViewModel
///
/// ## 상태 흐름
/// ```
/// 날짜 선택 → fetchDaylightRecords() → 기존 기록 표시
///     ↓
/// 시작/종료 시각 입력
///     ↓
/// trySave() → 중복 체크
///     ├─ 중복 있음 → showOverlapAlert = true
///     └─ 중복 없음 → performSave()
///                         ↓
///                    HealthKit 저장 + SED 재계산
///                    + fetchDaylightRecords() 갱신
/// ```
///
@MainActor
@Observable
final class DaylightRecordViewModel {
    
    // MARK: - Date Selection
    
    /// 선택한 날짜 (기본값: 오늘)
    var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    
    // MARK: - Existing Records
    
    /// 선택한 날짜의 기존 일광 기록
    private(set) var existingRecords: [TimeInDaylight] = []
    
    /// 기록 조회 중 여부
    private(set) var isLoadingRecords: Bool = false
    
    // MARK: - New Entry
    
    var startTime: Date
    var endTime: Date
    var appliedSunscreen: Bool = false
    var selectedSPF: SPFLevel
    
    // MARK: - UI State
    
    private(set) var isSaving: Bool = false
    var showOverlapAlert: Bool = false
    var showSuccessAlert: Bool = false
    var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let syncCoordinator: any SyncCoordinatorProtocol
    
    /// 프로필 기본 SPF (SPF Picker 초기값 및 Toggle OFF 시 초기화 기준)
    let defaultSPF: SPFLevel
    
    // MARK: - Initializer
    
    init(syncCoordinator: any SyncCoordinatorProtocol) {
        self.syncCoordinator = syncCoordinator
        
        let profileSPF = syncCoordinator.userProfile?.spfLevel ?? .spf30
        self.defaultSPF = profileSPF
        self.selectedSPF = profileSPF
        
        let now = Date()
        self.startTime = Calendar.current.date(byAdding: .minute, value: -30, to: now) ?? now
        self.endTime = now
        
        Log.debug("DaylightRecordViewModel initialized")
    }
    
    // MARK: - Computed: Date
    
    /// 선택 가능한 날짜 범위 (최대 30일 전 ~ 오늘)
    var selectableDateRange: ClosedRange<Date> {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let startOfRange = Calendar.current.startOfDay(for: thirtyDaysAgo)
        let today = Calendar.current.startOfDay(for: Date())
        return startOfRange...today
    }
    
    /// 시간 입력 가능 범위 (선택 날짜 기준)
    var timePickerRange: ClosedRange<Date> {
        let start = Calendar.current.startOfDay(for: selectedDate)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: start).map {
            $0.addingTimeInterval(-1)
        } ?? start
        // 오늘이면 현재 시각까지, 과거 날짜면 23:59:59까지
        let end = Calendar.current.isDateInToday(selectedDate) ? Date() : endOfDay
        return start...end
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    // MARK: - Computed: Validation
    
    var isValidTimeRange: Bool {
        endTime > startTime
    }
    
    /// 새 입력과 겹치는 기존 기록
    var overlappingRecords: [TimeInDaylight] {
        existingRecords.filter { record in
            startTime < record.endTime && endTime > record.startTime
        }
    }
    
    var hasOverlap: Bool {
        !overlappingRecords.isEmpty
    }
    
    /// 중복 기록의 시간대 텍스트 (Alert 메시지용)
    var overlapSummary: String {
        overlappingRecords.map { record in
            "\(record.startTime.formatted(date: .omitted, time: .shortened)) ~ \(record.endTime.formatted(date: .omitted, time: .shortened))"
        }.joined(separator: "\n")
    }
    
    // MARK: - Computed: Display
    
    var durationText: String {
        let minutes = Int(endTime.timeIntervalSince(startTime) / 60)
        guard minutes > 0 else { return "" }
        if minutes >= 60 {
            return "\(minutes / 60)\(L10n.DaylightRecord.unitHour) \(minutes % 60)\(L10n.DaylightRecord.unitMinute)"
        }
        return "\(minutes)\(L10n.DaylightRecord.unitMinute)"
    }
    
    var selectedDateTitle: String {
        if isToday { return L10n.DaylightRecord.today }
        return selectedDate.formatted(date: .abbreviated, time: .omitted)
    }
    
    // MARK: - Load Records
    
    /// 선택한 날짜의 기록 조회
    func loadRecordsForSelectedDate() async {
        isLoadingRecords = true
        errorMessage = nil
        defer { isLoadingRecords = false }
        
        do {
            existingRecords = try await syncCoordinator.fetchDaylightRecords(for: selectedDate)
            Log.debug("DaylightRecord: \(existingRecords.count)개 기록 로드 (\(selectedDate.formatted(date: .abbreviated, time: .omitted)))")
        } catch {
            errorMessage = L10n.DaylightRecord.loadFailed
            Log.error("DaylightRecord: 기록 로드 실패 — \(error.localizedDescription)")
        }
    }
    
    /// 날짜 변경 시 호출 — 시간 입력 초기화 + 기록 재조회
    func onDateChanged() async {
        resetTimeInputsToSelectedDate()
        await loadRecordsForSelectedDate()
    }
    
    private func resetTimeInputsToSelectedDate() {
        let calendar = Calendar.current
        if isToday {
            let now = Date()
            startTime = calendar.date(byAdding: .minute, value: -30, to: now) ?? now
            endTime = now
        } else {
            // 과거 날짜: 정오 기준 1시간
            startTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: selectedDate) ?? selectedDate
            endTime = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        }
    }
    
    // MARK: - Save
    
    /// 저장 시도 — 중복 있으면 Alert, 없으면 즉시 저장
    func trySave() {
        guard isValidTimeRange, !isSaving else { return }
        
        if hasOverlap {
            showOverlapAlert = true
        } else {
            Task { await performSave() }
        }
    }
    
    /// 실제 저장 실행
    func performSave() async {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        
        let spf: SPFLevel? = appliedSunscreen ? selectedSPF : nil
        
        do {
            try await syncCoordinator.recordDaylightExposure(
                start: startTime,
                end: endTime,
                sunscreenSPF: spf
            )
            // 저장 후 목록 갱신
            await loadRecordsForSelectedDate()
            showSuccessAlert = true
            Log.info("DaylightRecord: 저장 완료 (\(startTime.formatted(date: .omitted, time: .shortened)) ~ \(endTime.formatted(date: .omitted, time: .shortened)))")
        } catch {
            errorMessage = L10n.DaylightRecord.saveFailed
            Log.error("DaylightRecord: 저장 실패 — \(error.localizedDescription)")
        }
    }
    
    // MARK: - HealthKit Auth
    
    func requestWriteAuthorization() async {
        try? await syncCoordinator.requestHealthKitWriteAuthorization()
    }
}
