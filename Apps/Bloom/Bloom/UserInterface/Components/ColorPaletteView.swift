//
//  ColorPaletteView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-21.
//

import SwiftUI

struct ColorPaletteView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Muted") {
                    ColorCell(name: String(localized: "Muted Blue", comment: "Developer colour palette swatch name"), color: .mutedBlue)
                    ColorCell(name: String(localized: "Muted Green", comment: "Developer colour palette swatch name"), color: .mutedGreen)
                    ColorCell(name: String(localized: "Muted Indigo", comment: "Developer colour palette swatch name"), color: .mutedIndigo)
                    ColorCell(name: String(localized: "Muted Light Blue", comment: "Developer colour palette swatch name"), color: .mutedLightBlue)
                    ColorCell(name: String(localized: "Muted Orange", comment: "Developer colour palette swatch name"), color: .mutedOrange)
                    ColorCell(name: String(localized: "Muted Pink", comment: "Developer colour palette swatch name"), color: .mutedPink)
                    ColorCell(name: String(localized: "Muted Purple", comment: "Developer colour palette swatch name"), color: .mutedPurple)
                    ColorCell(name: String(localized: "Muted Red", comment: "Developer colour palette swatch name"), color: .mutedRed)
                    ColorCell(name: String(localized: "Muted Teal", comment: "Developer colour palette swatch name"), color: .mutedTeal)
                    ColorCell(name: String(localized: "Muted Yellow", comment: "Developer colour palette swatch name"), color: .mutedYellow)
                }
            }
            .navigationTitle("Color Palette")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                  DismissButton()
                }
            }
        }
    }
}

private struct ColorCell: View {
    let name: String
    let color: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name)
                    .foregroundStyle(color)

                Text(name)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background {
                        Capsule()
                            .fill(color)
                    }

                Text(name)
                    .font(.caption)
                    .foregroundStyle(color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background {
                        Capsule()
                            .fill(.background.secondary)
                    }
            }

            Spacer()

            Circle()
                .fill(color.tertiary)
                .frame(square: 40)

            Circle()
                .fill(color)
                .frame(square: 40)
        }
    }
}

#Preview {
    ColorPaletteView()
}
