//
//  SecondaryButtonStyle.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-26.
//

import SwiftUI

struct SecondaryButtonStyle: ButtonStyle {

  @Environment(\.isEnabled) private var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    HStack {
      configuration.label
    }
    .bold()
    .padding(.vertical, 8)
    .padding(.horizontal, 16)
    .background(isEnabled ? AnyShapeStyle(.tint) : AnyShapeStyle(.fill))
    .foregroundStyle(.invertedText)
    .clipShape(Capsule())
  }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
  static var secondary: some ButtonStyle { SecondaryButtonStyle() }
}

#Preview {
  VStack {
    Button("Tap Me", systemImage: "sparkles") {

    }
    .buttonStyle(.secondary)

    Button("I'm Disabled") {

    }
    .buttonStyle(.secondary)
    .disabled(true)
  }
  .padding()
  .tint(.mutedYellow)
}
