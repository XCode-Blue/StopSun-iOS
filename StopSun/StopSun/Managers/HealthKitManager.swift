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
    
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    var isAuthorized: Bool {
        _ = healthStore.authorizationStatus(for: timeInDaylightType)
        return true
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async throws {
        // TODO: 구현
        guard isAvailable else {
            throw AppError.healthKit(.notAvailable)
        }
        
        let typesToRead: Set<HKObjectType> = [timeInDaylightType]
        
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
    }
    
    // MARK: - Fetch Data
    
    func fetchTodayTimeInDaylight() async throws -> [TimeInDaylight] {
        // TODO: 구현
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
            
            // TODO: - NotificationCenter 파일 분리 필요
            NotificationCenter.default.post(name: .healthKitDataDidUpdate, object: nil)
        }
        
        healthStore.execute(query)
    }
}
