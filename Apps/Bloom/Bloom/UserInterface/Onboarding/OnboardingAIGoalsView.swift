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

  @ObservedObject private var permissionsManager = ExternalHealthMetricPermissionManager.shared
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
        Text("Great! Let's create some personalized goals for you based on your health data.")
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
          await loadAIGoals()
        } label: {
          Text("Try Again")
        }
        .buttonStyle(.primary)

        Button {
          onContinue()
        } label: {
          Text("Skip")
            .bold()
        }
      }
      Spacer()
    }
  }

  var shelfContent: some View {
    AsyncButton {
      try await saveAIGoals()
    } label: {
      Text("Continue")
    }
    .buttonStyle(.onboarding)
  }
}

private extension OnboardingAIGoalsView {

  func loadAIGoals() async {
    self.mode = .loading

    if permissionsManager.hasUndeterminedPermissions() {
      await withCheckedContinuation { continuation in
        presentedSheet = ExternalHealthPrivacyView {
          continuation.resume()
        }.asAny
      }
    }

    do {
      let result = try await AIGoalManager.shared.proposeNewGoals()

      self.proposedGoals = result
      self.mode = .loaded
    } catch {
      self.error = error
      self.mode = .failed
    }
  }

  func saveAIGoals() async throws {
    let newHabits = NewHabitResult(
      proposedGoals: proposedGoals.goals,
      proposedToDos: proposedGoals.todos
    )
    try habitsViewModel.performSave(newGoals: newHabits)
    onContinue()
  }
}

#Preview {
  OnboardingAIGoalsView { }
}
