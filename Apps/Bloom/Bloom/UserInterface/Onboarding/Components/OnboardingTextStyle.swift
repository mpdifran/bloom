//
//  OnboardingTextStyle.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-11-19.
//

import SwiftUI

extension View {

  func primaryOnboardingTextStyle() -> some View {
    self
      .font(.title)
      .bold()
      .fontDesign(.rounded)
  }

  func secondaryOnboardingTextStyle() -> some View {
    self
      .font(.title3)
      .bold()
      .fontDesign(.rounded)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      Text("Primary Text Style")
        .primaryOnboardingTextStyle()

      Text("Secondary Text Style")
        .secondaryOnboardingTextStyle()
    }
  }
}
