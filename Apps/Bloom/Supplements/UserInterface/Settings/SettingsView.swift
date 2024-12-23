//
//  SettingsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-16.
//

import SwiftUI
import SwiftData
import DataContainer

struct SettingsView: View {

  @ObservedObject private var healthManager = HealthManager.shared
  
  @State private var presentedSheet: AnyView?

  @Query private var userAddedHabits: [Habit]
  @Query private var allHabits: [Habit]

  init() {
    _userAddedHabits = Query(
      filter: #Predicate<Habit> { habit in
        habit.endDate == nil && !habit.isSuggested
      },
      sort: \Habit.startDate,
      order: .forward
    )
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        userSection
        healthGoalsSection
        habitsSection
      }
      .padding()
    }
    .groupedBackground()
    .presentationCornerRadius(30)
    .presentationDragIndicator(.visible)
    .sheet($presentedSheet)
  }
}

extension SettingsView {

  var userSection: some View {
    VStack(spacing: 16) {
      Circle()
        .fill(.fill)
        .frame(square: 140)
      TextField("", text: $healthManager.name, prompt: Text("Your Name"))
        .font(.title)
        .bold()
        .fontDesign(.rounded)
        .multilineTextAlignment(.center)
    }
    .padding(.top, 40)
  }

  var healthGoalsSection: some View {
    VStack {
      SectionTitleView("Health Goals")

      HStack {
        SettingsHealthGoalCell(
          image: Image(.logWeightIcon),
          value: healthManager.healthGaolAssociatedValueString(),
          subtitle: healthManager.healthGoalDisplayString()
        )
        .tint(.mutedIndigo)
        .onTapGesture {
          presentedSheet = HealthGoalEditCard().asAny
        }

        Group {
          if let activityLevel = healthManager.userReportedActivityLevel {
            SettingsHealthGoalCell(
              image: Image(systemName: activityLevel.systemImage),
              value: activityLevel.name,
              subtitle: "Activity level"
            )
            .tint(activityLevel.barColor)
          } else {
            SettingsHealthGoalCell(
              image: Image(systemName: "figure"),
              value: "No level set",
              subtitle: "Activity level"
            )
          }
        }
        .onTapGesture {
          presentedSheet = ActivityLevelEditCard().asAny
        }
      }
    }
  }

  var habitsSection: some View {
    VStack {
      SectionTitleView("\(userAddedHabits.count) Habits")

      ForEach(userAddedHabits) { habit in
        SettingsHabitCell(
          image: Image(systemName: habit.targetMetric.systemImage),
          title: habit.targetMetric.name,
          subtitle: habit.displayQuantity
        )
        .tint(habit.targetMetric.color)
      }
      if remainingMetrics.isNotEmpty {
        SettingsAddHabitCell()
          .onTapGesture {
            presentedSheet = UserAddedGoalPicker().asAny
          }
      }
    }
  }

  var remainingMetrics: [TargetMetric] {
    TargetMetric.allCases.filter({ targetMetric in
      !allHabits.contains(where: { habit in
        habit.targetMetric == targetMetric
      })
    })
  }
}

#Preview {
  PreviewSheetPresent {
    SettingsView()
  }
}
