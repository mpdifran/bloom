//
//  ProposedNewGoalsView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-28.
//

import SwiftUI

struct ProposedNewGoalsView: View {

  init(proposedGoalsResult: ProposedGoalsResult) {
    self._proposedGoalsResult = State(initialValue: proposedGoalsResult)
  }

  @State private var proposedGoalsResult: ProposedGoalsResult

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        if let summary = proposedGoalsResult.summary {
          Text(summary)
            .onboardingTextStyle()
            .transition(.opacity)
        }

        ForEach($proposedGoalsResult.goals) { goal in
          ProposedGoalCell(proposedGoal: goal)
        }
      }
      .padding()
    }
    .groupedBackground()
  }
}

#Preview {
  ProposedNewGoalsView(
    proposedGoalsResult: ProposedGoalsResult(
      summary: "I've made some tweaks to your goals!",
      goals: [
        ProposedGoal(
          habitID: nil,
          targetMetric: .bikeDistance,
          value: 10,
          suggestedValue: 10,
          previousValue: 5,
          unitString: "km",
          vitalKind: nil,
          context: "Bike more for better health.",
          hasUserEdited: false
        )
      ]
    )
  )
}
