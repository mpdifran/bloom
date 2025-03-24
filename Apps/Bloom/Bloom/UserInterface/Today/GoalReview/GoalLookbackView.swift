//
//  GoalLookbackView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-26.
//

import SwiftUI
import AppUI
import TelemetryDeck

struct GoalLookbackView: View {
  let onCalculateProposedGoals: (ProposedGoalsResult) -> Void

  @State var viewModel = ViewModel()

  @State private var hasGoals = true
  @State private var goalLookbackDetails = [GoalLookbackDetails]()
  @State private var presentedSheet: AnyView?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        section1
      }
      .padding()
    }
    .shelf {
      AsyncButton {
        try await calculateGoals()
      } label: {
        Text(hasGoals ? "Update Goals" : "Get Goals")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
    }
    .groupedBackground()
    .animation(.bouncy, value: goalLookbackDetails)
    .animation(.default, value: hasGoals)
    .sensoryFeedback(.selection, trigger: goalLookbackDetails.count)
    .sheet($presentedSheet)
    .task {
      let details = await viewModel.loadGoalHistory()
      await Delay(1000)

      hasGoals = details.isNotEmpty
      for detail in details {
        goalLookbackDetails.append(detail)
        await Delay(100)
      }
    }
    .onAppear {
      TelemetryDeck.signal("Focus Area Goal Lookback")
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

      if hasGoals {
        if goalLookbackDetails.isEmpty {
          CircularSpinnerView()
            .foregroundStyle(.tint)
            .frame(height: 300)
        }

        ForEach(goalLookbackDetails) { details in
          GoalLookbackCell(
            goal: details.goal,
            history: details.goalMetHistory
          )
          .transition(.scale)
        }
      } else {
        ContentUnavailableView(
          "No Goals",
          systemSymbol: .sparkles,
          description: Text("You don't have any goals set.")
        )
        .frame(height: 300)
      }
    }
  }
}

private extension GoalLookbackView {

  func calculateGoals() async throws {
//    if permissionsManager.hasUndeterminedPermissions() {
//      await withCheckedContinuation { continuation in
//        presentedSheet = ExternalHealthPrivacyView {
//          continuation.resume()
//        }.asAny
//      }
//    }

    let proposedGoals = try await viewModel.proposeNewGoals()
    onCalculateProposedGoals(proposedGoals)
  }
}

#Preview {
  PreviewEnvironment {
    GoalLookbackView { (_) in }
  }
}
