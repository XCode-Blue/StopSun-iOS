//
//  SSButton.swift
//  StopSun
//
//  Created by taeni on 1/9/26.
//

import SwiftUI

// MARK: - SSButton

struct SSButton: View {
    
    enum Style {
        case primary
        case secondary
        case ghost
        case notAllowed
    }
    
    private let title: String
    private let style: Style
    private let action: () -> Void
    
    // MARK: - Initializer
    
    /// String 사용 (L10n과 함께 사용)
    ///
    /// ```swift
    /// SSButton(L10n.Button.continue) { }
    /// SSButton(L10n.Button.cancel, style: .secondary) { }
    /// ```
    init(
        _ title: String,
        style: Style = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        switch style {
        case .primary:
            Button(action: action) { Text(title) }
                .buttonStyle(.ssPrimary)
        case .secondary:
            Button(action: action) { Text(title) }
                .buttonStyle(.ssSecondary)
        case .ghost:
            Button(action: action) { Text(title) }
                .buttonStyle(.ssGhost)
        case .notAllowed:
            Button(action: action) { Text(title) }
                .buttonStyle(.ssNotAllowed)
            
        }
    }
}

// MARK: - Preview

#Preview("SSButton") {
    VStack(spacing: 16) {
        Button {
            print(L10n.Button.next)
        } label: { Text(L10n.Button.next) }
            .buttonStyle(.ssPrimary)
        
        Button {
            print(L10n.Button.cancel)
        } label: { Text(L10n.Button.cancel) }
            .buttonStyle(.ssSecondary)
    }
    .padding()
}
