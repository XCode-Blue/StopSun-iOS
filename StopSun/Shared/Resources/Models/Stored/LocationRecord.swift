//
//  LocationRecord.swift
//  StopSun
//
//  Created by J on 1/27/26.
//

import Foundation

/// 위치 히스토리 기록
///
/// 백그라운드에서 사용자 위치를 주기적으로 저장합니다.
/// HealthKit 데이터 지연 도착 시 노출 시점의 위치 조회에 사용됩니다.
///
/// ## 저장 정보
/// - 저장 위치: UserDefaults
/// - 저장 키: `stopsun.locationHistory`
///
/// ## 사용 목적
/// HealthKit `timeInDaylight` 데이터는 지연도착할 수 있습니다.
/// 예: 11:00 노출 → 12:30 데이터 도착
/// 이때 11:00 시점의 위치가 필요합니다.
///
/// ```swift
/// // 과거 시점 위치 조회
/// if let location = storage.getLocation(at: exposureTime) {
///     let uv = await weather.fetchUVIndex(at: location)
/// }
/// ```
///
/// - Important: 백그라운드 위치 추적에 Always 권한이 필요합니다.
struct LocationRecord: Codable, Identifiable {
    
    /// 고유 식별자
    let id: UUID
    
    /// 위도
    let latitude: Double
    
    /// 경도
    let longitude: Double
    
    /// 도시 이름
    ///
    /// 역지오코딩으로 조회한 도시명
    /// 기존 데이터 호환을 위해 Optional로 유지
    let cityName: String?
    
    /// 기록 시각
    ///
    /// 과거 위치 조회 시 기준이 됩니다.
    let timestamp: Date
    
    init(
        id: UUID = UUID(),
        latitude: Double,
        longitude: Double,
        cityName: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.cityName = cityName
        self.timestamp = timestamp
    }
    
    /// LocationInfo로부터 생성
    init(from location: LocationInfo) {
        self.id = UUID()
        self.latitude = location.latitude
        self.longitude = location.longitude
        self.cityName = location.cityName
        self.timestamp = Date()
    }
    
    /// LocationInfo로 변환
    var locationInfo: LocationInfo {
        LocationInfo(
            latitude: latitude,
            longitude: longitude,
            cityName: cityName
        )
    }
}
