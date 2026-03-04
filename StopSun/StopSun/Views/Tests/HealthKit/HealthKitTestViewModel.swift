//
//  HealthKitTestViewModel.swift
//  StopSun
//
//  Created by J on 1/29/26.
//

import Foundation

#if DEBUG
@MainActor
final class HealthKitTestViewModel: ObservableObject {
    
    // MARK: - Published
    @Published private(set) var isAuthorized: Bool = false
    @Published private(set) var isBackgroundDeliveryEnabled = false
    @Published private(set) var lastBackgroundDeliveryTime: Date?
    @Published private(set) var backgroundDeliveryCount = 0
    @Published private(set) var todayData: [TimeInDaylight] = []
    @Published private(set) var periodData: [TimeInDaylight] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading = false
    
    @Published var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @Published var endDate = Date()
    
    // MARK: - Dependencies
    private let healthKitManager: any HealthKitManagerProtocol
    
    var isAvailable: Bool {
        healthKitManager.isAvailable
    }
    
    // MARK: - Init
    
    init() {
        self.healthKitManager = DIContainer.shared.healthKit
        setupObservers()
        
        Task {
            await checkAuthorizationAndSetup()
        }
        
    }
    
    // 테스트용
    init(healthKitManager: any HealthKitManagerProtocol) {
        self.healthKitManager = healthKitManager
        setupObservers()
        
        Task {
            await checkAuthorizationAndSetup()
        }
    }
    
    private func checkAuthorizationAndSetup() async {
        // 이미 권한 있으면 바로 설정
        guard healthKitManager.isAvailable else { return }
        
        // 권한 요청 (이미 허용됐으면 바로 완료)
        do {
            try await healthKitManager.requestAuthorization()
            isAuthorized = true
            
            try await healthKitManager.enableBackgroundDelivery()
            isBackgroundDeliveryEnabled = true
            Log.info("초기화 완료")
        } catch {
            Log.error("초기화 실패: \(error.localizedDescription)")
        }
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBackgroundDelivery),
            name: .healthKitDataDidUpdate,
            object: nil
        )
    }
    
    @objc nonisolated private func handleBackgroundDelivery() {
        Task { @MainActor in
            lastBackgroundDeliveryTime = Date()
            backgroundDeliveryCount += 1
            print("🔔 [ViewModel] Background Delivery 수신: \(Date())")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Methods
    
    func requestAuthorization() async {
        errorMessage = nil
        do {
            try await healthKitManager.requestAuthorization()
            isAuthorized = true
            
            try await healthKitManager.enableBackgroundDelivery()
            isBackgroundDeliveryEnabled = true
            Log.info("Background Delivery 활성화")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func enableBackgroundDelivery() async {
        errorMessage = nil
        do {
            try await healthKitManager.enableBackgroundDelivery()
            isBackgroundDeliveryEnabled = true
            Log.info("Background Delivery 활성화됨")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func fetchTodayData() async {
        errorMessage = nil
        isLoading = true
        
        do {
            todayData = try await healthKitManager.fetchTodayTimeInDaylight()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func fetchPeriodData() async {
        errorMessage = nil
        isLoading = true
        
        do {
            periodData = try await healthKitManager.fetchTimeInDaylight(from: startDate, to: endDate)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
#endif
