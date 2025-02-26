//
//  ReviewGoalsView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-26.
//

import SwiftUI

struct ReviewGoalsView: View {

  @State private var index = 1

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text("Let's take a look at how you did over the last 7 days.")
          .onboardingTextStyle()
          .transition(.opacity)
          .appear(with: 1, currentIndex: index)
      }
    }
    .groupedBackground()
    .task {
      await advanceToGoalReview()
    }
  }
}

private extension ReviewGoalsView {

  func advanceToGoalReview() async {
    while index < 2 {
      await delayAdvanceIndex()
    }
  }

  func delayAdvanceIndex() async {
    await Delay(1000)
    index += 1
  }
}

#Preview {
  ReviewGoalsView()
}
