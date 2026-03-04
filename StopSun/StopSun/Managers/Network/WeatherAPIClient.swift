//
//  WeatherAPIClient.swift
//  StopSun
//
//  Created by J on 1/30/26.
//

import Foundation
import Moya

/// WeatherAPI 호출 클라이언트
///
/// Moya를 통해 WeatherAPI 엔드포인트를 호출합니다.
/// WeatherManager에서 사용합니다.
///
final class WeatherAPIClient {
    
    // MARK: - Properties
    
    private let provider: MoyaProvider<WeatherAPI>
    private let decoder: JSONDecoder
    
    // MARK: - Init
    
    init() {
        self.provider = MoyaProvider<WeatherAPI>()
        self.decoder = JSONDecoder()
    }
    
    // MARK: - Request
    
    func request(_ target: WeatherAPI) async throws -> WeatherAPIResponse {
        let response = try await provider.request(target)
        
        Log.info("📡 Status Code: \(response.statusCode)")
        
        if let json = String(data: response.data, encoding: .utf8) {
            Log.info("Weather API Response: \(json)")
        }
        
        let data = try response.filterSuccessfulStatusCodes().data
        
        do {
            return try decoder.decode(WeatherAPIResponse.self, from: data)
        } catch {
            Log.error("Decoding Error: \(error)")
            throw AppError.weather(.parsingFailed)
        }
    }
}

extension MoyaProvider {
    func request(_ target: Target) async throws -> Response {
        try await withCheckedThrowingContinuation { continuation in
            self.request(target) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(_):
                    continuation.resume(throwing: AppError.weather(.requestFailed))
                }
            }
        }
    }
}
