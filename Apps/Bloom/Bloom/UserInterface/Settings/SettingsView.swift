//
//  SettingsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-16.
//

import SFSafeSymbols
import SwiftUI
import AppUI
import SwiftData
import DataContainer
import HealthKit
import RevenueCat
import TelemetryDeck
import Swipy
import CoreHealth

struct SettingsView: View {

  @ObservedObject private var healthManager = HealthManager.shared
  @ObservedObject private var toDoManager = ToDoManager.shared
  @ObservedObject private var habitsViewModel = HabitsViewModel.shared
  @ObservedObject private var apiHost = APIHost.shared

  @Bindable private var reportViewModel = ReportCoordinatorViewModel.shared
  @Bindable private var unitPreferences = HealthUnitPreferences.shared

  @AppStorage("TodayView.showWeightWidget") private var showWeightWidget: Bool = true
  @AppStorage("TodayView.showNutritionTodayWidget") private var showNutritionTodayWidget: Bool = true
  @AppStorage(.FeatureFlag.developerMode) private var showDeveloperMode: Bool = false

  @Environment(\.openURL) private var openURL
  @Environment(\.modelContext) private var modelContext
  @Environment(ThemeController.self) private var themeController

  @ObservedObject private var userController = UserController.shared
  @ObservedObject private var entitlementController = EntitlementController.shared
  @State private var shouldRequestHealthPermissions = false
  @State private var isSwipingAnItem = false
  @State private var presentedSheet: AnyView?
  @State private var confirmationDialogDetails: ConfirmationDialogDetails?
  @State private var error: Error?

  @Query private var userAddedHabits: [Habit]
  @Query private var reminders: [Reminder]

  init() {
    _userAddedHabits = Query(
      filter: #Predicate<Habit> { habit in
        habit.endDate == nil
      },
      sort: \Habit.startDate,
      order: .forward
    )
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        userSection
        healthPermissionsSection
        healthGoalsSection
        personalizationSection
        habitsSection
        remindersSection
        workoutEquipmentSection
        unitsSection
        subscriptionSection
        supportSection
        authenticationSection
        if showDeveloperMode {
          developerSection
        }
      }
      .padding()
    }
    .scrollDisabled(isSwipingAnItem)
    .groupedBackground()
    .presentationCornerRadius(30)
    .presentationDragIndicator(.visible)
    .animation(.default, value: shouldRequestHealthPermissions)
    .animation(.easeInOut, value: showDeveloperMode)
    .sheet($presentedSheet)
    .confirmationDialog($confirmationDialogDetails)
    .alert(error: $error)
    .onAppear {
      #if DEBUG
      showDeveloperMode = true
      #endif
    }
    .task {
      await checkHealthKitPermissions()
    }
  }
}

private extension SettingsView {

  func checkHealthKitPermissions() async {
    do {
      let shouldRequest = try await HealthPermissionChecker.shared.checkAccessForAllTypes() == .shouldRequest
      self.shouldRequestHealthPermissions = shouldRequest
    } catch {
      TelemetryDeck.errorOccurred(
        id: "SettingsView.HealthPermissionChecker.checkAccessForAllTypes",
        category: .thrownException,
        message: error.localizedDescription
      )
      print(error)
    }
  }
}

private extension SettingsView {

  var userSection: some View {
    VStack(spacing: 16) {
      UserProfilePhotoView(canEdit: true)

      TextField("", text: $healthManager.name, prompt: Text("Your Name"))
        .font(.title)
        .bold()
        .fontDesign(.rounded)
        .multilineTextAlignment(.center)
        .submitLabel(.done)

      CurrentThemeView()
        .selectable()
        .onTapGesture {
          presentedSheet = ThemeSelectionCard().asAny
        }
    }
    .padding(.top, 40)
  }

  var healthGoalsSection: some View {
    VStack {
      SectionTitleView("Health Focus")
        .padding(.horizontal)

      HStack {
        SettingsHealthGoalCell(
          image: Image(systemSymbol: .scope),
          value: "Focus",
          subtitle: healthManager.focus
        )
        .tint(.mutedIndigo)
        .onTapGesture {
          presentedSheet = HealthGoalEditCard().asAny
        }
      }
    }
  }

  var personalizationSection: some View {
    VStack {
      SectionTitleView("Personalization")
        .padding(.horizontal)

      SettingsSectionContainer {
        SettingsCell("Personal Details", showDisclosureIndicator: true) {
          EmptyView()
        }
        .onTapGesture {
          presentedSheet = PersonalizationSettingsView().asAny
        }
      }
    }
  }

  @ViewBuilder
  var healthPermissionsSection: some View {
    if shouldRequestHealthPermissions {
      VStack {
        SectionTitleView("Health Permissions")
          .padding(.horizontal)

        SettingsSectionContainer {
          SettingsHealthAppCell(title: "Grant New Permissions")
            .onTapGesture {
              Task {
                await HealthPermissionChecker.shared.requestAccessIfNeeded()
                await checkHealthKitPermissions()
              }
            }
        }
      }
    }
  }

  var habitsSection: some View {
    VStack {
      SectionTitleView("\(userAddedHabits.count) Goals")
        .padding(.horizontal)

      ForEach(userAddedHabits) { habit in
        SettingsHabitCell(
          image: Image(systemSymbol: SFSymbol(rawValue: habit.targetMetric.systemImage)),
          title: habit.targetMetric.name,
          subtitle: "\(habit.displayQuantity) • \(habit.timePeriod.name)"
        )
        .tint(habit.targetMetric.color)
        .onTapGesture {
          presentedSheet = EditUserAddedHabitView(habit: habit) { _ in }.asAny
        }
        .contextMenu {
          Button("Delete", systemSymbol: .trash, role: .destructive) {
            delete(habit: habit)
          }
        }
      }
      if remainingMetrics.isNotEmpty {
        SettingsAddHabitCell()
          .onTapGesture {
            // Check if user has reached their goal limit
            if let maxGoals = entitlementController.maxGoals, userAddedHabits.count >= maxGoals {
              EntitledPresent(presentedSheet: $presentedSheet) {
                NewGoalCard()
              }
            } else {
              presentedSheet = NewGoalCard().asAny
            }
          }
      }
    }
  }

  var remainingMetrics: [TargetMetric] {
    TargetMetric.allCases.filter({ targetMetric in
      !userAddedHabits.contains(where: { habit in
        habit.targetMetric == targetMetric
      })
    })
  }
  
  var workoutEquipmentSection: some View {
    VStack {
      SectionTitleView("Workouts")
        .padding(.horizontal)
      
      SettingsSectionContainer {
        SettingsCell("Workout Equipment") {
          HStack {
            Text("\(healthManager.selectedWorkoutEquipment.count) selected")
              .foregroundStyle(.secondary)
            DisclosureIndicator()
          }
        }
        .onTapGesture {
          presentedSheet = WorkoutEquipmentView().asAny
        }
      }
    }
  }
  
  var remindersSection: some View {
    VStack {
      SectionTitleView("Reminders")
        .padding(.horizontal)
      
      SettingsSectionContainer {
        SettingsCell("Reminders") {
          HStack {
            Text("\(reminders.count)")
              .foregroundStyle(.secondary)
            DisclosureIndicator()
          }
        }
        .onTapGesture {
          presentedSheet = RemindersEditListView().asAny
        }
      }
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

        Divider()

        SettingsCell("Height") {
          Picker("", selection: $unitPreferences.heightUnit) {
            ForEach(HKUnit.heightUnits, id: \.unitString) { unit in
              Text(unit.descriptiveUnitName)
                .tag(unit)
            }
          }
        }
      }
    }
  }

  @ViewBuilder
  var subscriptionSection: some View {
    VStack {
      SectionTitleView("Bloom Plus")
        .padding(.horizontal)

      SettingsSectionContainer {
        if let entitlementInfo = entitlementController.bloomProEntitlement {
          SettingsCell("Plan") {
            Text(entitlementInfo.activeSubscriptionName)
          }

          Divider()

          if let cellInfo = entitlementInfo.statusCellInfo {
            SettingsCell(cellInfo.title) {
              Text(cellInfo.date, style: .date)
            }
            Divider()
          }

          if entitlementInfo.isActive {
            SettingsCell("Manage Subscription") {
              DisclosureIndicator()
            }
            .onTapGesture {
              ThrowingUserTask(error: $error) {
                try await Purchases.shared.showManageSubscriptions()
                TelemetryDeck.signal("View Manage Subscriptions")
              }
            }
          } else {
            SettingsCell("Subscribe to Bloom Plus") {
              DisclosureIndicator()
            }
            .onTapGesture {
              presentedSheet = BloomPlusPaywall().asAny
            }
          }
        } else {
          SettingsCell("Subscribe to Bloom Plus") {
            DisclosureIndicator()
          }
          .onTapGesture {
            presentedSheet = BloomPlusPaywall().asAny
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
          Text(Bundle.main.appVersion ?? "Unknown")
            .onTapGesture(count: 10) {
              showDeveloperMode = true
            }
        }

        Divider()

        SettingsCell("Tell us what you think!", showDisclosureIndicator: true) {
          Image(systemSymbol: .heartFill)
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

        Divider()

        SettingsCell("Privacy Policy") {
          DisclosureIndicator()
        }
        .onTapGesture {
          openURL(.privacyPolicy)
        }

        Divider()

        SettingsCell("Terms of Service") {
          DisclosureIndicator()
        }
        .onTapGesture {
          openURL(.termsOfService)
        }
      }
    }
  }

  var authenticationSection: some View {
    VStack {
      SectionTitleView("Account")
        .padding(.horizontal)

      SettingsSectionContainer {
        SettingsCell("Email") {
          Text(userController.email ?? "--")
        }

        Divider()

        Group {
          if userController.isAuthenticated {
            AsyncButton {
              try await UserController.shared.logout()
            } label: {
              Text("Sign Out")
            }
          }
        }
        .bold()
        .frame(minHeight: 60)
      }

      if userController.isAuthenticated {
        SettingsSectionContainer {
          AsyncButton(role: .destructive) {
            try await withCheckedThrowingContinuation { continuation in
              confirmationDialogDetails = ConfirmationDialogDetails(
                title: "Are You Sure?",
                message: "This can't be undone. Your health data and existing food logs will not be deleted, and will remain on your device.",
                buttons: [
                  ConfirmationDialogDetails.Button(title: "Delete", role: .destructive) {
                    Task {
                      do {
                        try await UserController.shared.deleteAccount()
                        continuation.resume()
                      } catch {
                        continuation.resume(throwing: error)
                      }
                    }
                  },
                  ConfirmationDialogDetails.Button(title: "Cancel", role: .cancel) {
                    continuation.resume()
                  }
                ]
              )
            }
          } label: {
            Text("Delete Account")
              .bold()
              .horizontallyCentered()
              .frame(minHeight: 60)
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

  func delete(habit: Habit) {
    do {
      try habitsViewModel.delete(habit)
    } catch {
      self.error = error
    }
  }
}

#Preview {
  PreviewEnvironment {
    PreviewSheetPresent {
      SettingsView()
    }
  }
}
