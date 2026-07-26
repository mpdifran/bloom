//
//  PrimaryButtonStyle.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-25.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {

  @Environment(\.isEnabled) private var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    HStack {
      configuration.label
    }
    .bold()
    .padding(.vertical, 16)
    .padding(.horizontal)
    .background(isEnabled ? AnyShapeStyle(.tint) : AnyShapeStyle(.fill))
    .foregroundStyle(.invertedText)
    .clipShape(Capsule())
  }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
  static var primary: some ButtonStyle { PrimaryButtonStyle() }
}

#Preview {
  VStack {
    Button("Tap Me", systemImage: "sparkles") {

    }
    .buttonStyle(.primary)

    Button("I'm Disabled") {

    }
    .buttonStyle(.primary)
    .disabled(true)
  }
  .padding()
  .tint(.blue)
}
