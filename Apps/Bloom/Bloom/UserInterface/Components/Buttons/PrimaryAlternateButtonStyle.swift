//
//  PrimaryAlternateButtonStyle.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-20.
//

import SwiftUI

struct PrimaryAlternateButtonStyle: ButtonStyle {

  @Environment(\.isEnabled) private var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    if #available(iOS 26.0, *) {
      HStack {
        configuration.label
      }
      .bold()
      .padding(.vertical, 16)
      .padding(.horizontal)
      .background(isEnabled ? AnyShapeStyle(.tint.opacity(0.3)) : AnyShapeStyle(.fill.opacity(0.5)))
      .background(.regularMaterial)
      .foregroundStyle(.tint)
      .clipShape(Capsule())
    } else {
      HStack {
        configuration.label
      }
      .bold()
      .padding(.vertical, 16)
      .padding(.horizontal)
      .background(isEnabled ? AnyShapeStyle(.tint.opacity(0.3)) : AnyShapeStyle(.fill.opacity(0.5)))
      .background(.regularMaterial)
      .foregroundStyle(.tint)
      .clipShape(RoundedRectangle(cornerRadius: 17))
    }
  }
}

extension ButtonStyle where Self == PrimaryAlternateButtonStyle {
  static var primaryAlternate: some ButtonStyle { PrimaryAlternateButtonStyle() }
}

#Preview {
  VStack {
    Button("Tap Me", systemImage: "sparkles") {

    }
    .buttonStyle(.primaryAlternate)

    Button("I'm Disabled") {

    }
    .buttonStyle(.primaryAlternate)
    .disabled(true)
  }
  .padding()
  .tint(.blue)
}
