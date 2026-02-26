////
////  ErrorTestView.swift
////  StopSun
////
////  Created by taeni on 2/2/26.
////
//
//#if DEBUG
//import SwiftUI
//
///// 에러 UI 테스트용 뷰
/////
///// 다양한 에러 타입을 발생시켜 Alert 동작을 확인합니다.
/////
//struct ErrorTestView: View {
//    
//    @EnvironmentObject var errorHandler: ErrorHandler
//    
//    var body: some View {
//        NavigationView {
//            List {
//                Section("HealthKit Errors") {
//                    errorButton(.healthKit(.notAvailable))
//                    errorButton(.healthKit(.authorizationDenied))
//                    errorButton(.healthKit(.dataFetchFailed))
//                    errorButton(.healthKit(.backgroundDeliveryFailed))
//                }
//                
//                Section("Location Errors") {
//                    errorButton(.location(.servicesDisabled))
//                    errorButton(.location(.authorizationDenied))
//                    errorButton(.location(.locationUnavailable))
//                    errorButton(.location(.geocodingFailed))
//                }
//                
//                Section("Weather Errors") {
//                    errorButton(.weather(.requestFailed))
//                    errorButton(.weather(.parsingFailed))
//                    errorButton(.weather(.invalidLocation))
//                    errorButton(.weather(.quotaExceeded))
//                }
//                
//                Section("Storage Errors") {
//                    errorButton(.storage(.saveFailed))
//                    errorButton(.storage(.loadFailed))
//                    errorButton(.storage(.dataCorrupted))
//                    errorButton(.storage(.insufficientSpace))
//                }
//                
//                Section("Notification Errors") {
//                    errorButton(.notification(.authorizationDenied))
//                    errorButton(.notification(.scheduleFailed))
//                    errorButton(.notification(.invalidDate))
//                }
//                
//                Section("Network Errors") {
//                    errorButton(.network(.noConnection))
//                    errorButton(.network(.timeout))
//                    errorButton(.network(.serverError(500)))
//                    errorButton(.network(.serverError(404)))
//                }
//                
//                Section("Watch Connectivity Errors") {
//                    errorButton(.watchConnectivity(.notReachable))
//                    errorButton(.watchConnectivity(.sessionInactive))
//                    errorButton(.watchConnectivity(.transferFailed))
//                }
//                
//                Section("Unknown Error") {
//                    errorButton(.unknown(nil))
//                    errorButton(.unknown("커스텀 에러 메시지입니다."))
//                }
//                
//                Section("With Retry") {
//                    Button("Network Error + Retry") {
//                        errorHandler.handle(.network(.timeout)) {
//                            print("재시도 실행됨!")
//                        }
//                    }
//                }
//            }
//            .navigationTitle("Error Test")
//        }
//        .errorAlert(errorHandler)
//    }
//    
//    @ViewBuilder
//    private func errorButton(_ error: AppError) -> some View {
//        Button {
//            errorHandler.handle(error)
//        } label: {
//            VStack(alignment: .leading, spacing: 4) {
//                Text(error.title)
//                    .font(.headline)
//                Text(error.message)
//                    .font(.caption)
//                    .foregroundStyle(.secondary)
//                    .lineLimit(2)
//                
//                HStack(spacing: 8) {
//                    if error.isRetryable {
//                        Label("Retryable", systemImage: "arrow.clockwise")
//                            .font(.caption2)
//                            .foregroundStyle(.blue)
//                    }
//                    if error.requiresSettings {
//                        Label("Settings", systemImage: "gear")
//                            .font(.caption2)
//                            .foregroundStyle(.orange)
//                    }
//                }
//            }
//        }
//        .foregroundStyle(.primary)
//    }
//}
//
//// MARK: - Preview
//
//#Preview("Error Test") {
//    ErrorTestView()
//        .environmentObject(ErrorHandler())
//}
//#endif
