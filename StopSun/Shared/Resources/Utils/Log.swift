//
//  Log.swift
//  StopSun
//
//  Created by J on 1/20/26.
//

import Foundation
import os.log

enum Log {
    /// # Level
    /// - debug: 개발 중 코드 디버깅 시 사용할 수 있는 정보
    /// - info: 문제 해결 시 활용할 수 있는, 도움 되지만 필수적이진 않은 정보
    /// - warning: 경고에 대한 정보, 잠재적으로 문제가 될 수 있는 상황
    /// - error: 코드 실행 중 나타난 에러
    /// - fault: 실행 중 발생하는 버그나 잘못된 동작
    
    enum Level {
        case debug
        case info
        case warning
        case error
        case fault
        
        fileprivate var category: String {
            switch self {
            case .debug:
                return "⌨️ DEBUG"
            case .info:
                return "ℹ️ INFO"
            case .warning:
                return "⚠️ WARNING"
            case .error:
                return "❌ ERROR"
            case .fault:
                return "🚫 FAULT"
            }
        }
        
        fileprivate var osLog: OSLog {
            switch self {
            case .debug:
                return OSLog.debug
            case .info:
                return OSLog.info
            case .warning:
                return OSLog.warning
            case .error:
                return OSLog.error
            case .fault:
                return OSLog.fault
            }
        }
    }
    
    private static func log(
        _ message: Any,
        level: Level,
        file: String,
        function: String
    ) {
        #if DEBUG
        let logger = Logger(
            subsystem: OSLog.subsystem,
            category: level.category
        )
        
        let logMessage = "\(level.category): [\(file)] \(function) -> \(message)"
        
        switch level {
        case .debug:
            logger.debug("\(logMessage, privacy: .public)")
        case .info:
            logger.info("\(logMessage, privacy: .public)")
        case .warning:
            logger.warning("\(logMessage, privacy: .private)")
        case .error:
            logger.error("\(logMessage, privacy: .private)")
        case .fault:
            logger.fault("\(logMessage, privacy: .private)")
        }
        #endif
    }
}

extension Log {
    static func debug(_ meesage: Any, file: String = #fileID, function: String = #function) {
        log(meesage, level: .debug, file: file, function: function)
    }
    
    static func info(_ message: Any, file: String = #fileID, function: String = #function) {
        log(message, level: .info, file: file, function: function)
    }
    
    static func warning(_ message: Any, file: String = #fileID, function: String = #function) {
        log(message, level: .warning, file: file, function: function)
    }
    
    static func error(_ message: Any, file: String = #fileID, function: String = #function) {
        log(message, level: .error, file: file, function: function)
    }
    
    static func fault(_ message: Any, file: String = #fileID, function: String = #function) {
        log(message, level: .fault, file: file, function: function)
    }
}

extension OSLog {
    static let subsystem = Bundle.main.bundleIdentifier!
    static let debug = OSLog(subsystem: subsystem, category: "Debug")
    static let info = OSLog(subsystem: subsystem, category: "Info")
    static let warning = OSLog(subsystem: subsystem, category: "Warning")
    static let error = OSLog(subsystem: subsystem, category: "Error")
    static let fault = OSLog(subsystem: subsystem, category: "Fault")
}
