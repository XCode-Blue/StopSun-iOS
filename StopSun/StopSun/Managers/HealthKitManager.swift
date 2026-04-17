//
//  HealthKitManager.swift
//  StopSun
//
//  Created by J on 1/27/26.
//

import Foundation
import HealthKit

/// HealthKit 데이터 관리자
///
/// Apple Watch의 `timeInDaylight` 데이터를 조회하고
/// Background Delivery를 통해 실시간 업데이트를 수신합니다.
///
final class HealthKitManager: HealthKitManagerProtocol {
   
    // MARK: - Properties
    
    private let healthStore = HKHealthStore()
    private let timeInDaylightType = HKQuantityType(.timeInDaylight)
    
    /// 권한 요청 완료 플래그 키
    private static let authRequestedKey = "stopsun.permission.healthKitRequested"
    
    /// ObserverQuery 중복 등록 방지
    private var observerQuery: HKObserverQuery?
    
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    /// 권한 요청 완료 여부
    var isAuthorized: Bool {
        guard isAvailable else { return false }
        return UserDefaults.standard.bool(forKey: Self.authRequestedKey)
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async throws {
        guard isAvailable else {
            throw AppError.healthKit(.notAvailable)
        }
        
        let typesToRead: Set<HKObjectType> = [timeInDaylightType]
        
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
        
        UserDefaults.standard.set(true, forKey: Self.authRequestedKey)
    }
    
    // MARK: - Fetch Data
    
    func fetchTodayTimeInDaylight() async throws -> [TimeInDaylight] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let now = Date()
        
        return try await fetchTimeInDaylight(from: startOfDay, to: now)
    }
    
    func fetchTimeInDaylight(from start: Date, to end: Date) async throws -> [TimeInDaylight] {
        guard isAvailable else {
            throw AppError.healthKit(.notAvailable)
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )
        
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: true
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: timeInDaylightType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    let results = (samples as? [HKQuantitySample] ?? []).map { sample in
                        TimeInDaylight(
                            id: sample.uuid,
                            startTime: sample.startDate,
                            endTime: sample.endDate
                        )
                    }
                    continuation.resume(returning: results)
                }
            healthStore.execute(query)
        }
    }
    
    // MARK: - Background Delivery
    
    func enableBackgroundDelivery() async throws {
        guard isAvailable else {
            throw AppError.healthKit(.notAvailable)
        }
        
        try await healthStore.enableBackgroundDelivery(for: timeInDaylightType, frequency: .immediate)
        
        guard observerQuery == nil else {
            Log.debug("ObserverQuery 이미 등록됨 — 스킵")
            return
        }
        
        setupObserverQuery()
    }
    
    // MARK: - Observer Query

    private func setupObserverQuery() {
        let query = HKObserverQuery(
            sampleType: timeInDaylightType,
            predicate: nil
        ) { _, completionHandler, error in
            defer { completionHandler() }
            
            guard error == nil else { return }
            
            NotificationCenter.default.post(name: .healthKitDataDidUpdate, object: nil)
        }
        
        observerQuery = query
        healthStore.execute(query)
    }
}
