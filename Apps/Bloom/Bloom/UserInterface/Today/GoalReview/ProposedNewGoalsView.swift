//
//  ProposedNewGoalsView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-28.
//

import SwiftUI
import AppUI
import TelemetryDeck

struct ProposedNewGoalsView: View {

  init(proposedGoalsResult: ProposedGoalsResult) {
    self._proposedGoalsResult = State(initialValue: proposedGoalsResult)
  }

  @State private var proposedGoalsResult: ProposedGoalsResult

  @ObservedObject private var habitsViewModel = HabitsViewModel.shared

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        Text("Here are your personalized goals!")
          .onboardingTextStyle()

        ForEach(proposedGoalsResult.todos) { todo in
          ProposedToDoCell(proposedToDo: todo)
            .transition(.scale)
        }

        ForEach($proposedGoalsResult.goals) { goal in
          ProposedGoalCell(proposedGoal: goal)
            .transition(.scale)
        }

        if proposedGoalsResult.removedGoals.isNotEmpty {
          SectionTitleView("Removed Goals")
            .padding(.horizontal)

          ForEachEnumerated(proposedGoalsResult.removedGoals) { (index, goal) in
            RemovedGoalCell(proposedGoal: goal) {
              proposedGoalsResult.removedGoals.remove(at: index)
              proposedGoalsResult.goals.append(goal)
            }
          }
        }
      }
      .padding()
    }
    .animation(.default, value: proposedGoalsResult)
    .groupedBackground()
    .shelf {
      AsyncButton {
        let newHabits = NewHabitResult(
          proposedGoals: proposedGoalsResult.goals,
          proposedToDos: proposedGoalsResult.todos
        )
        try habitsViewModel.performSave(newGoals: newHabits, isAI: true)
        dismiss()
      } label: {
        Text("Let's Do It!")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
    }
    .onAppear {
      TelemetryDeck.signal("Focus Area AI Goals")
    }
  }
}

#Preview {
  ProposedNewGoalsView(
    proposedGoalsResult: ProposedGoalsResult(
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
      ],
      removedGoals: [
        ProposedGoal(
          habitID: nil,
          targetMetric: .proteinIntake,
          value: 120,
          suggestedValue: 120,
          previousValue: 120,
          unitString: "g",
          vitalKind: nil,
          context: nil,
          hasUserEdited: false
        )
      ],
      todos: [
        ProposedToDo(
          todoKind: .logFood,
          todoCadence: .daily,
          vitalKind: .nutrition,
          context: "Log your food daily in order to get nutrition goals."
        )
      ]
    )
  )
}
