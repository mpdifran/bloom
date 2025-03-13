//
//  OnboardingButtonStyle.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-24.
//

import SwiftUI

struct OnboardingButtonStyle: ButtonStyle {

  @Environment(\.isEnabled) private var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: 0) {
      Spacer(minLength: 0)
      configuration.label
      Spacer(minLength: 0)
    }
    .foregroundStyle(.invertedText)
    .font(.title3)
    .fontDesign(.rounded)
    .bold()
    .padding(.vertical, 20)
    .background {
      RoundedRectangle(cornerRadius: 26)
        .fill(isEnabled ? AnyShapeStyle(.tint) : AnyShapeStyle(.fill))
    }
  }
}

extension ButtonStyle where Self == OnboardingButtonStyle {
  static var onboarding: some ButtonStyle { OnboardingButtonStyle() }
}

#Preview {
  VStack {
    Button("Onboarding") {

    }
    .buttonStyle(.onboarding)

    Button("I'm Disabled") {

    }
    .buttonStyle(.onboarding)
    .disabled(true)
  }
  .padding()
}
