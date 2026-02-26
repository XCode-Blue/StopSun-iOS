//
//  AppError.swift
//  StopSun
//
//  Created by taeni on 2/2/26.
//

import Foundation

/// 앱 전체 에러 타입
///
/// 각 Manager에서 발생하는 에러를 통합 관리합니다.
/// L10n을 통해 다국어 메시지를 제공합니다.
///
/// ## 사용 예시
/// ```swift
/// throw AppError.healthKit(.authorizationDenied)
/// throw AppError.network(.noConnection)
/// ```
///
enum AppError: Error, Equatable {
    
    // MARK: - Error Categories
    
    case healthKit(HealthKitError)
    case location(LocationError)
    case weather(WeatherError)
    case storage(StorageError)
    case notification(NotificationError)
    case network(NetworkError)
    case watchConnectivity(WatchConnectivityError)
    case unknown(String?)
    
    // MARK: - HealthKit Errors
    
    enum HealthKitError: Error, Equatable {
        case notAvailable
        case authorizationDenied
        case dataFetchFailed
        case backgroundDeliveryFailed
    }
    
    // MARK: - Location Errors
    
    enum LocationError: Error, Equatable {
        case servicesDisabled
        case authorizationDenied
        case locationUnavailable
        case geocodingFailed
    }
    
    // MARK: - Weather Errors
    
    enum WeatherError: Error, Equatable {
        case requestFailed
        case parsingFailed
        case invalidLocation
        case quotaExceeded
    }
    
    // MARK: - Storage Errors
    
    enum StorageError: Error, Equatable {
        case saveFailed
        case loadFailed
        case dataCorrupted
        case insufficientSpace
    }
    
    // MARK: - Notification Errors
    
    enum NotificationError: Error, Equatable {
        case authorizationDenied
        case scheduleFailed
        case invalidDate
    }
    
    // MARK: - Network Errors
    
    enum NetworkError: Error, Equatable {
        case noConnection
        case timeout
        case serverError(Int)
    }
    
    // MARK: - Watch Connectivity Errors
    
    enum WatchConnectivityError: Error, Equatable {
        case notReachable
        case sessionInactive
        case transferFailed
    }
}

// MARK: - Localized Messages

extension AppError {
    
    /// 에러 제목 (Alert Title)
    var title: String {
        switch self {
        case .healthKit:
            return L10n.Error.Title.healthKit
        case .location:
            return L10n.Error.Title.location
        case .weather:
            return L10n.Error.Title.weather
        case .storage:
            return L10n.Error.Title.storage
        case .notification:
            return L10n.Error.Title.notification
        case .network:
            return L10n.Error.Title.network
        case .watchConnectivity:
            return L10n.Error.Title.watchConnectivity
        case .unknown:
            return L10n.Error.Title.unknown
        }
    }
    
    /// 에러 메시지 (Alert Message)
    var message: String {
        switch self {
        case .healthKit(let error):
            return error.message
        case .location(let error):
            return error.message
        case .weather(let error):
            return error.message
        case .storage(let error):
            return error.message
        case .notification(let error):
            return error.message
        case .network(let error):
            return error.message
        case .watchConnectivity(let error):
            return error.message
        case .unknown(let customMessage):
            return customMessage ?? L10n.Error.unknown
        }
    }
    
    /// 재시도 가능 여부
    var isRetryable: Bool {
        switch self {
        case .healthKit(let error):
            return error.isRetryable
        case .location(let error):
            return error.isRetryable
        case .weather(let error):
            return error.isRetryable
        case .storage(let error):
            return error.isRetryable
        case .notification(let error):
            return error.isRetryable
        case .network(let error):
            return error.isRetryable
        case .watchConnectivity(let error):
            return error.isRetryable
        case .unknown:
            return true
        }
    }
    
    /// 설정 앱으로 이동 필요 여부
    var requiresSettings: Bool {
        switch self {
        case .healthKit(.authorizationDenied),
             .location(.authorizationDenied),
             .location(.servicesDisabled),
             .notification(.authorizationDenied):
            return true
        default:
            return false
        }
    }
}

// MARK: - HealthKitError Messages

extension AppError.HealthKitError {
    
    var message: String {
        switch self {
        case .notAvailable:
            return L10n.Error.HealthKit.notAvailable
        case .authorizationDenied:
            return L10n.Error.HealthKit.authorizationDenied
        case .dataFetchFailed:
            return L10n.Error.HealthKit.dataFetchFailed
        case .backgroundDeliveryFailed:
            return L10n.Error.HealthKit.backgroundDeliveryFailed
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .notAvailable, .authorizationDenied:
            return false
        case .dataFetchFailed, .backgroundDeliveryFailed:
            return true
        }
    }
}

// MARK: - LocationError Messages

extension AppError.LocationError {
    
    var message: String {
        switch self {
        case .servicesDisabled:
            return L10n.Error.Location.servicesDisabled
        case .authorizationDenied:
            return L10n.Error.Location.authorizationDenied
        case .locationUnavailable:
            return L10n.Error.Location.locationUnavailable
        case .geocodingFailed:
            return L10n.Error.Location.geocodingFailed
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .servicesDisabled, .authorizationDenied:
            return false
        case .locationUnavailable, .geocodingFailed:
            return true
        }
    }
}

// MARK: - WeatherError Messages

extension AppError.WeatherError {
    
    var message: String {
        switch self {
        case .requestFailed:
            return L10n.Error.Weather.requestFailed
        case .parsingFailed:
            return L10n.Error.Weather.parsingFailed
        case .invalidLocation:
            return L10n.Error.Weather.invalidLocation
        case .quotaExceeded:
            return L10n.Error.Weather.quotaExceeded
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .requestFailed, .parsingFailed:
            return true
        case .invalidLocation, .quotaExceeded:
            return false
        }
    }
}

// MARK: - StorageError Messages

extension AppError.StorageError {
    
    var message: String {
        switch self {
        case .saveFailed:
            return L10n.Error.Storage.saveFailed
        case .loadFailed:
            return L10n.Error.Storage.loadFailed
        case .dataCorrupted:
            return L10n.Error.Storage.dataCorrupted
        case .insufficientSpace:
            return L10n.Error.Storage.insufficientSpace
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .saveFailed, .loadFailed:
            return true
        case .dataCorrupted, .insufficientSpace:
            return false
        }
    }
}

// MARK: - NotificationError Messages

extension AppError.NotificationError {
    
    var message: String {
        switch self {
        case .authorizationDenied:
            return L10n.Error.Notification.authorizationDenied
        case .scheduleFailed:
            return L10n.Error.Notification.scheduleFailed
        case .invalidDate:
            return L10n.Error.Notification.invalidDate
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .authorizationDenied, .invalidDate:
            return false
        case .scheduleFailed:
            return true
        }
    }
}

// MARK: - NetworkError Messages

extension AppError.NetworkError {
    
    var message: String {
        switch self {
        case .noConnection:
            return L10n.Error.Network.noConnection
        case .timeout:
            return L10n.Error.Network.timeout
        case .serverError(let code):
            return L10n.Error.Network.serverError(code)
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .noConnection, .timeout:
            return true
        case .serverError(let code):
            // 5xx 서버 에러는 재시도 가능
            return code >= 500
        }
    }
}

// MARK: - WatchConnectivityError Messages

extension AppError.WatchConnectivityError {
    
    var message: String {
        switch self {
        case .notReachable:
            return L10n.Error.WatchConnectivity.notReachable
        case .sessionInactive:
            return L10n.Error.WatchConnectivity.sessionInactive
        case .transferFailed:
            return L10n.Error.WatchConnectivity.transferFailed
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .notReachable, .sessionInactive, .transferFailed:
            return true
        }
    }
}
