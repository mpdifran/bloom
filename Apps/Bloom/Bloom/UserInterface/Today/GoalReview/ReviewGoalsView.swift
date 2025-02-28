//
//  ReviewGoalsView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-26.
//

import SwiftUI
import AppUI

struct ReviewGoalsView: View {

  @State var viewModel = ViewModel()

  @State private var index = 1

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        section1
      }
    }
    .groupedBackground()
    .animation(.bouncy, value: viewModel.goalLookbackDetails)
    .task {
      await advanceToGoalReview()
    }
    .task {
      await viewModel.loadGoalHistory()
    }
  }
}

private extension ReviewGoalsView {

  @ViewBuilder
  var section1: some View {
    Text("Let's take a look at how you did over the last 7 days.")
      .onboardingTextStyle()
      .transition(.opacity)
      .appear(with: 1, currentIndex: index)
  }

  @ViewBuilder
  var goalsLookback: some View {
    Group {
      if viewModel.goalLookbackDetails.isEmpty {
        CircularSpinnerView()
          .foregroundStyle(.tint)
      } else {
        ForEach(viewModel.goalLookbackDetails) { details in
          GoalLookbackCell(
            goal: details.goal,
            history: details.goalMetHistory.map { $0.goalMet }
          )
        }
      }
    }
    .appear(with: 2, currentIndex: index)
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
