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
        if let summary = createMarkdownSummary() {
          Text(summary)
            .font(.title3)
            .bold()
            .fontDesign(.rounded)
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

private extension ProposedNewGoalsView {

  func createMarkdownSummary() -> AttributedString? {
    guard let summary = proposedGoalsResult.summary else { return nil }

    let editedSummary = summary.replacingOccurrences(of: "\n", with: "  \n")
    do {
      return try AttributedString(markdown: editedSummary)
    } catch {
      print(error)
    }
    return AttributedString(summary)
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
