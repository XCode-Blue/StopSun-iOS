//
//  LocationManager.swift
//  StopSun
//
//  Created by J on 1/27/26.
//

import Foundation

/// 위치 관리자
final class LocationManager: LocationManagerProtocol {
    
    var isAuthorized: Bool { false }
    
    var isDenied: Bool { false }
    
    func requestAuthorization() async {
        // TODO: 구현
    }
    
    func getCurrentLocation() async throws -> LocationInfo {
        // TODO: 구현
        return LocationInfo(latitude: 0, longitude: 0)
    }
    
    func startMonitoringSignificantLocationChanges() {
        // TODO: 구현
    }
    
    func stopMonitoringSignificantLocationChanges() {
        // TODO: 구현
    }
}
