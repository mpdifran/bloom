//
//  SettingsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-16.
//

import SwiftUI
import AppUI
import SwiftData
import DataContainer
import HealthKit

struct SettingsView: View {

  @ObservedObject private var healthManager = HealthManager.shared
  @ObservedObject private var toDoManager = ToDoManager.shared

  @Bindable private var reportViewModel = ReportCoordinatorViewModel.shared
  @Bindable private var unitPreferences = HealthUnitPreferences.shared

  @AppStorage("TodayView.showWeightWidget") private var showWeightWidget: Bool = true
  @AppStorage("TodayView.showNutritionTodayWidget") private var showNutritionTodayWidget: Bool = true

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
        todoSection
        reportSection
        widgetsSection
        unitsSection
        supportSection
        developerSection
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
        .padding(.horizontal)

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

      if healthManager.healthStore.sex() == .female {
        SettingsSectionContainer {
          SettingsCell("Breastfeeding") {
            Toggle("", isOn: healthManager.$isBreastfeeding)
              .tint(.mutedGreen)
          }

          Divider()

          SettingsCell("Pregnant") {
            Toggle("", isOn: healthManager.$isPregnant)
              .tint(.mutedGreen)
          }
        }
      }
    }
  }

  var habitsSection: some View {
    VStack {
      SectionTitleView("\(userAddedHabits.count) Habits")
        .padding(.horizontal)

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

  var todoSection: some View {
    VStack {
      SectionTitleView("To Dos")
        .padding(.horizontal)

      ForEachEnumerated(toDoManager.userAddableToDos) { (index, todo) in
        SettingsHabitCell(
          image: Image(systemName: todo.kind.systemImage),
          title: todo.kind.name,
          subtitle: todo.cadence.name
        )
        .tint(todo.kind.color)
        .onTapGesture {
          presentedSheet = ToDoCadenceConfigureView(todo: $toDoManager.userAddableToDos[index]).asAny
        }
      }
    }
  }

  var reportSection: some View {
    VStack {
      SectionTitleView("Reports")
        .padding(.horizontal)

      SettingsSectionContainer {
        SettingsCell("Morning Report on Wake Up") {
          Toggle("", isOn: $reportViewModel.showMorningReportOnWakeUp)
            .tint(.mutedGreen)
        }

        Divider()

        SettingsCell("Evening Report") {
          DatePicker(
            "",
            selection: $reportViewModel.eveningReportDate,
            displayedComponents: .hourAndMinute
          )
        }
      }
    }
  }

  var widgetsSection: some View {
    VStack {
      SectionTitleView("Widgets")
        .padding(.horizontal)

      SettingsSectionContainer {
        SettingsCell("Weight Widget") {
          Toggle("", isOn: $showWeightWidget)
            .tint(.mutedGreen)
        }

        Divider()

        SettingsCell("Nutrition Widget") {
          Toggle("", isOn: $showNutritionTodayWidget)
            .tint(.mutedGreen)
        }
      }

      Text("Widgets will only show if they're enabled above, and there's a corresponding Focus Area, Habit, or Health Goal.")
        .horizontalAlignment(.leading)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  var unitsSection: some View {
    VStack {
      SectionTitleView("Units")
        .padding(.horizontal)

      SettingsSectionContainer {
        SettingsCell("Distance") {
          Picker("", selection: $unitPreferences.distanceUnit) {
            ForEach(HKUnit.distanceUnits, id: \.unitString) { unit in
              Text(unit.descriptiveUnitName)
                .tag(unit)
            }
          }
        }

        Divider()

        SettingsCell("Liquid Volume") {
          Picker("", selection: $unitPreferences.liquidVolumeUnit) {
            ForEach(HKUnit.liquidVolumeUnits, id: \.unitString) { unit in
              Text(unit.descriptiveUnitName)
                .tag(unit)
            }
          }
        }

        Divider()

        SettingsCell("Weight") {
          Picker("", selection: $unitPreferences.weightUnit) {
            ForEach(HKUnit.weightUnits, id: \.unitString) { unit in
              Text(unit.descriptiveUnitName)
                .tag(unit)
            }
          }
        }
      }
    }
  }

  var supportSection: some View {
    VStack {
      SectionTitleView("Support")
        .padding(.horizontal)

      SettingsSectionContainer {
        SettingsCell("App Version") {
          Text(appVersion ?? "Unknown")
        }

        Divider()

        SettingsCell("Submit Feedback", showDisclosureIndicator: true) {
          Image(systemName: "heart.fill")
            .foregroundStyle(.mutedRed)
        }
        .onTapGesture {
          if healthManager.name.isEmpty {
            presentedSheet = UserNamePrompt {
              presentedSheet = FeatureRequestScreen().asAny
            }
            .asAny
          } else {
            presentedSheet = FeatureRequestScreen().asAny
          }
        }
      }
    }
  }

  var developerSection: some View {
    VStack {
      SectionTitleView("Developer")
        .padding(.horizontal)

      SettingsSectionContainer {
        SettingsCell("Developer Tools", showDisclosureIndicator: true) {
          EmptyView()
        }
        .onTapGesture {
          presentedSheet = DeveloperSettingsView().asAny
        }
      }
    }
  }
}

private extension SettingsView {

  var appVersion: String? {
    guard let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else { return nil }

    if let buildString = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
      return "\(versionString) (\(buildString))"
    }
    return versionString
  }
}

#Preview {
  PreviewSheetPresent {
    SettingsView()
  }
}
