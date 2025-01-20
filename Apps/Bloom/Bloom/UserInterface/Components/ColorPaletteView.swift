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
                    ColorCell(name: "Muted Blue", color: .mutedBlue)
                    ColorCell(name: "Muted Green", color: .mutedGreen)
                    ColorCell(name: "Muted Indigo", color: .mutedIndigo)
                    ColorCell(name: "Muted Light Blue", color: .mutedLightBlue)
                    ColorCell(name: "Muted Orange", color: .mutedOrange)
                    ColorCell(name: "Muted Pink", color: .mutedPink)
                    ColorCell(name: "Muted Purple", color: .mutedPurple)
                    ColorCell(name: "Muted Red", color: .mutedRed)
                    ColorCell(name: "Muted Teal", color: .mutedTeal)
                    ColorCell(name: "Muted Yellow", color: .mutedYellow)
                }
            }
            .navigationTitle("Color Palette")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .bold()
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
