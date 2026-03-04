//
//  LocationManager.swift
//  StopSun
//
//  Created by J on 1/27/26.
//

import Foundation
import CoreLocation

/// 위치 관리자
///
/// CoreLocation을 통해 현재 위치를 조회하고
/// Significant Location Changes를 모니터링합니다.
///
/// ## 권한 흐름
/// `requestAlwaysAuthorization()` 호출 시 iOS가 자동으로 2단계 처리:
/// 1. "앱 사용 중 허용" 팝업 표시
/// 2. 이후 iOS가 적절한 시점에 "항상 허용" 팝업 표시
///
/// ## Info.plist 필수 키
/// - `NSLocationWhenInUseUsageDescription`
/// - `NSLocationAlwaysAndWhenInUseUsageDescription`
///
final class LocationManager: NSObject, LocationManagerProtocol {
    
    // MARK: - Properties
    
    private let clLocationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    /// 위치 요청 continuation
     private var locationContinuation: CheckedContinuation<CLLocation, Error>?
     
     /// 권한 요청 continuation
     private var authContinuation: CheckedContinuation<Void, Never>?
     
     /// 타임아웃 Task (정상 응답 시 취소)
     private var timeoutTask: Task<Void, Never>?
    
    // MARK: - Init
    
    override init() {
        super.init()
        clLocationManager.delegate = self
        clLocationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        clLocationManager.allowsBackgroundLocationUpdates = true
    }
    
    // MARK: - Authorization
    
    var isAuthorized: Bool {
        switch clLocationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }
    
    var isDenied: Bool {
        clLocationManager.authorizationStatus == .denied
    }
    
    func requestAuthorization() async {
        let status = clLocationManager.authorizationStatus
        
        // 이미 결정된 상태면 바로 리턴
        guard status == .notDetermined else {
            Log.debug("[Location] 권한 이미 결정됨: \(status.rawValue)")
            return
        }
        
        await withCheckedContinuation { continuation in
            authContinuation = continuation
            clLocationManager.requestWhenInUseAuthorization()
        }
        
        let newStatus = clLocationManager.authorizationStatus
        
        switch newStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            Log.info("[Location] 권한 허용됨")
            
        case .denied:
            Log.warning("[Location] 권한 거부됨 — 설정에서 위치 권한을 허용해주세요")
            
        case .restricted:
            Log.warning("[Location] 권한 제한됨 — 기기 설정에 의해 위치 사용이 제한되어 있습니다")
            
        case .notDetermined:
            Log.warning("[Location] 권한 미결정 — 예상하지 못한 상태")
            
        @unknown default:
            Log.warning("[Location] 알 수 없는 권한 상태: \(newStatus.rawValue)")
        }
    }
    
    // MARK: - Current Location
    
    func getCurrentLocation() async throws -> LocationInfo {
        guard isAuthorized else {
            throw AppError.location(.authorizationDenied)
        }
        
        let clLocation = try await requestSingleLocation()
        let cityName = await reverseGeocode(clLocation)
        
        return LocationInfo(
            latitude: clLocation.coordinate.latitude,
            longitude: clLocation.coordinate.longitude,
            cityName: cityName
        )
    }
    
    // MARK: - Significant Location Changes
    
    func startMonitoringSignificantLocationChanges() {
        guard isAuthorized else {
            Log.warning("[Location] 권한 없음 — 위치 모니터링 불가")
            return
        }
        clLocationManager.startMonitoringSignificantLocationChanges()
        Log.info("Significant Location Changes 모니터링 시작")
    }
    
    func stopMonitoringSignificantLocationChanges() {
        clLocationManager.stopMonitoringSignificantLocationChanges()
        Log.info("Significant Location Changes 모니터링 중지")
    }
    
    // MARK: - Private Methods
    
    /// 단일 위치 요청
    ///
    /// `requestLocation()`은 위치를 한 번 받고 자동으로 중지됩니다.
    /// 동시에 여러 요청이 들어오면 기존 요청을 취소합니다.
    /// 10초 내 응답이 없으면 타임아웃 에러를 반환합니다.
    private func requestSingleLocation() async throws -> CLLocation {
        // 기존 요청이 있으면 취소
        if let existing = locationContinuation {
            existing.resume(throwing: CancellationError())
            locationContinuation = nil
        }
        timeoutTask?.cancel()
        
        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            clLocationManager.requestLocation()
            
            // 타임아웃: 응답 없으면 에러 반환
            timeoutTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 10 * 1_000_000_000)
                
                guard let self, let pending = self.locationContinuation else { return }
                self.locationContinuation = nil
                pending.resume(throwing: AppError.location(.locationUnavailable))
                Log.warning("[Location] 위치 요청 타임아웃")
            }
        }
    }
    
    /// 역지오코딩으로 도시 이름 조회
    ///
    /// 실패해도 nil 반환 (도시 이름은 선택 정보)
    private func reverseGeocode(_ location: CLLocation) async -> String? {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            return placemarks.first?.locality
        } catch {
            Log.warning("역지오코딩 실패: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Significant Location Change에서 LocationInfo 생성 후 Notification 발송
    private func postLocationChangeNotification(from location: CLLocation) {
        Task {
            let cityName = await reverseGeocode(location)
            let locationInfo = LocationInfo(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                cityName: cityName
            )
            
            NotificationCenter.default.post(
                name: .locationDidChange,
                object: nil,
                userInfo: [NotificationUserInfoKey.location: locationInfo]
            )
            
            Log.info("위치 변경 감지: \(cityName ?? "알 수 없음") (\(location.coordinate.latitude), \(location.coordinate.longitude))")
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 단일 위치 요청 응답
        if let continuation = locationContinuation {
            timeoutTask?.cancel()
            timeoutTask = nil
            locationContinuation = nil
            continuation.resume(returning: location)
            return
        }
        
        // Significant Location Changes 응답
        postLocationChangeNotification(from: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Log.error("위치 조회 실패: \(error.localizedDescription)")
        
        if let continuation = locationContinuation {
            timeoutTask?.cancel()
            timeoutTask = nil
            locationContinuation = nil
            continuation.resume(throwing: AppError.location(.locationUnavailable))
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Log.info("위치 권한 변경: \(status.debugDescription)")
        
        // 권한 요청 대기 중이면 완료
        if status != .notDetermined {
            authContinuation?.resume()
            authContinuation = nil
        }
    }
}

// MARK: - CLAuthorizationStatus + Debug

extension CLAuthorizationStatus {
    var debugDescription: String {
        switch self {
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorizedAlways: return "authorizedAlways"
        case .authorizedWhenInUse: return "authorizedWhenInUse"
        @unknown default: return "unknown(\(rawValue))"
        }
    }
}
