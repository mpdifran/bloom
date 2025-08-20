//
//  DeveloperSettingsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-26.
//

import SFSafeSymbols
import SwiftUI
import AppUI
import HealthKit
import DataContainer
import CoreHealth

struct DeveloperSettingsView: View {

  @AppStorage("hasShownOnboardingV3") var hasShownOnboarding: Bool = false
  @AppStorage(.FeatureFlag.developerMode) private var showDeveloperMode: Bool = false
  @AppStorage(.FeatureFlag.enableOpenAIModelOverride) private var enableOpenAIModelOverride = false
  @AppStorage(.FeatureFlag.bypassPaywall) private var bypassPaywall = false
  @AppStorage(.FeatureFlag.useSwiftUIChatView) private var useSwiftUIChatView = false

  @State private var authStatus: HKAuthorizationRequestStatus = .unknown
  @State private var shouldPromptForNotificationPermissions = false
  @State private var showRCDebugOverlay = false
  @State private var presentedFullScreenView: AnyView?
  @State private var presentedSheet: AnyView?
  @State private var alertDetails: AlertDetails?
  @State private var error: Error?

  @ObservedObject private var apiHost = APIHost.shared

  @Environment(\.dismiss) private var dismiss

  @ObservedObject private var userController = UserController.shared

  private let vitalsViewModel = VitalsViewModel.shared
  private let modelContext = ContainerHolder.shared.createContext()

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 20) {
          networkSection
          userSection
          healthPermissionsSection
          featureFlagSection
          experimentsSection
          adminActionsSection
          debugSection
          notificationsSection
          storageSection
          designSection
          authSection
          developerModeSection
        }
        .padding()
      }
      .groupedBackground()
      .navigationTitle("Developer Tools")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Done") {
            dismiss()
          }
          .bold()
        }
      }
    }
    .presentationCornerRadius(30)
    .presentationDragIndicator(.visible)
    .fullScreenCover($presentedFullScreenView)
    .sheet($presentedSheet)
    .animation(.default, value: apiHost.overrideEnabled)
    .onAppear {
      Task {
        shouldPromptForNotificationPermissions = await NotificationManager.shared.shouldRequestAuthorization()
        await checkHealthAuthStatus()
      }
    }
    .task {
      shouldPromptForNotificationPermissions = await NotificationManager.shared.shouldRequestAuthorization()
    }
    .task {
      await checkHealthAuthStatus()
    }
    .alert(alertDetails: $alertDetails)
    .alert(error: $error)
  }
}

extension DeveloperSettingsView {

  func checkHealthAuthStatus() async {
    self.authStatus = (try? await HealthPermissionChecker.shared.checkAccessForAllTypes()) ?? .unknown
  }

  var networkSection: some View {
    VStack(alignment: .leading) {
      SectionTitleView("Network")
        .padding(.horizontal)

      SettingsSectionContainer {
        SettingsCell("Override Host") {
          Toggle("", isOn: apiHost.$overrideEnabled)
        }

        if apiHost.overrideEnabled {
          Divider()

          SettingsCell("Host") {
            TextField("", text: apiHost.$base, prompt: Text("ex: 192.168.1.1"))
              .multilineTextAlignment(.trailing)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
              .submitLabel(.done)
              .selectAllTextOnBeginEditing()
          }

          Divider()

          SettingsCell("WS Host") {
            TextField("", text: apiHost.$wsBase, prompt: Text("ex: 192.168.1.1"))
              .multilineTextAlignment(.trailing)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
              .submitLabel(.done)
              .selectAllTextOnBeginEditing()
          }
        }
      }

      Text("Current host: \(apiHost.resolvedHost.absoluteString)\nCurrent WS Host: \(apiHost.resolvedWebSocketHost.absoluteString)")
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal)
    }
  }

  var userSection: some View {
    VStack(alignment: .leading) {
      SectionTitleView("User")
        .padding(.horizontal)

      SettingsSectionContainer {
        SettingsCell("User ID") {
          Text(UserID.value)
            .lineLimit(2)
            .multilineTextAlignment(.trailing)
            .minimumScaleFactor(0.1)
        }
        .selectable()
        .onTapGesture {
          UIPasteboard.general.string = UserID.value
          alertDetails = AlertDetails(
            title: "Copied to Clipboard",
            message: "The User ID has been copied to your clipboard."
          )
        }
      }
    }
  }

  @ViewBuilder
  var healthPermissionsSection: some View {
    if authStatus == .shouldRequest || shouldPromptForNotificationPermissions {
      VStack {
        SectionTitleView("Permissions")
          .padding(.horizontal)

        SettingsSectionContainer {
          if authStatus == .shouldRequest {
            AsyncButton {
              await HealthPermissionChecker.shared.requestAccessIfNeeded()
            } label: {
              LabeledContent("HealthKit Permissions") {
                Image(systemSymbol: .arrowUpForwardAppFill)
              }
              .bold()
              .fontDesign(.rounded)
              .foregroundStyle(.tint)
              .selectable()
            }
            .frame(height: 60)
          }

          if authStatus == .shouldRequest && shouldPromptForNotificationPermissions {
            Divider()
          }

          if shouldPromptForNotificationPermissions {
            Button {
              NotificationManager.shared.requestAuthorization()
            } label: {
              LabeledContent("Notification Permissions") {
                Image(systemSymbol: .arrowUpForwardAppFill)
              }
              .bold()
              .fontDesign(.rounded)
              .foregroundStyle(.tint)
              .selectable()
            }
            .frame(height: 60)
          }
        }
      }
    }
  }

  var featureFlagSection: some View {
    VStack {
      SectionTitleView("Feature Flags")
        .padding(.horizontal)

      SettingsSectionContainer {
        SettingsCell("Bypass Paywall") {
          Toggle("", isOn: $bypassPaywall)
        }

        Divider()

        SettingsCell("OpenAI Model o3") {
          Toggle("", isOn: $enableOpenAIModelOverride)
        }

        Divider()

        SettingsCell("Use SwiftUI Chat View") {
          Toggle("", isOn: $useSwiftUIChatView)
        }
      }
    }
  }

  var debugSection: some View {
    VStack {
      SectionTitleView("SwiftData")
        .padding(.horizontal)

      SettingsSectionContainer {
        SettingsCell("View Goals", showDisclosureIndicator: true) { }
          .onTapGesture {
            presentedSheet = DebugHabitsListView().asAny
          }

        Divider()

        SettingsCell("View Food Item Logs", showDisclosureIndicator: true) { }
          .onTapGesture {
            presentedSheet = DebugFoodItemLogListView().asAny
          }
      }
    }
  }
  
  var notificationsSection: some View {
    VStack {
      SectionTitleView("Notifications")
        .padding(.horizontal)

      SettingsSectionContainer {
        SettingsCell("View Scheduled Notifications", showDisclosureIndicator: true) { }
          .onTapGesture {
            presentedSheet = ScheduledNotificationsView().asAny
          }
      }
    }
  }

  var adminActionsSection: some View {
    VStack {
      SectionTitleView("Admin Actions")
        .padding(.horizontal)

      SettingsSectionContainer {
        AsyncButton {
          do {
            let date = Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
            let dayReviewData = try await DayReviewCalculator.shared.calculateDayReviewHealthDataString(for: date)
            UIPasteboard.general.string = dayReviewData

            await MainActor.run {
              alertDetails = AlertDetails(
                title: "Copied to Clipboard",
                message: "Your day review data has been copied to your clipboard."
              )
            }
          } catch {
            await MainActor.run {
              self.error = error
            }
          }
        } label: {
          LabeledContent("Copy Morning Report Data to Clipboard") {
            Image(systemSymbol: .sunrise)
          }
          .multilineTextAlignment(.leading)
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.tint)
          .selectable()
        }
        .frame(height: 60)

        Divider()

        AsyncButton {
          await ReportCoordinator.shared.clearLastNotificationDate()
          try await ReportCoordinator.shared.deleteTodaysReport()
          await ReportCoordinator.shared.didDetectWakeUp()
        } label: {
          LabeledContent("Generate Morning Report") {
            Image(systemSymbol: .sunriseCircle)
          }
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.tint)
          .selectable()
          .frame(height: 60)
        }

        Divider()

        AsyncButton {
          try await NetworkRequester.shared.deleteChatThread()
          try modelContext.deleteAll(ChatMessage.self)
          try modelContext.save()

          alertDetails = AlertDetails(
            title: "Chat History Deleted",
            message: "Your chat history has been deleted."
          )
        } label: {
          LabeledContent("Delete Chat History") {
            Image(systemSymbol: .trash)
          }
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.tint)
          .selectable()
          .frame(height: 60)
        }

        Divider()

        Button {
          hasShownOnboarding = false
        } label: {
          LabeledContent("Reset Onboarding") {
            Image(systemSymbol: .arrowUturnBackwardSquareFill)
          }
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.tint)
          .selectable()
          .frame(height: 60)
        }

        Divider()

        AsyncButton {
          await VitalsCalculator.shared.forceFetchVitals()
          await MainActor.run {
            alertDetails = AlertDetails(title: "Vitals Recalculated", message: "Your Vitals have been recalculated.")
          }
        } label: {
          LabeledContent("Recalculate Vitals") {
            Image(systemSymbol: .arrowTriangleheadClockwiseHeartFill)
          }
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.tint)
          .selectable()
          .frame(height: 60)
        }

        Divider()

        Button {
          ImageResizeMigration.shared.resetMigration()
          alertDetails = AlertDetails(
            title: "Migration Reset",
            message: "Image resize migration flag has been reset. Migration will run on next app foreground."
          )
        } label: {
          LabeledContent("Reset Image Migration") {
            Image(systemSymbol: .arrowClockwise)
          }
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.tint)
          .selectable()
          .frame(height: 60)
        }

        Divider()

        AsyncButton {
          await ImageResizeMigration.shared.forceMigration()
          alertDetails = AlertDetails(
            title: "Migration Complete",
            message: "Image resize migration has been forced to run. Check console for logs."
          )
        } label: {
          LabeledContent("Force Image Migration") {
            Image(systemSymbol: .photoStack)
          }
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.tint)
          .selectable()
          .frame(height: 60)
        }

        Divider()

        AsyncButton {
          do {
            try await NutritionTrackingViewModel.shared.reSyncNutritionToHealthKit()
            await MainActor.run {
              alertDetails = AlertDetails(title: "Nutrition Synced to HealthKit", message: "Your nutrition data has been re-synced to HealthKit.")
            }
          } catch {
            self.error = error
          }
        } label: {
          LabeledContent("Sync Nutrition to HealthKit") {
            Image(systemSymbol: .carrot)
          }
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.tint)
          .selectable()
          .frame(height: 60)
        }

        Divider()

        Button {
          presentedSheet = BloomPlusPaywall().asAny
        } label: {
          LabeledContent("Show Paywall") {
            Image(systemSymbol: .dollarsignSquareFill)
          }
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.tint)
          .selectable()
          .frame(height: 60)
        }

        #if DEBUG
        Divider()

        Button {
          showRCDebugOverlay.toggle()
        } label: {
          LabeledContent("Debug RevenueCat") {
            Image(systemSymbol: .catFill)
          }
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.tint)
          .selectable()
          .frame(height: 60)
        }
        .debugRevenueCatOverlay(isPresented: $showRCDebugOverlay)
        #endif
      }
    }
  }

  var storageSection: some View {
    VStack {
      SectionTitleView("Storage")
        .padding(.horizontal)

      SettingsSectionContainer {
        SettingsCell("Storage Analysis", showDisclosureIndicator: true) { }
          .onTapGesture {
            presentedSheet = StorageAnalysisView().asAny
          }
      }
    }
  }

  var designSection: some View {
    VStack {
      SectionTitleView("Design")
        .padding(.horizontal)

      SettingsSectionContainer {
        SettingsCell("Color Palette", showDisclosureIndicator: true) { }
          .onTapGesture {
            presentedSheet = ColorPaletteView().asAny
          }

        Divider()

        SettingsCell("Sounds", showDisclosureIndicator: true) { }
          .onTapGesture {
            presentedSheet = SoundDebugView().asAny
          }
      }
    }
  }

  var authSection: some View {
    VStack {
      SectionTitleView("Auth")
        .padding(.horizontal)

      SettingsSectionContainer {
        SettingsCell("User ID") {
          Text(userController.authenticatedUserIdentifier?.value ?? "None")
        }

        Divider()

        SettingsCell("Auth Token") {
          Text(userController.authToken?.value ?? "None")
        }

        Divider()

        if userController.isAuthenticated {
          AsyncButton(role: .destructive) {
            try await UserController.shared.logout()
          } label: {
            Text("Log Out")
              .frame(height: 60)
          }
        } else {
          Button("Show Log In") {
            presentedSheet = OnboardingLoginView { }.asAny
          }
          .frame(height: 60)
        }
      }
    }
  }

  var experimentsSection: some View {
    VStack {
      SectionTitleView("Experiments")
        .padding(.horizontal)
      
      SettingsSectionContainer {
        ExperimentOverrideView(
          experimentId: .ExperimentID.onboardingHealthKitView,
          experimentName: "Onboarding HealthKit View"
        )
      }
    }
  }

  var developerModeSection: some View {
    VStack {
      SettingsSectionContainer {
        Button(role: .destructive) {
          apiHost.overrideEnabled = false
          showDeveloperMode = false
          bypassPaywall = false
          enableOpenAIModelOverride = false
          useSwiftUIChatView = false
          clearAllExperimentOverrides()
          dismiss()
        } label: {
          Text("Exit Developer Mode")
            .bold()
            .fontDesign(.rounded)
            .horizontallyCentered()
            .frame(minHeight: 60)
            .selectable()
        }
      }
    }
  }
  
  private func clearAllExperimentOverrides() {
    // Clear all experiment overrides
    let overrideKey = String.ExperimentOverrideKey.key(for: .ExperimentID.onboardingHealthKitView)
    UserDefaults.standard.removeObject(forKey: overrideKey)
  }
}

#Preview {
  PreviewEnvironment {
    DeveloperSettingsView()
  }
}
