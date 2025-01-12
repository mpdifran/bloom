//
//  OnboardingFocusAreasView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-28.
//

import SwiftUI
import AppUI
import DataContainer
import TelemetryDeck

struct OnboardingFocusAreasView: View {
  let onContinue: () -> Void

  @State private var index = 0

  @State private var vitals = [VitalModel]()

  @State private var hasApprovedOfVitals = false
  @State private var showContinue = false
  @State private var didContinue = false
  @State private var hasStartedCalculateGoals = false
  @State private var newHabitResult = NewHabitResult()
  @State private var presentedSheet: AnyView?
  @State private var error: Error?

  private let vitalsViewModel = VitalsViewModel.shared

  @ObservedObject private var habitsViewModel = HabitsViewModel.shared

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text("Great! Let's determine which parts of your health we should focus on.")
          .onboardingTextStyle()
          .appear(with: 1, currentIndex: index)


        if vitals.isEmpty {
          CircularSpinnerView()
            .foregroundStyle(.tint)
            .horizontallyCentered()
            .appear(with: 2, currentIndex: index)
        } else {
          Group {
            ForEach(vitals) { vital in
              Menu {
                if vitals.count > 1 && index == 2 {
                  Button("Remove", systemImage: "trash", role: .destructive) {
                    vitals.removeAll(where: { $0.id == vital.id })
                  }
                }
              } label: {
                MiniVitalCell(vital: vital)
              }
              .buttonStyle(.plain)
              .transition(.scale)
            }

            if !hasApprovedOfVitals && vitals.count < 3 {
              AddVitalCell()
                .onTapGesture {
                  presentedSheet = VitalPickerView(
                    excluding: excludingVitalKinds
                  ) { vitalModel in
                    vitals.append(vitalModel)
                  }.asAny
                }
                .transition(.scale)
            }
          }
        }

        Text("Now let's calculate some goals to tackle these based on your Health data.")
          .onboardingTextStyle()
          .appear(with: 3, currentIndex: index, secondaryIfNotCurrentIndex: false)

        VStack {
          if newHabitResult.focusVitals.isNotEmpty {
            SectionTitleView("Suggested Goals")
              .padding(.horizontal)

            ForEach($newHabitResult.focusVitals) { focusVital in
              FocusVitalGoalCell(
                focusVital: focusVital,
                includeActions: true
              )
              .transition(.scale)
            }
          }

          if newHabitResult.proposedGoals.isNotEmpty {
            SectionTitleView("Goals You Added")
              .padding(.horizontal)

            ForEach($newHabitResult.proposedGoals) { proposedGoal in
              ProposedGoalCell(
                proposedGoal: proposedGoal,
                includeActions: true
              )
              .transition(.scale)
            }
          }

          if newHabitResult.proposedToDos.isNotEmpty {
            SectionTitleView("To Do")
              .padding(.horizontal)

            ForEach(newHabitResult.proposedToDos) { proposedToDo in
              ProposedToDoCell(proposedToDo: proposedToDo)
                .transition(.scale)
            }
          }
        }
        .appear(with: 4, currentIndex: index, secondaryIfNotCurrentIndex: false)
      }
      .horizontalAlignment(.leading)
      .padding()
    }
    .if(showContinue) {
      $0.shelf {
        Button("Continue") {
          if !hasApprovedOfVitals {
            hasApprovedOfVitals = true
            Task {
              await bulkAdvanceIndexRound2()
            }
          } else {
            do {
              try habitsViewModel.performSave(newGoals: newHabitResult)
              didContinue.toggle()
              onContinue()
            } catch {
              self.error = error
            }
          }
        }
        .buttonStyle(.onboarding)
        .disabled(!canContinue)
      }
    }
    .animation(.bouncy, value: vitals.count)
    .animation(.default, value: index)
    .sensoryFeedback(.selection, trigger: index)
    .sensoryFeedback(.impact, trigger: didContinue)
    .sheet($presentedSheet)
    .onChange(of: index) { _, _ in
      Task {
        await loadVitals()
        await loadGoals()
      }
    }
    .topSafeAreaBlur()
    .task {
      await bulkAdvanceIndexRound1()
    }
    .alert(error: $error)
    .onAppear {
      TelemetryDeck.signal("OB Focus Areas")
    }
  }
}

private extension OnboardingFocusAreasView {

  var excludingVitalKinds: [VitalModel.Kind] {
    vitals.map { $0.id } + [.bodyComposition, .cycleTracking]
  }

  var canContinue: Bool {
    index == 2 || index == 4
  }

  func bulkAdvanceIndexRound1() async {
    while index < 2 {
      await advanceIndex()
    }

    await Delay(1200)

    showContinue = true
  }

  func bulkAdvanceIndexRound2() async {
    while index < 4 {
      await advanceIndex()
    }

    await Delay(1200)

    showContinue = true
  }

  func advanceIndex() async {
    index += 1

    await Delay(1200)
  }

  func loadVitals() async {
    guard index >= 2 && vitals.isEmpty else { return }

    await Delay(1200)

    let focusVitals = await HabitsFactory.shared.recommendedFocusVitals()

    for vital in focusVitals {
      await Delay(100)
      self.vitals.append(vital)
    }
  }

  func loadGoals() async {
    guard index >= 4 && !hasStartedCalculateGoals else { return }

    hasStartedCalculateGoals = true

    self.newHabitResult = await habitsViewModel.generateProposedHabits(vitals: vitals)
  }
}

#Preview {
  OnboardingFocusAreasView { }
}
