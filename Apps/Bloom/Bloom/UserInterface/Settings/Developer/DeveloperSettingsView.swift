//
//  DeveloperSettingsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-26.
//

import SwiftUI
import AppUI
import HealthKit

struct DeveloperSettingsView: View {

  @AppStorage("PreferencesView.danieleMode") private var danieleMode = false
  @AppStorage("hasShownOnboardingV3") var hasShownOnboarding: Bool = false
  @AppStorage("SettingsView.showDeveloperMode") private var showDeveloperMode: Bool = false

  @State private var authStatus: HKAuthorizationRequestStatus = .unknown
  @State private var shouldPromptForNotificationPermissions = false
  @State private var showRCDebugOverlay = false
  @State private var presentedFullScreenView: AnyView?
  @State private var presentedSheet: AnyView?
  @State private var alertDetails: AlertDetails?
  @State private var error: Error?

  @ObservedObject private var apiHost = APIHost.shared

  @Environment(\.dismiss) private var dismiss

  @State private var viewModel = UserControllerViewModel()

  private let vitalsViewModel = VitalsViewModel.shared

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 20) {
          networkSection
          userSection
          healthPermissionsSection
          danieleSection
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
                Image(systemName: "arrow.up.forward.app.fill")
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
                Image(systemName: "arrow.up.forward.app.fill")
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

  var danieleSection: some View {
    VStack {
      SectionTitleView("Feature Flags")
        .padding(.horizontal)

      SettingsSectionContainer {
        SettingsCell("Daniele Mode") {
          Toggle("", isOn: $danieleMode)
            .tint(.mutedPurple)
        }

        Divider()

        AsyncButton {
          do {
            let chatHealthData = await ChatVitalConverter.shared.convertHealthData()

            let jsonData = try JSONEncoder.bloomModel.encode(chatHealthData)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
            UIPasteboard.general.string = jsonString

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
            Image(systemName: "document.on.document")
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
            let goalsData = await ChatGoalConverter.shared.convertGoalData()

            let jsonData = try JSONEncoder.bloomModel.encode(goalsData)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
            UIPasteboard.general.string = jsonString

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
            Image(systemName: "document.on.document")
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

  var debugSection: some View {
    VStack {
      SectionTitleView("SwiftData")
        .padding(.horizontal)

      SettingsSectionContainer {
        SettingsCell("View Habits", showDisclosureIndicator: true) { }
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
        Button {
          hasShownOnboarding = false
        } label: {
          LabeledContent("Reset Onboarding") {
            Image(systemName: "arrow.uturn.backward.square.fill")
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
            Image(systemName: "repeat")
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
            Image(systemName: "arrow.clockwise.heart.fill")
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
            Image(systemName: "carrot")
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
            Image(systemName: "dollarsign.square.fill")
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
            Image(systemName: "cat.fill")
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
            Image(systemName: "paintpalette")
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
          Text(viewModel.userID?.value ?? "None")
        }

        Divider()

        SettingsCell("Auth Token") {
          Text(viewModel.authToken?.value ?? "None")
        }

        Divider()

        if viewModel.isAuthenticated {
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
