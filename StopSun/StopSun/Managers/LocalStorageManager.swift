//
//  LocalStorageManager.swift
//  StopSun
//
//  Created by J on 1/27/26.
//

import Foundation

/// 로컬 저장소 관리자
final class LocalStorageManager: LocalStorageManagerProtocol {

    // MARK: - Properties

    private let userDefaults: UserDefaults

    // UserProfile Keys
    private let profileKey = "userProfile"
    private let onboardingCompletedKey = "isOnboardingCompleted"
    private let firstLaunchKey = "isFirstLaunch"

    // Sunscreen Keys
    private let sunscreenHistoryKey = "sunscreenHistory"

    // Location Keys
    private let locationHistoryKey = "locationHistory"

    // MARK: - Initialization

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        Log.debug("LocalStorageManager initialized")
    }

    // MARK: - UserProfile

    func loadUserProfile() -> UserProfile? {
        guard let data = userDefaults.data(forKey: profileKey) else {
            Log.debug("No UserProfile found in UserDefaults")
            return nil
        }

        do {
            let profile = try JSONDecoder().decode(UserProfile.self, from: data)
            Log.debug("UserProfile loaded successfully")
            return profile
        } catch {
            Log.error("Failed to decode UserProfile: \(error.localizedDescription)")
            return nil
        }
    }

    func loadUserProfileOrDefault() -> UserProfile {
        guard let profile = loadUserProfile() else {
            Log.debug("Returning default UserProfile")
            return UserProfile.defaultUser
        }
        return profile
    }

    func saveUserProfile(_ profile: UserProfile) {
        do {
            let encoded = try JSONEncoder().encode(profile)
            userDefaults.set(encoded, forKey: profileKey)
            Log.info("UserProfile saved successfully: \(profile)")

            NotificationCenter.default.post(
                name: .userProfileDidChange,
                object: profile
            )
        } catch {
            Log.error("Failed to save UserProfile: \(error.localizedDescription)")
        }
    }

    func updateSkinType(_ skinType: SkinType) {
        var profile = loadUserProfileOrDefault()
        profile.skinType = skinType
        Log.info("Updating SkinType to: \(skinType.title)")
        saveUserProfile(profile)
    }

    func updateSunscreenSPF(_ spfLevel: SPFLevel) {
        var profile = loadUserProfileOrDefault()
        profile.spfLevel = spfLevel
        Log.info("Updating SPFLevel to: SPF \(spfLevel.rawValue)")
        saveUserProfile(profile)
    }

    func deleteUserProfile() {
        userDefaults.removeObject(forKey: profileKey)
        Log.info("UserProfile deleted")

        NotificationCenter.default.post(
            name: .userProfileDidChange,
            object: nil
        )
    }

    func saveOnboardingCompleted(_ isCompleted: Bool) {
        userDefaults.set(isCompleted, forKey: onboardingCompletedKey)
        Log.info("Onboarding completed status saved: \(isCompleted)")
    }

    func loadOnboardingCompleted() -> Bool {
        return userDefaults.bool(forKey: onboardingCompletedKey)
    }

    func checkIsFirstLaunch() -> Bool {
        let isFirst = !userDefaults.bool(forKey: firstLaunchKey)

        guard isFirst else {
            return false
        }

        userDefaults.set(true, forKey: firstLaunchKey)
        Log.info("First launch detected and recorded")

        return true
    }
    
    // MARK: - SunscreenApplication

    func loadSunscreenHistory() -> [SunscreenApplication] {
        guard let data = userDefaults.data(forKey: sunscreenHistoryKey) else {
            Log.debug("No Sunscreen history found in UserDefaults")
            return []
        }

        do {
            let history = try JSONDecoder().decode([SunscreenApplication].self, from: data)
            Log.debug("Sunscreen history loaded: \(history.count) items")
            return history
        } catch {
            Log.error("Failed to decode Sunscreen history: \(error.localizedDescription)")
            return []
        }
    }

    func loadCurrentSunscreen() -> SunscreenApplication? {
        let history = loadSunscreenHistory()
        return history.last
    }

    func saveSunscreenApplication(_ application: SunscreenApplication) {
        var history = loadSunscreenHistory()
        history.append(application)

        // 메모리 관리: 최근 1000개만 유지
        if history.count > 1000 {
            history.removeFirst(history.count - 1000)
        }

        do {
            let encoded = try JSONEncoder().encode(history)
            userDefaults.set(encoded, forKey: sunscreenHistoryKey)
            Log.info("Sunscreen application saved: SPF \(application.spfLevel.rawValue) at \(application.appliedAt.formatted())")
        } catch {
            Log.error("Failed to save Sunscreen application: \(error.localizedDescription)")
        }
    }

    func deleteSunscreen() {
        userDefaults.removeObject(forKey: sunscreenHistoryKey)
        Log.info("Sunscreen history deleted")
    }

    func isSunscreenActive() -> Bool {
        guard let current = loadCurrentSunscreen() else {
            return false
        }
        let isActive = current.isActive(at: Date())
        Log.debug("Sunscreen active status: \(isActive)")
        return isActive
    }

    func loadSunscreenRemainingMinutes() -> Int {
        guard let current = loadCurrentSunscreen() else {
            return 0
        }

        let currentTime = Date()
        let nextReapplyTime = current.nextReapplyTime
        let remainingTime = nextReapplyTime.timeIntervalSince(currentTime)

        return remainingTime > 0 ? Int(remainingTime / 60) : 0
    }

    func getActiveSPF(at date: Date) -> SPFLevel {
        let history = loadSunscreenHistory()
        let activeSunscreen = history.first { $0.isActive(at: date) }
        return activeSunscreen?.spfLevel ?? .none
    }
    
    // MARK: - LocationRecord

    func loadLocationHistory() -> [LocationRecord] {
        guard let data = userDefaults.data(forKey: locationHistoryKey) else {
            Log.debug("No Location history found in UserDefaults")
            return []
        }

        do {
            let history = try JSONDecoder().decode([LocationRecord].self, from: data)
            Log.debug("Location history loaded: \(history.count) items")
            return history
        } catch {
            Log.error("Failed to decode Location history: \(error.localizedDescription)")
            return []
        }
    }

    func saveLocationRecord(_ record: LocationRecord) {
        var history = loadLocationHistory()
        history.append(record)

        // 메모리 관리: 최근 1000개만 유지
        if history.count > 1000 {
            history.removeFirst(history.count - 1000)
        }

        do {
            let encoded = try JSONEncoder().encode(history)
            userDefaults.set(encoded, forKey: locationHistoryKey)
            Log.info("Location record saved: (\(record.latitude), \(record.longitude)) at \(record.timestamp.formatted())")
        } catch {
            Log.error("Failed to save Location record: \(error.localizedDescription)")
        }
    }

    func getLocation(at date: Date) -> LocationRecord? {
        let history = loadLocationHistory()

        // 10분 오차 범위 내 가장 가까운 기록 반환
        // HealthKit 데이터 지연을 고려한 여유값
        return history.last { record in
            abs(record.timestamp.timeIntervalSince(date)) < 600
        }
    }
    
    // MARK: - UVExposureRecord

    func loadExposureRecords(for date: Date) -> [UVExposureRecord] {
        let key = exposureKey(for: date)
        guard let data = userDefaults.data(forKey: key) else {
            Log.debug("No UV Exposure records found for \(date.formatted(date: .abbreviated, time: .omitted))")
            return []
        }

        do {
            let records = try JSONDecoder().decode([UVExposureRecord].self, from: data)
            Log.debug("UV Exposure records loaded: \(records.count) items for \(date.formatted(date: .abbreviated, time: .omitted))")
            return records
        } catch {
            Log.error("Failed to decode UV Exposure records: \(error.localizedDescription)")
            return []
        }
    }

    func saveExposureRecord(_ record: UVExposureRecord) {
        let key = exposureKey(for: record.startTime)
        var records = loadExposureRecords(for: record.startTime)

        // 중복 저장 방지: HealthKit ID가 이미 존재하는지 확인
        if let healthKitID = record.healthKitID,
           records.contains(where: { $0.healthKitID == healthKitID }) {
            Log.debug("UV Exposure record already exists: \(healthKitID)")
            return
        }

        records.append(record)

        do {
            let encoded = try JSONEncoder().encode(records)
            userDefaults.set(encoded, forKey: key)
            Log.info("UV Exposure record saved: \(record.receivedSED) SED at \(record.startTime.formatted())")
        } catch {
            Log.error("Failed to save UV Exposure record: \(error.localizedDescription)")
        }
    }

    func isProcessed(healthKitID: UUID) -> Bool {
        let calendar = Calendar.current
        let today = Date()

        // 1. 당일 데이터 먼저 확인 (대부분의 케이스)
        let todayRecords = loadExposureRecords(for: today)
        if todayRecords.contains(where: { $0.healthKitID == healthKitID }) {
            return true
        }

        // 2. 당일에 없으면 과거 검색 (지연 도착 케이스)
        for dayOffset in 1...30 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let records = loadExposureRecords(for: date)

            if records.contains(where: { $0.healthKitID == healthKitID }) {
                return true
            }
        }

        return false
    }
    
    // MARK: - DailyMEDRecord

    func loadDailyMEDRecord(for date: Date) -> DailyMEDRecord? {
        let key = dailyMEDKey(for: date)
        guard let data = userDefaults.data(forKey: key) else {
            Log.debug("No Daily MED record found for \(date.formatted(date: .abbreviated, time: .omitted))")
            return nil
        }

        do {
            let record = try JSONDecoder().decode(DailyMEDRecord.self, from: data)
            Log.debug("Daily MED record loaded: \(record.totalSED) SED for \(date.formatted(date: .abbreviated, time: .omitted))")
            return record
        } catch {
            Log.error("Failed to decode Daily MED record: \(error.localizedDescription)")
            return nil
        }
    }

    func saveDailyMEDRecord(_ record: DailyMEDRecord) {
        let key = dailyMEDKey(for: record.date)

        do {
            let encoded = try JSONEncoder().encode(record)
            userDefaults.set(encoded, forKey: key)
            Log.info("Daily MED record saved: \(record.totalSED) SED (\(record.recordCount) exposures) for \(record.date.formatted(date: .abbreviated, time: .omitted))")
        } catch {
            Log.error("Failed to save Daily MED record: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Cleanup

    func cleanupOldData() {
        let calendar = Calendar.current
        let today = Date()

        var removedCount = 0

        // 31일 이전 ~ 90일 이전 데이터 삭제 (30일 보관 정책)
        for dayOffset in 31...90 {
            guard let oldDate = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            // UVExposureRecord 삭제
            let exposureKey = exposureKey(for: oldDate)
            if userDefaults.object(forKey: exposureKey) != nil {
                userDefaults.removeObject(forKey: exposureKey)
                removedCount += 1
            }

            // DailyMEDRecord 삭제
            let medKey = dailyMEDKey(for: oldDate)
            if userDefaults.object(forKey: medKey) != nil {
                userDefaults.removeObject(forKey: medKey)
                removedCount += 1
            }
        }

        Log.info("Cleanup completed: \(removedCount) old records removed")
    }

    // MARK: - Private Methods

    /// 날짜 포맷터 (yyyyMMdd)
    private static let dateKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()

    /// 날짜별 UVExposure 키 생성
    private func exposureKey(for date: Date) -> String {
        return "exposures.\(Self.dateKeyFormatter.string(from: date))"
    }

    /// 날짜별 DailyMED 키 생성
    private func dailyMEDKey(for date: Date) -> String {
        return "dailyMED.\(Self.dateKeyFormatter.string(from: date))"
    }
}
