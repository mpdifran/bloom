//
//  GoalLookbackView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-26.
//

import SwiftUI
import AppUI

struct GoalLookbackView: View {
  let onCalculateProposedGoals: (ProposedGoalsResult) -> Void

  @State var viewModel = ViewModel()

  @State private var index = 0
  @State private var goalLookbackDetails = [GoalLookbackDetails]()

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        section1
      }
      .padding()
    }
    .shelf {
      AsyncButton {
        let proposedGoals = try await viewModel.proposeNewGoals()
        onCalculateProposedGoals(proposedGoals)
      } label: {
        Text("Update Goals")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
    }
    .groupedBackground()
    .animation(.bouncy, value: goalLookbackDetails)
    .sensoryFeedback(.selection, trigger: goalLookbackDetails.count)
    .sensoryFeedback(.selection, trigger: index)
    .task {
      await advanceToGoalReview()
    }
    .task {
      let details = await viewModel.loadGoalHistory()

      await Delay(1000)

      for detail in details {
        goalLookbackDetails.append(detail)
        await Delay(100)
      }
    }
  }
}

private extension GoalLookbackView {

  @ViewBuilder
  var section1: some View {
    VStack {
      Text("Let's take a look at how you did over the last 7 days.")
        .onboardingTextStyle()
        .transition(.opacity)

      if goalLookbackDetails.isEmpty {
        CircularSpinnerView()
          .foregroundStyle(.tint)
      } else {
        ForEach(goalLookbackDetails) { details in
          GoalLookbackCell(
            goal: details.goal,
            history: details.goalMetHistory
          )
          .transition(.scale)
        }
      }
    }
    .appear(with: 1, currentIndex: index, secondaryIfNotCurrentIndex: false)
  }
}

private extension GoalLookbackView {

  func advanceToGoalReview() async {
    while index < 1 {
      await delayAdvanceIndex()
    }
  }

  func delayAdvanceIndex() async {
    await Delay(1000)
    index += 1
  }
}

#Preview {
  GoalLookbackView { (_) in }
}
