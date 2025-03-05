//
//  ProposedNewGoalsView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-28.
//

import SwiftUI
import AppUI

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
      }
      .padding()
    }
    .groupedBackground()
    .shelf {
      AsyncButton {
        let newHabits = NewHabitResult(
          proposedGoals: proposedGoalsResult.goals,
          proposedToDos: proposedGoalsResult.todos
        )
        try habitsViewModel.performSave(newGoals: newHabits)
        dismiss()
      } label: {
        Text("Let's Do It!")
          .horizontallyCentered()
      }
      .buttonStyle(.primary)
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
