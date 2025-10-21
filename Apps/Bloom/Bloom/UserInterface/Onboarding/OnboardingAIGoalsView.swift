//
//  OnboardingAIGoalsView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-10.
//

import SwiftUI
import AppUI
import DataContainer
import TelemetryDeck
import BloomUI

extension OnboardingAIGoalsView {
  enum Mode {
    case loading
    case loaded
    case failed
  }
}

struct OnboardingAIGoalsView: View {
  let onContinue: () -> Void

  @State private var mode: Mode = .loading
  @State private var proposedGoals = ProposedGoalsResult()
  @State private var didContinue = false
  @State private var presentedSheet: AnyView?
  @State private var error: Error?

  @ObservedObject private var habitsViewModel = HabitsViewModel.shared

  var body: some View {
    Group {
      switch mode {
      case .loaded, .loading:
        mainScrollContent
      case .failed:
        loadFailedView
      }
    }
    .groupedBackground()
    .sensoryFeedback(.impact, trigger: didContinue)
    .animation(.default, value: proposedGoals)
    .alert(error: $error)
    .sheet($presentedSheet)
    .task {
      await loadAIGoals()
    }
    .onAppear {
      TelemetryDeck.signal("OB Focus Areas")
    }
  }
}

private extension OnboardingAIGoalsView {

  var mainScrollContent: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text("Great! Let's create some personalized goals for you based on your data.")
          .onboardingTextStyle()

        switch mode {
        case .loading:
          CircularSpinnerView()
            .foregroundStyle(.tint)
            .horizontallyCentered()
        case .loaded:
          if proposedGoals.goals.isNotEmpty {
            SectionTitleView("Suggested Goals")
              .padding(.horizontal)
            ForEach($proposedGoals.goals) { goal in
              ProposedGoalCell(
                proposedGoal: goal,
                includeActions: true
              )
              .transition(.scale)
            }
          }

          if proposedGoals.todos.isNotEmpty {
            SectionTitleView("To Do")
              .padding(.horizontal)

            ForEach(proposedGoals.todos) { todo in
              ProposedToDoCell(proposedToDo: todo)
                .transition(.scale)
            }
          }
        case .failed:
          EmptyView()
        }
      }
      .horizontalAlignment(.leading)
      .padding()
    }
    .shelf {
      shelfContent
    }
  }

  var loadFailedView: some View {
    VStack {
      Spacer()
      ContentUnavailableView {
        Label("Failed to Load Goals", systemSymbol: .boltHorizontalFill)
      } description: {
        Text("We failed to load your goals, please try again.")
      } actions: {
        AsyncButton {
          TelemetryDeck.signal(
            "OB Focus Area Result Failed Event",
            parameters: ["event": "Retry AI Goal Setting on Fail"]
          )
          await loadAIGoals()
        } label: {
          Text("Try Again")
        }
        .buttonStyle(.primary)

        Button {
          TelemetryDeck.signal(
            "OB Focus Area Result Failed Event",
            parameters: ["event": "Skip AI Goal Setting on Fail"]
          )
          onContinue()
        } label: {
          Text("Skip")
            .bold()
        }
      }
      Spacer()
    }
  }

  @ViewBuilder
  var shelfContent: some View {
    switch mode {
    case .loaded:
      AsyncButton {
        try await saveAIGoals()
      } label: {
        Text("Continue")
      }
      .buttonStyle(.onboarding)
    case .loading, .failed:
      EmptyView()
    }
  }
}

private extension OnboardingAIGoalsView {

  func showUndeterminedPermissionsSheet() async {
    await withCheckedContinuation { continuation in
      presentedSheet = ExternalHealthPrivacyView {
        continuation.resume()
      }.asAny
    }
  }

  func loadAIGoals() async {
    self.mode = .loading

//    if permissionsManager.hasUndeterminedPermissions() {
//      await withCheckedContinuation { continuation in
//        presentedSheet = ExternalHealthPrivacyView {
//          continuation.resume()
//        }.asAny
//      }
//    }

    do {
      let result = try await AIGoalManager.shared.proposeNewGoals()

      self.proposedGoals = result
      self.mode = .loaded
      TelemetryDeck.signal(
        "OB Focus Area Result",
        parameters: ["result": "AI Goal Loading Succeeded"]
      )
    } catch {
      self.error = error
      self.mode = .failed
      TelemetryDeck.signal(
        "OB Focus Area Result",
        parameters: ["result": "AI Goal Loading Failed"]
      )
    }
  }

  func saveAIGoals() async throws {
    let newHabits = NewHabitResult(
      proposedGoals: proposedGoals.goals,
      proposedToDos: proposedGoals.todos
    )
    try habitsViewModel.performSave(newGoals: newHabits)

    TelemetryDeck.signal("OB Focus Area - Saved Goals")

    onContinue()
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingAIGoalsView { }
  }
}
