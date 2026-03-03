//
//  LocationTestViewModel.swift
//  StopSun
//
//  Created by J on 2/24/26.
//

import Foundation
import UIKit

@MainActor
final class LocationTestViewModel: ObservableObject {
    
    // MARK: - Published
    
    @Published private(set) var authorizationStatus: String = "확인 전"
    @Published private(set) var isAuthorized: Bool = false
    @Published private(set) var isDenied: Bool = false
    @Published private(set) var currentLocation: LocationInfo?
    @Published private(set) var locationHistory: [LocationRecord] = []
    @Published private(set) var isMonitoring: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading: Bool = false
    
    // MARK: - Dependencies
    
    private let locationManager: any LocationManagerProtocol
    private let localStorage: any LocalStorageManagerProtocol
    
    // MARK: - Init
    
    init(
        locationManager: (any LocationManagerProtocol)? = nil,
        localStorage: (any LocalStorageManagerProtocol)? = nil
    ) {
        self.locationManager = locationManager ?? DIContainer.shared.location
        self.localStorage = localStorage ?? DIContainer.shared.localStorage
        
        refreshStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async {
        await locationManager.requestAuthorization()
        refreshStatus()
    }
    
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    
    // MARK: - Location
    
    func fetchCurrentLocation() async {
        await performTask {
            self.currentLocation = try await self.locationManager.getCurrentLocation()
        }
    }
    
    // MARK: - Significant Location Changes
    
    func toggleMonitoring() {
        if isMonitoring {
            locationManager.stopMonitoringSignificantLocationChanges()
        } else {
            locationManager.startMonitoringSignificantLocationChanges()
        }
        isMonitoring.toggle()
    }
    
    // MARK: - History
    
    func loadLocationHistory() {
        locationHistory = localStorage.loadLocationHistory()
    }
    
    // MARK: - Private
    
    private func refreshStatus() {
        isAuthorized = locationManager.isAuthorized
        isDenied = locationManager.isDenied
        
        if isDenied {
            authorizationStatus = "거부됨"
        } else if isAuthorized {
            authorizationStatus = "허용됨"
        } else {
            authorizationStatus = "미결정"
        }
    }
    
    private func performTask(_ task: () async throws -> Void) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await task()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
