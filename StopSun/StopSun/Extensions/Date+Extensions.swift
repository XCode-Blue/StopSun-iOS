//
//  Date+Extensions.swift
//  StopSun
//
//  Created by J on 1/30/26.
//

import Foundation

// MARK: - Date Extensions

extension Date {
    
    // MARK: - API용 (고정 포맷)
     
     /// API 요청용 날짜 문자열 (yyyy-MM-dd)
     ///
     /// ```swift
     /// Date().toAPIDateString  // "2026-01-30"
     /// ```
    var toAPIDateString: String {
        formatted(.iso8601.year().month().day().dateSeparator(.dash))
    }
    
    // MARK: - UI용 (Localized)
    
    /// 시간만 표시 (오후 2:30)
    var toTimeString: String {
        formatted(date: .omitted, time: .shortened)
    }
    
    /// 날짜만 표시 (1월 30일)
    var toDateString: String {
        formatted(date: .abbreviated, time: .omitted)
    }
    
    /// 날짜 + 시간 표시 (1월 30일 오후 2:30)
    var toDateTimeString: String {
        formatted(date: .abbreviated, time: .shortened)
    }
    
    /// 상대 시간 표시 (5분 전, 1시간 전)
    var toRelativeString: String {
        formatted(.relative(presentation: .named))
    }
    
    /// 날짜 + 요일 표시 (2월 15일, 토요일)
    var toDayWithWeekdayString: String {
        formatted(.dateTime.month().day().weekday(.wide).locale(Locale(identifier: "ko_KR")))
    }
}
