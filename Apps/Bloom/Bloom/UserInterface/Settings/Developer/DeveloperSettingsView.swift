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
      List {
        networkSection
        userSection
        healthPermissionsSection
        danieleSection
        adminActionsSection
        debugSection
        revenueCatSection
        designSection
        authSection
      }
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
    Section {
      Toggle("Override Host", isOn: apiHost.$overrideEnabled)
        .tint(.mutedPurple)

      if apiHost.overrideEnabled {
        LabeledContent("Host") {
          TextField("", text: apiHost.$base, prompt: Text("ex: 192.168.1.1"))
            .multilineTextAlignment(.trailing)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .selectAllTextOnBeginEditing()
        }
      }
    } header: {
      Text("Network")
    } footer: {
      Text("Current host: \(apiHost.resolvedHost.absoluteString)")
    }
  }

  var userSection: some View {
    Section("User") {
      LabeledContent("User ID") {
        Text(UserID.value)
          .lineLimit(1)
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

  @ViewBuilder
  var healthPermissionsSection: some View {
    if authStatus == .shouldRequest || shouldPromptForNotificationPermissions {
      Section("Permissions") {
        if authStatus == .shouldRequest {
          Button(action: {
            Task {
              await HealthPermissionChecker.shared.requestAccessIfNeeded()
            }
          }, label: {
            LabeledContent("HealthKit Permissions") {
              Image(systemName: "arrow.up.forward.app.fill")
            }
          })
          .buttonStyle(.plain)
        }
        if shouldPromptForNotificationPermissions {
          Button(action: {
            NotificationManager.shared.requestAuthorization()
          }, label: {
            LabeledContent("Notification Permissions") {
              Image(systemName: "arrow.up.forward.app.fill")
            }
          })
          .buttonStyle(.plain)
        }
      }
    }
  }

  var danieleSection: some View {
    Section("Daniele") {
      Toggle("Daniele Mode", isOn: $danieleMode)
        .tint(.mutedPurple)

      Button {
        Task {
          do {
            let chatHealthData = await ChatVitalConverter.shared.convertHealthData()

            let jsonData = try JSONEncoder().encode(chatHealthData)
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
        }
      } label: {
        HStack {
          Text("Copy Health Data to Clipboard")
          Spacer()
          DisclosureIndicator()
        }
      }
      .buttonStyle(.plain)
    }
  }

  var debugSection: some View {
    Section("Debug") {
      Button {
        presentedSheet = DebugHabitsListView().asAny
      } label: {
        HStack {
          Text("Debug Habits")
          Spacer()
          DisclosureIndicator()
        }
      }
      .buttonStyle(.plain)

      Button {
        presentedSheet = DebugFoodItemLogListView().asAny
      } label: {
        HStack {
          Text("Debug Food Item Logs")
          Spacer()
          DisclosureIndicator()
        }
      }
      .buttonStyle(.plain)
    }
  }

  var adminActionsSection: some View {
    Section("Admin Actions") {
      Button {
        hasShownOnboarding = false
      } label: {
        LabeledContent("Reset Onboarding") {
          Image(systemName: "arrow.uturn.backward.square.fill")
        }
      }
      .buttonStyle(.plain)

      Button {
        HabitsViewModel.shared.resetHabitCheckDate()
        alertDetails = AlertDetails(title: "Focus Area Review", message: "You will now be prompted to review your focus areas.")
      } label: {
        HStack {
          Text("Prompt Focus Area Review")
          Spacer()
          DisclosureIndicator()
        }
      }
      .buttonStyle(.plain)

      Button {
        Task {
          await VitalsCalculator.shared.forceFetchVitals()
          await MainActor.run {
            alertDetails = AlertDetails(title: "Vitals Recalculated", message: "Your Vitals have been recalculated.")
          }
        }
      } label: {
        HStack {
          Text("Recalculate Vitals")
          Spacer()
          DisclosureIndicator()
        }
      }
      .buttonStyle(.plain)

      Button {
        Task {
          do {
            try await NutritionTrackingViewModel.shared.reSyncNutritionToHealthKit()
            await MainActor.run {
              alertDetails = AlertDetails(title: "Nutrition Synced to HealthKit", message: "Your nutrition data has been re-synced to HealthKit.")
            }
          } catch {
            self.error = error
          }
        }
      } label: {
        HStack {
          Text("Re-Sync Nutrition to HealthKit")
          Spacer()
          DisclosureIndicator()
        }
      }
      .buttonStyle(.plain)

      Button {
        presentedSheet = BloomPlusPaywall().asAny
      } label: {
        HStack {
          Text("Show Paywall")
          Spacer()
          DisclosureIndicator()
        }
        .selectable()
      }
    }
  }

  @ViewBuilder
  var revenueCatSection: some View {
    #if DEBUG
    Section("RevenueCat") {
      Button {
        showRCDebugOverlay.toggle()
      } label: {
        HStack {
          Text("Debug View")
          Spacer()
          DisclosureIndicator()
        }
      }
      .buttonStyle(.plain)
      .debugRevenueCatOverlay(isPresented: $showRCDebugOverlay)
    }
    #endif
  }

  var designSection: some View {
    Section("Design") {
      Button {
        presentedSheet = ColorPaletteView().asAny
      } label: {
        LabeledContent("Color Palette") {
          Image(systemName: "paintpalette")
        }
      }
      .buttonStyle(.plain)
    }
  }

  var authSection: some View {
    Section("Auth") {
      LabeledContent("User ID") {
        Text(viewModel.userID?.value ?? "None")
      }
      LabeledContent("Auth Token") {
        Text(viewModel.authToken?.value ?? "None")
      }

      if viewModel.isAuthenticated {
        AsyncButton(role: .destructive) {
          try await UserController.shared.logout()
        } label: {
          Text("Log Out")
        }
      } else {
        Button("Show Log In") {
          presentedSheet = LoginView { }.asAny
        }
      }
    }
  }
}

#Preview {
  DeveloperSettingsView()
}
