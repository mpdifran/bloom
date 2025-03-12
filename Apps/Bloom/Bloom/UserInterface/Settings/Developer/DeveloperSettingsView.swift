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

struct DeveloperSettingsView: View {

  @AppStorage(.FeatureFlag.danieleMode) private var danieleMode = false
  @AppStorage("hasShownOnboardingV3") var hasShownOnboarding: Bool = false
  @AppStorage(.FeatureFlag.developerMode) private var showDeveloperMode: Bool = false
  @AppStorage(.FeatureFlag.legacyGoalSetting) private var legacyGoalSetting = false
  @AppStorage(.FeatureFlag.alwaysAskForAIGoalSettingPermission) private var alwaysAskForAIGoalSettingPermission = false

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

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 20) {
          networkSection
          userSection
          healthPermissionsSection
          featureFlagSection
          adminActionsSection
          debugSection
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
    .tint(.mutedPurple)
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
        }
      }

      Text("Current host: \(apiHost.resolvedHost.absoluteString)")
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
        SettingsCell("AI Goal Review") {
          Toggle("", isOn: $legacyGoalSetting)
        }

        Divider()

        SettingsCell("Always Ask Permission") {
          Toggle("", isOn: $alwaysAskForAIGoalSettingPermission)
        }

        Divider()

        SettingsCell("Daniele Mode") {
          Toggle("", isOn: $danieleMode)
        }

        Divider()
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

  var adminActionsSection: some View {
    VStack {
      SectionTitleView("Admin Actions")
        .padding(.horizontal)

      SettingsSectionContainer {
        AsyncButton {
          do {
            let chatHealthData = try await ChatVitalConverter.shared.convertHealthDataString()
            UIPasteboard.general.string = chatHealthData

            await MainActor.run {
              alertDetails = AlertDetails(
                title: "Copied to Clipboard",
                message: "Your health data has been copied to your clipboard."
              )
            }
          } catch {
            await MainActor.run {
              self.error = error
            }
          }
        } label: {
          LabeledContent("Copy Health Data to Clipboard") {
            if #available(iOS 18.0, *) {
              Image(systemSymbol: .documentOnDocument)
            }
          }
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.tint)
          .selectable()
        }
        .frame(height: 60)

        Divider()

        AsyncButton {
          do {
            let goalsData = try await ChatGoalConverter.shared.convertGoalDataString()
            UIPasteboard.general.string = goalsData

            await MainActor.run {
              alertDetails = AlertDetails(
                title: "Copied to Clipboard",
                message: "Your current goals have been copied to your clipboard."
              )
            }
          } catch {
            await MainActor.run {
              self.error = error
            }
          }
        } label: {
          LabeledContent("Copy Goals to Clipboard") {
            if #available(iOS 18.0, *) {
              Image(systemSymbol: .documentOnDocument)
            } else {
              // Fallback on earlier versions
            }
          }
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.tint)
          .selectable()
        }
        .frame(height: 60)

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

        Button {
          HabitsViewModel.shared.resetHabitCheckDate()
          alertDetails = AlertDetails(
            title: "Goal Review",
            message: "You will now be prompted to review your goals on the Today tab."
          )
        } label: {
          LabeledContent("Prompt Goal Review") {
            Image(systemSymbol: .repeat)
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
            Image(systemSymbol: .arrowClockwiseHeartFill)
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

  var designSection: some View {
    VStack {
      SectionTitleView("Design")
        .padding(.horizontal)

      SettingsSectionContainer {
        Button {
          presentedSheet = ColorPaletteView().asAny
        } label: {
          LabeledContent("Color Palette") {
            Image(systemSymbol: .paintpalette)
          }
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.tint)
          .selectable()
          .frame(height: 60)
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
            presentedSheet = LoginView { }.asAny
          }
          .frame(height: 60)
        }
      }
    }
  }

  var developerModeSection: some View {
    VStack {
      SettingsSectionContainer {
        Button(role: .destructive) {
          apiHost.overrideEnabled = false
          showDeveloperMode = false
          danieleMode = false
          legacyGoalSetting = false
          alwaysAskForAIGoalSettingPermission = false
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
}

#Preview {
  DeveloperSettingsView()
}
