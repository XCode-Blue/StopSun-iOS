//
//  EnvironmentValues+LocalStorage.swift
//  StopSun
//
//  Created by taeni on 2/21/26.
//

import SwiftUI

// MARK: - LocalStorage Environment Key

private struct LocalStorageKey: EnvironmentKey {
    @MainActor
    static let defaultValue: any LocalStorageManagerProtocol = LocalStorageManager()
}

extension EnvironmentValues {
    var localStorage: any LocalStorageManagerProtocol {
        get { self[LocalStorageKey.self] }
        set { self[LocalStorageKey.self] = newValue }
    }
}
