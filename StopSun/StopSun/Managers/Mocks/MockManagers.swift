//
//  MockManagers.swift
//  StopSun
//
//  Created by J on 1/27/26.
//

import Foundation
import UserNotifications

// MARK: - MockHealthKitManager

final class MockHealthKitManager: HealthKitManagerProtocol {
    var isAvailable: Bool { true }
    var isAuthorized: Bool { true }
    
    func requestAuthorization() async throws {}
    
    func fetchTodayTimeInDaylight() async throws -> [TimeInDaylight] {
        return []
    }
    
    func fetchTimeInDaylight(from start: Date, to end: Date) async throws -> [TimeInDaylight] {
        return []
    }
    
    func enableBackgroundDelivery() async throws {}
}

// MARK: - MockWeatherManager

final class MockWeatherManager: WeatherManagerProtocol {
    func fetchCurrentUVIndex(for location: LocationInfo) async throws -> Double {
        return 2.0
    }
    
    func fetchCurrentWeather(for location: LocationInfo) async throws -> LocationWeather {
        return LocationWeather(
            location: location,
            currentUVIndex: 5.0,
            currentTemperature: 25.0
        )
    }
    
    func fetchUVIndex(for location: LocationInfo, at date: Date) async throws -> Double {
        return 5.0
    }
}

// MARK: - MockLocationManager

final class MockLocationManager: LocationManagerProtocol {
    
    var isAuthorized: Bool { true }
    var isDenied: Bool { false }

    func requestAuthorization() async {}
    
    func getCurrentLocation() async throws -> LocationInfo {
        return .mockPohang
    }
    
    func startMonitoringSignificantLocationChanges() {}
    func stopMonitoringSignificantLocationChanges() {}
}

// MARK: - MockLocalStorageManager

final class MockLocalStorageManager: LocalStorageManagerProtocol {
    
    private var userProfile: UserProfile? = .mockUser
    private var activeSunscreen: SunscreenApplication?
    private var sunscreenHistory: [SunscreenApplication] = []
    private var locationHistory: [LocationRecord] = []
    private var onboardingCompleted: Bool = false
    private var firstLaunchChecked: Bool = false
    
    // MARK: - UserProfile

    func loadUserProfile() -> UserProfile? { userProfile }
    func loadUserProfileOrDefault() -> UserProfile { userProfile ?? .defaultUser }
    func saveUserProfile(_ profile: UserProfile) { userProfile = profile }
    func updateSkinType(_ skinType: SkinType) {
        userProfile?.skinType = skinType
    }
    func updateSunscreenSPF(_ spfLevel: SPFLevel) {
        userProfile?.spfLevel = spfLevel
    }
    func deleteUserProfile() { userProfile = nil }
    func hasUserProfile() -> Bool { userProfile != nil }
    
    // MARK: - Onboarding
    
    func saveOnboardingCompleted(_ isCompleted: Bool) {
        onboardingCompleted = isCompleted
    }
    func loadOnboardingCompleted() -> Bool { onboardingCompleted }
    func checkIsFirstLaunch() -> Bool {
        guard !firstLaunchChecked else { return false }
        firstLaunchChecked = true
        return true
    }
    
    // MARK: - Active Sunscreen
    
    func saveActiveSunscreen(_ sunscreen: SunscreenApplication) {
        activeSunscreen = sunscreen
    }
    func loadActiveSunscreen() -> SunscreenApplication? { activeSunscreen }
    func loadActiveValidSunscreen() -> SunscreenApplication? {
        guard let s = activeSunscreen, s.isActive(at: Date()) else { return nil }
        return s
    }
    func deleteActiveSunscreen() { activeSunscreen = nil }
    func hasActiveSunscreen() -> Bool { activeSunscreen != nil }
    func fetchRemainingMinutes() -> Int {
        guard let s = activeSunscreen else { return 0 }
        let remaining = s.nextReapplyTime.timeIntervalSince(Date())
        return remaining > 0 ? Int(remaining / 60) : 0
    }
    
    // MARK: - Sunscreen History
    
    func loadSunscreenHistory() -> [SunscreenApplication] { sunscreenHistory }
    func loadCurrentSunscreen() -> SunscreenApplication? { sunscreenHistory.last }
    func saveSunscreenApplication(_ application: SunscreenApplication) {
        sunscreenHistory.append(application)
    }
    func deleteSunscreen() { sunscreenHistory.removeAll() }
    func isSunscreenActive() -> Bool {
        guard let current = sunscreenHistory.last else { return false }
        return current.isActive(at: Date())
    }
    func loadSunscreenRemainingMinutes() -> Int {
        guard let current = sunscreenHistory.last else { return 0 }
        let nextReapply = current.nextReapplyTime
        let remaining = nextReapply.timeIntervalSince(Date())
        return remaining > 0 ? Int(remaining / 60) : 0
    }
    func getActiveSPF(at date: Date) -> SPFLevel {
        sunscreenHistory.first { $0.isActive(at: date) }?.spfLevel ?? .none
    }
    
    // MARK: - LocationRecord
    
    func loadLocationHistory() -> [LocationRecord] { locationHistory }
    func saveLocationRecord(_ record: LocationRecord) {
        locationHistory.append(record)
    }
    func getLocation(at date: Date) -> LocationRecord? { nil }
    
    // MARK: - UVExposureRecord
    
    func loadExposureRecords(for date: Date) -> [UVExposureRecord] { [] }
    func saveExposureRecord(_ record: UVExposureRecord) {}
    func isProcessed(healthKitID: UUID) -> Bool { false }
    
    // MARK: - DailyMEDRecord
    
    func loadDailyMEDRecord(for date: Date) -> DailyMEDRecord? { nil }
    func saveDailyMEDRecord(_ record: DailyMEDRecord) {}
    
    // MARK: - Cleanup
    
    func cleanupOldData() {}
}

// MARK: - MockNotificationManager

final class MockNotificationManager: NotificationManagerProtocol {
    
    var _isAuthorized: Bool = true
    var _authorizationStatus: UNAuthorizationStatus = .authorized
    var scheduledReminders: [Date] = []
    var sentMEDWarnings: [Double] = []
    var shouldFailAuthorization: Bool = false
    var shouldFailSchedule: Bool = false
    
    var isAuthorized: Bool { _isAuthorized }
    
    var authorizationStatus: UNAuthorizationStatus {
        get async { _authorizationStatus }
    }
    
    func requestAuthorization() async throws {
        if shouldFailAuthorization {
            throw AppError.notification(.authorizationDenied)
        }
        _isAuthorized = true
    }
    
    func scheduleReapplyReminder(at date: Date) async throws {
        if shouldFailSchedule {
            throw AppError.notification(.scheduleFailed)
        }
        guard date > Date() else {
            throw AppError.notification(.invalidDate)
        }
        scheduledReminders.append(date)
    }
    
    func cancelReapplyReminder() {
        scheduledReminders.removeAll()
    }
    
    func snoozeReapplyReminder() async throws {
        let snoozeDate = Date().addingTimeInterval(15 * 60)
        try await scheduleReapplyReminder(at: snoozeDate)
    }
    
    func sendMEDWarning(percentage: Double) {
        sentMEDWarnings.append(percentage)
    }
    
    func resetMEDWarningHistory() {
        sentMEDWarnings.removeAll()
    }
    
    func cancelAllNotifications() {
        scheduledReminders.removeAll()
        sentMEDWarnings.removeAll()
    }
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return []
    }
    
    func refreshAuthorizationStatus() async {}
}

// MARK: - MockWatchConnectivityManager

final class MockWatchConnectivityManager: WatchConnectivityManagerProtocol {
    
    var _isPaired: Bool = true
    
    var isPaired: Bool { _isPaired }
    var isReachable: Bool { false }

    var onMessageReceived: (([String: Any]) -> Void)?
    var onUserInfoReceived: (([String: Any]) -> Void)?

    func activate() {}
    func sendUserProfile(_ profile: UserProfile) {}
    func sendSunscreenApplication(_ application: SunscreenApplication) {}
    func sendMEDStatus(totalSED: Double, maxMED: Double) {}

    func sendMessage(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)?,
        errorHandler: ((Error) -> Void)?
    ) {}

    func transferUserInfo(_ userInfo: [String: Any]) {}
    func updateApplicationContext(_ context: [String: Any]) throws {}
}
