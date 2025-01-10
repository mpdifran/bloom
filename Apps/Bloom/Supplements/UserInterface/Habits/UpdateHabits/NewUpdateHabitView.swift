//
//  NewUpdateHabitView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-20.
//

import SwiftUI
import AppUI
import DataContainer

struct NewUpdateHabitView: View {

  @ObservedObject private var habitsViewModel = HabitsViewModel.shared

  @State private var isLoading = true
  @State private var proposedGoals = [ProposedGoal]()
  @State private var proposedToDos = [ProposedToDo]()
  @State private var error: Error?

  @Environment(\.modelContext) var modelContext
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          HStack {
            VStack(alignment: .leading, spacing: 20) {
              Text("Let's Start the Week Right!")
                .font(.title2)
                .bold()

              Text("Review your goals for the week. These recommendations are based off the data from the past two weeks.")
                .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
          }
          .cardContainer()

          newHabitsSection
        }
        .horizontallyCentered()
        .padding()
      }
      .groupedBackground()
      .navigationTitle("Focus Areas")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
          .bold()
        }
      }
      .shelf {
        ProminentButton("Save") {
          do {
            try habitsViewModel.performSave(
              proposedGoals: proposedGoals,
              proposedToDos: proposedToDos
            )
            dismiss()
          } catch {
            self.error = error
          }
        }
      }
    }
    .tint(.mutedBlue)
    .alert(error: $error)
    .animation(.bouncy, value: proposedGoals)
    .task {
      let result = await habitsViewModel.generateProposedHabits()
      proposedGoals = result.proposedGoals
      proposedToDos = result.proposedToDos

      isLoading = false
    }
  }
}

private extension NewUpdateHabitView {

  @ViewBuilder
  var newHabitsSection: some View {
    if isLoading {
      loadingView
    } else if proposedGoals.isEmpty && proposedToDos.isEmpty {
      contentUnavailableView
    } else {
      contentView
    }
  }

  var loadingView: some View {
    VStack(spacing: 20) {
      CircularSpinnerView()
        .foregroundStyle(.tint)
      Text("Loading Focus Areas")
        .font(.title2)
        .bold()
    }
    .horizontallyCentered()
    .padding(.top, 40)
  }

  var contentUnavailableView: some View {
    ContentUnavailableView(
      "Oops",
      systemImage: "exclamationmark.triangle.fill",
      description: Text("There was a problem loading your focus areas. Please try again later.")
    )
  }

  @ViewBuilder
  var contentView: some View {
    if proposedGoals.isNotEmpty {
      SectionTitleView("Proposed Goals")
        .padding(.horizontal)

      ForEachEnumerated(proposedGoals) { (index, _) in
        ProposedHabitCell(
          proposedHabit: $proposedGoals[index],
          includeActions: true
        )
        .transition(.scale)
      }
    }

    if proposedToDos.isNotEmpty {
      SectionTitleView("To Do")
        .padding(.horizontal)

      ForEach(proposedToDos) { proposedToDo in
        ProposedToDoCell(proposedToDo: proposedToDo)
          .transition(.scale)
      }
    }
  }
}

#Preview {
  NewUpdateHabitView()
}
