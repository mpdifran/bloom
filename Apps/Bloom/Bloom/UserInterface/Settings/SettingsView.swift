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

struct SettingsView: View {

  @ObservedObject private var healthManager = HealthManager.shared
  @ObservedObject private var toDoManager = ToDoManager.shared
  @ObservedObject private var habitsViewModel = HabitsViewModel.shared
  @ObservedObject private var apiHost = APIHost.shared
  @ObservedObject private var permissionsManager = ExternalHealthMetricPermissionManager.shared

  @Bindable private var reportViewModel = ReportCoordinatorViewModel.shared
  @Bindable private var unitPreferences = HealthUnitPreferences.shared

  @AppStorage("TodayView.showWeightWidget") private var showWeightWidget: Bool = true
  @AppStorage("TodayView.showNutritionTodayWidget") private var showNutritionTodayWidget: Bool = true
  @AppStorage(.FeatureFlag.danieleMode) private var danieleMode = false
  @AppStorage(.FeatureFlag.developerMode) private var showDeveloperMode: Bool = false

  @Environment(\.openURL) private var openURL
  @Environment(\.modelContext) private var modelContext
  @Environment(ThemeController.self) private var themeController

  @ObservedObject private var userController = UserController.shared
  @State private var entitlementController = EntitlementController.shared
  @State private var shouldRequestHealthPermissions = false
  @State private var isSwipingAnItem = false
  @State private var presentedSheet: AnyView?
  @State private var confirmationDialogDetails: ConfirmationDialogDetails?
  @State private var error: Error?

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
        userDetailsSection
        healthPermissionsSection
        reportSection
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
      UserProfilePhotoView(name: healthManager.name)

      TextField("", text: $healthManager.name, prompt: Text("Your Name"))
        .font(.title)
        .bold()
        .fontDesign(.rounded)
        .multilineTextAlignment(.center)

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
              image: Image(systemSymbol: activityLevel.symbol),
              value: activityLevel.name,
              subtitle: "Activity level"
            )
            .tint(activityLevel.barColor)
          } else {
            SettingsHealthGoalCell(
              image: Image(systemSymbol: .figure),
              value: "No level set",
              subtitle: "Activity level"
            )
          }
        }
        .onTapGesture {
          presentedSheet = ActivityLevelEditCard().asAny
        }
      }

      if healthManager.sex() == .female {
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

  var userDetailsSection: some View {
    VStack {
      SectionTitleView("Personal Details")
        .padding(.horizontal)

      SettingsSectionContainer {
        SettingsCell("Birthday") {
          DatePicker(
            "",
            selection: $healthManager.birthday,
            in: ...Date(),
            displayedComponents: .date
          )
        }

        Divider()

        SettingsCell("Sex") {
          Picker("", selection: $healthManager.isFemale) {
            Text("Male")
              .tag(false)
            Text("Female")
              .tag(true)
          }
          .pickerStyle(.segmented)
          .frame(width: 150, height: 50)
        }

        Divider()

        SettingsCell("Height") {
          HeightEditorTextField()
        }
      }
    }
  }

  var healthPermissionsSection: some View {
    VStack {
      SectionTitleView("Health & Privacy")
        .padding(.horizontal)

      SettingsSectionContainer {
        if shouldRequestHealthPermissions {
          SettingsHealthAppCell(title: "Grant New Permissions")
            .onTapGesture {
              Task {
                await HealthPermissionChecker.shared.requestAccessIfNeeded()
                await checkHealthKitPermissions()
              }
            }
        }

        SettingsCell("External Health Sharing", showDisclosureIndicator: true) {
          Text("\(permissionsManager.enabledPermissions.count) enabled")
        }
          .onTapGesture {
            self.presentedSheet = ExternalHealthPrivacyView(mode: .all, onDismiss: { }).asAny
          }
      }
    }
  }

  var habitsSection: some View {
    VStack {
      SectionTitleView("\(userAddedHabits.count) Goals")
        .padding(.horizontal)

      ForEach(userAddedHabits) { habit in
        Swipeable(
          isSwipingItem: $isSwipingAnItem,
          actions: [
            SwipeAction(
              title: "Delete",
              symbol: .trash,
              tint: .mutedRed
            ) {
              delete(habit: habit)
            }
          ]
        ) {
          SettingsHabitCell(
            image: Image(systemSymbol: SFSymbol(rawValue: habit.targetMetric.systemImage)),
            title: habit.targetMetric.name,
            subtitle: habit.displayQuantity
          )
          .tint(habit.targetMetric.color)
          .onTapGesture {
            presentedSheet = EditUserAddedHabitView(habit: habit) { _ in }.asAny
          }
        }
      }
      if remainingMetrics.isNotEmpty {
        SettingsAddHabitCell()
          .onTapGesture {
            presentedSheet = NewGoalCard().asAny
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
          image: Image(systemSymbol: todo.kind.symbol),
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
        // Turning off until we figure out widgets
        //        SettingsCell("Weight Widget") {
        //          Toggle("", isOn: $showWeightWidget)
        //            .tint(.mutedGreen)
        //        }
        //
        //        Divider()

        SettingsCell("Nutrition Widget") {
          Toggle("", isOn: $showNutritionTodayWidget)
            .tint(.mutedGreen)
        }
      }

      Text("Widgets will only show if they're enabled above, and there's a corresponding Focus Area, Habit, or Health Goal.")
        .horizontalAlignment(.leading)
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal)
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

          SettingsCell("Manage Subscription") {
            DisclosureIndicator()
          }
          .onTapGesture {
            ThrowingUserTask(error: $error) {
              try await Purchases.shared.showManageSubscriptions()
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
          Text(appVersion ?? "Unknown")
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
          } else {
            Button {
              presentedSheet = LoginView { }.asAny
            } label: {
              Text("Sign In")
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
  PreviewEnvironment {
    PreviewSheetPresent {
      SettingsView()
    }
  }
}
