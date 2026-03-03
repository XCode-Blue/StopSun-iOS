//
//  AppTab.swift
//  StopSun
//
//  Created by J on 2/23/26.
//

import Foundation

/// 하단 탭바의 탭 정의
///
/// ## 탭 구성
/// | 탭 | 라벨 | 아이콘 |
/// |---|---|---|
/// | dashboard | 대시보드 | 커스텀 에셋 (임시: sun.max.fill) |
/// | records | 기록 | chart.bar.fill |
/// | settings | 설정 | gearshape |
///
enum AppTab: String, CaseIterable, Hashable {
    case dashboard
//    case records
    case info
    case settings
    
    // MARK: - Display
    
    /// 탭 라벨
    // TODO: -(추후 L10n으로 설정해야함)
    var title: String {
        switch self {
        case .dashboard: "대시보드"
//        case .records: "기록"
        case .info: "정보"
        case .settings: "설정"
        }
    }
    
    /// 탭 아이콘 (커스텀)
    var iconName: String {
        switch self {
        case .dashboard: "clipboard"
//        case .records: "bar-chart"
        case .info: "info"
        case .settings: "settings"
        }
    }
    
    var selectedIconName: String {
        switch self {
        case .dashboard: "clipboard-tint"
//        case .records: "bar-chart-tint"
        case .info: "info-tint"
        case .settings: "settings-tint"
        }
    }
    
}
