//
//  GradientColorsEditor.swift
//  Gardener
//
//  Created by Claude on 2025-12-05.
//

import SwiftUI

struct GradientColorsEditor: View {
  @Binding var colors: [String]

  var body: some View {
    Section("Button Gradient Colors") {
      ForEach(colors.indices, id: \.self) { index in
        HStack {
          HexColorPicker(title: "Color \(index + 1)", hexString: $colors[index])

          Button(role: .destructive) {
            colors.remove(at: index)
          } label: {
            Image(systemName: "trash")
          }
          .buttonStyle(.borderless)
        }
      }
      .onMove { colors.move(fromOffsets: $0, toOffset: $1) }

      Button {
        colors.append("#007AFF")
      } label: {
        Label("Add Color", systemImage: "plus")
      }

      if colors.count >= 2 {
        gradientPreview
      }
    }
  }

  @ViewBuilder
  private var gradientPreview: some View {
    let swiftUIColors = colors.compactMap { Color(hex: $0) }
    if swiftUIColors.count >= 2 {
      LinearGradient(
        colors: swiftUIColors,
        startPoint: .leading,
        endPoint: .trailing
      )
      .frame(height: 30)
      .clipShape(Capsule())
    }
  }
}

#Preview {
  Form {
    GradientColorsEditor(colors: .constant(["#FF5733", "#007AFF"]))
  }
  .padding()
}
