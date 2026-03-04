//
//  TypographyPreviewView.swift
//  StopSun
//
//  Created by taeni on 1/8/26.
//


import SwiftUI

#if DEBUG
struct TypographyPreviewView: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                section("Regular") {
                    text("R1 · Regular 12", .R1)
                    text("R2 · Regular 14", .R2)
                    text("R3 · Regular 15", .R3)
                    text("R4 · Regular 15 (160%)", .R4)
                    text("R5 · Regular 16", .R5)
                }

                section("Medium") {
                    text("M1 · Medium 10", .M1)
                    text("M2 · Medium 15", .M2)
                    text("M3 · Medium 16", .M3)
                    text("M4 · Medium 20", .M4)
                }

                section("Semibold") {
                    text("SB1 · Semibold 12", .SB1)
                    text("SB2 · Semibold 16", .SB2)
                    text("SB3 · Semibold 20", .SB3)
                    text("SB4 · Semibold 24", .SB4)
                }

                section("Bold") {
                    text("B1 · Bold 24", .B1)
                    text("B2 · Bold 28", .B2)
                }

                section("Large Display") {
                    text("SB5 · Semibold 75", .SB5)
                }
            }
            .padding()
        }
    }

    // MARK: - Components

    private func section(
        _ title: String,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            content()
        }
    }

    private func text(_ text: String, _ style: TextStyleToken) -> some View {
        Text(text)
            .textStyle(style)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    TypographyPreviewView()
}
#endif
