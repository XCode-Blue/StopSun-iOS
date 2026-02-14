//
//  SSPrimaryButtonStyle.swift
//  StopSun
//
//  Created by taeni on 1/23/26.
//

import SwiftUI

// MARK: - Primary Button Style

struct SSPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    var foregroundColor: Color = .white00
    var backgroundColor: Color = .key00
    var disabledForegroundColor: Color = .white01
    var disabledBackgroundColor: Color = .gray00
    var cornerRadius: CGFloat = 8
    var verticalPadding: CGFloat = 14
    var font: Font = .ssFont(.SB2)
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .frame(maxWidth: .infinity)
            .padding(.vertical, verticalPadding)
            .foregroundStyle(isEnabled ? foregroundColor : disabledForegroundColor)
            .background(isEnabled ? backgroundColor : disabledBackgroundColor)
            .cornerRadius(cornerRadius)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style

struct SSSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    var foregroundColor: Color = .key00
    var backgroundColor: Color = .white01
    var disabledForegroundColor: Color = .text04
    var disabledBackgroundColor: Color = .gray00
    var cornerRadius: CGFloat = 8
    var verticalPadding: CGFloat = 14
    var font: Font = .ssFont(.SB2)
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .frame(maxWidth: .infinity)
            .padding(.vertical, verticalPadding)
            .foregroundStyle(isEnabled ? foregroundColor : disabledForegroundColor)
            .background(isEnabled ? backgroundColor : disabledBackgroundColor)
            .cornerRadius(cornerRadius)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Ghost Button Style

struct SSGhostButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    var foregroundColor: Color = .key00
    var disabledForegroundColor: Color = .text04
    var font: Font = .ssFont(.SB2)
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .foregroundStyle(isEnabled ? foregroundColor : disabledForegroundColor)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Not Allowed Button Style

struct SSNotAllowedButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    var foregroundColor: Color = .text04
    var backgroundColor: Color = .pointBlue00
    var disabledForegroundColor: Color = .white00
    var disabledBackgroundColor: Color = .gray00
    var cornerRadius: CGFloat = 8
    var verticalPadding: CGFloat = 14
    var font: Font = .ssFont(.SB2)
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .frame(maxWidth: .infinity)
            .padding(.vertical, verticalPadding)
            .foregroundStyle(isEnabled ? foregroundColor : disabledForegroundColor)
            .background(isEnabled ? backgroundColor : disabledBackgroundColor)
            .cornerRadius(cornerRadius)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Static Accessors

extension ButtonStyle where Self == SSPrimaryButtonStyle {
    static var ssPrimary: SSPrimaryButtonStyle { SSPrimaryButtonStyle() }
}

extension ButtonStyle where Self == SSSecondaryButtonStyle {
    static var ssSecondary: SSSecondaryButtonStyle { SSSecondaryButtonStyle() }
}

extension ButtonStyle where Self == SSGhostButtonStyle {
    static var ssGhost: SSGhostButtonStyle { SSGhostButtonStyle() }
}

extension ButtonStyle where Self == SSNotAllowedButtonStyle {
    static var ssNotAllowed: SSNotAllowedButtonStyle { SSNotAllowedButtonStyle() }
}

// MARK: - Style Customization

extension SSPrimaryButtonStyle {
    func foregroundColor(_ color: Color) -> Self {
        var style = self
        style.foregroundColor = color
        return style
    }
    
    func backgroundColor(_ color: Color) -> Self {
        var style = self
        style.backgroundColor = color
        return style
    }
    
    func cornerRadius(_ radius: CGFloat) -> Self {
        var style = self
        style.cornerRadius = radius
        return style
    }
    
    func font(_ font: Font) -> Self {
        var style = self
        style.font = font
        return style
    }
    
    func verticalPadding(_ padding: CGFloat) -> Self {
        var style = self
        style.verticalPadding = padding
        return style
    }
}

extension SSSecondaryButtonStyle {
    func foregroundColor(_ color: Color) -> Self {
        var style = self
        style.foregroundColor = color
        return style
    }
    
    func backgroundColor(_ color: Color) -> Self {
        var style = self
        style.backgroundColor = color
        return style
    }
    
    func cornerRadius(_ radius: CGFloat) -> Self {
        var style = self
        style.cornerRadius = radius
        return style
    }
    
    func font(_ font: Font) -> Self {
        var style = self
        style.font = font
        return style
    }
}

// MARK: - Preview

#Preview("SSButtonStyle") {
    VStack(spacing: 16) {
        Section {
            Button("common.button.continue") { }
                .buttonStyle(.ssPrimary)
            
            Button("common.button.continue") { }
                .buttonStyle(.ssPrimary)
                .disabled(true)
        } header: {
            Text("Primary").font(.headline)
        }
        
        Section {
            Button("common.button.cancel") { }
                .buttonStyle(.ssSecondary)
            
            Button("common.button.cancel") { }
                .buttonStyle(.ssSecondary)
                .disabled(true)
        } header: {
            Text("Secondary").font(.headline)
        }
        
        Section {
            Button("common.button.skip") { }
                .buttonStyle(.ssGhost)
        } header: {
            Text("Ghost").font(.headline)
        }
        
        Section {
            Button("Custom Style") { }
                .buttonStyle(
                    SSPrimaryButtonStyle()
                        .backgroundColor(.gage02)
                        .cornerRadius(20)
                        .font(.ssFont(.SB3))
                )
        } header: {
            Text("Custom").font(.headline)
        }
    }
    .padding()
}
