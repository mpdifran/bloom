//
//  ProposedNewGoalsView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-28.
//

import SwiftUI

struct ProposedNewGoalsView: View {
  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        Text("")
          .onboardingTextStyle()
          .transition(.opacity)
      }
      .padding()
    }
    .groupedBackground()
  }
}

#Preview {
  ProposedNewGoalsView()
}
