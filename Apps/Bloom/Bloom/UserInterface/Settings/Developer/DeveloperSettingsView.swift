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
import CoreNetwork
import BloomModel
import BloomUI

struct DeveloperSettingsView: View {

  @AppStorage("hasShownOnboardingV3") var hasShownOnboarding: Bool = false
  @AppStorage(.FeatureFlag.developerMode) private var showDeveloperMode: Bool = false
  @AppStorage(.FeatureFlag.enableOpenAIModelOverride) private var enableOpenAIModelOverride = false
  @AppStorage(.FeatureFlag.bypassPaywall) private var bypassPaywall = false
  @AppStorage(.FeatureFlag.mockMagicScanner) private var mockMagicScanner = false
  @AppStorage(.FeatureFlag.mockBioAgeEnabled) private var mockBioAgeEnabled = false
  @AppStorage(.FeatureFlag.mockBioAgeDelta) private var mockBioAgeDelta = 0.0
  @AppStorage(.FeatureFlag.reEngagementTestMode) private var reEngagementTestMode = false
  @AppStorage("OnboardingRootViewTreatment.currentStep") private var onboardingCurrentStep = 0
  @AppStorage("OnboardingRootViewTreatment.wasYesInWarmingStep") private var onboardingWasYesInWarmingStep = false
  @AppStorage("OnboardingRootViewTreatment.personalizationFocus") private var onboardingPersonalizationFocus: String?

  @State private var authStatus: HKAuthorizationRequestStatus = .unknown
  @State private var shouldPromptForNotificationPermissions = false
  @State private var showRCDebugOverlay = false
  @State private var todayInsightsManager = TodayInsightsManager.shared
  @State private var presentedFullScreenView: AnyView?
  @State private var presentedSheet: AnyView?
  @State private var alertDetails: AlertDetails?
  @State private var error: Error?

  @ObservedObject private var apiHost = APIHost.shared
  @ObservedObject private var logManager = LogManager.shared

  @Environment(\.dismiss) private var dismiss

  @ObservedObject private var authTokenManager = AuthTokenManager.shared

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
          aiInsightsSection
          healthActionsSection
          paywallSection
          salesSection
          migrationSection
          debugSection
          logsSection
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
          DismissButton()
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

        SettingsCell("Mock Magic Scanner") {
          Toggle("", isOn: $mockMagicScanner)
        }

        Divider()

        SettingsCell("Mock Bio Age") {
          Toggle("", isOn: $mockBioAgeEnabled)
        }

        if mockBioAgeEnabled {
          Divider()

          VStack(alignment: .leading, spacing: 8) {
            SettingsCell("Bio Age Delta") {
              Text(mockBioAgeDelta >= 0 ? "+\(String(format: "%.1f", mockBioAgeDelta))" : String(format: "%.1f", mockBioAgeDelta))
                .foregroundStyle(.secondary)
            }

            Slider(
              value: $mockBioAgeDelta,
              in: -12...12,
              step: 0.5
            )
            .padding(.horizontal)

            HStack {
              Text("-12 (younger)")
                .font(.caption)
                .foregroundStyle(.secondary)
              Spacer()
              Text("+12 (older)")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
          }
        }
      }
    }
  }

  var debugSection: some View {
    VStack {
      SectionTitleView("SwiftData")
        .padding(.horizontal)

      SettingsSectionContainer {
        SettingsCell("View Goals", iconType: .disclosure) { }
          .onTapGesture {
            presentedSheet = DebugHabitsListView().asAny
          }

        Divider()

        SettingsCell("View Food Item Logs", iconType: .disclosure) { }
          .onTapGesture {
            presentedSheet = DebugFoodItemLogListView().asAny
          }

        Divider()

        SettingsCell("View Biological Age Records", iconType: .disclosure) { }
          .onTapGesture {
            presentedSheet = DebugBiologicalAgeRecordsView().asAny
          }
      }
    }
  }

  var logsSection: some View {
    VStack {
      SectionTitleView("Logs")
        .padding(.horizontal)

      SettingsSectionContainer {
        SettingsCell("View Logs (\(logManager.logs.count))", iconType: .disclosure) { }
          .onTapGesture {
            presentedSheet = LogsListView().asAny
          }

        Divider()

        AsyncButton(role: .destructive) {
          logManager.clearLogs()
          alertDetails = AlertDetails(
            title: "Logs Cleared",
            message: "All debug logs have been cleared."
          )
        } label: {
          Text("Clear All Logs")
            .bold()
            .horizontallyCentered()
            .frame(height: 60)
        }
      }
    }
  }

  var notificationsSection: some View {
    VStack {
      SectionTitleView("Notifications")
        .padding(.horizontal)

      SettingsSectionContainer {
        SettingsCell("View Scheduled Notifications", iconType: .disclosure) { }
          .onTapGesture {
            presentedSheet = ScheduledNotificationsView().asAny
          }

        Divider()

        Menu {
          Button("4 Days Before") {
            Task {
              await PeriodPredictionScheduler.shared.sendTestNotification(type: .near)
            }
          }

          Button("1 Day Before") {
            Task {
              await PeriodPredictionScheduler.shared.sendTestNotification(type: .imminent)
            }
          }

          Button("4 Days After") {
            Task {
              await PeriodPredictionScheduler.shared.sendTestNotification(type: .late)
            }
          }
        } label: {
          SettingsCell("Test Period Notifications") {
            Image(systemSymbol: .bellBadgeFill)
          }
        }

        Divider()

        Menu {
          ForEach(MonitorType.allCases, id: \.self) { monitorType in
            Menu(monitorType.displayName) {
              Button("Attention") {
                Task {
                  await MonitorNotificationScheduler.shared.sendTestNotification(
                    for: monitorType,
                    state: .attention
                  )
                }
              }

              Button("Alert") {
                Task {
                  await MonitorNotificationScheduler.shared.sendTestNotification(
                    for: monitorType,
                    state: .alert
                  )
                }
              }
            }
          }
        } label: {
          SettingsCell("Test Monitor Notifications") {
            Image(systemSymbol: .heartTextSquare)
          }
        }

        Divider()

        AsyncButton {
          do {
            try await NetworkRequester.shared.testPushNotification()

            await MainActor.run {
              alertDetails = AlertDetails(
                title: "Test Sent",
                message: "Test push notification has been sent. You should receive it shortly."
              )
            }
          } catch {
            await MainActor.run {
              self.error = error
            }
          }
        } label: {
          LabeledContent("Test Push Notifications") {
            Image(systemSymbol: .bellAndWavesLeftAndRight)
          }
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.tint)
          .selectable()
          .frame(height: 60)
        }

        Divider()

        SettingsCell(
          "Re-engagement Test Mode",
          subtitle: "Use minutes instead of days"
        ) {
          Toggle("", isOn: $reEngagementTestMode)
        }
      }
    }
  }

  var aiInsightsSection: some View {
    VStack {
      SectionTitleView("AI Insight Actions")
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
          LabeledContent("Copy Today Insight Data to Clipboard") {
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
          do {
            let contexts = try await generateMonitorInsightContexts()
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(contexts)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
            UIPasteboard.general.string = jsonString

            await MainActor.run {
              alertDetails = AlertDetails(
                title: "Copied to Clipboard",
                message: "Monitor insight contexts have been copied to your clipboard."
              )
            }
          } catch {
            await MainActor.run {
              self.error = error
            }
          }
        } label: {
          LabeledContent("Copy Monitor Insight Context to Clipboard") {
            Image(systemSymbol: .waveformPathEcg)
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
          TodayInsightsManager.shared.clearStoredContent()
          await TodayInsightsManager.shared.forceRefreshContent()

          await MainActor.run {
            alertDetails = AlertDetails(
              title: "Today Insights Regenerated",
              message: "Your today insights have been regenerated with yesterday's personal data."
            )
          }
        } label: {
          LabeledContent("Regenerate Today Insights") {
            Image(systemSymbol: .arrowClockwise)
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
          await BiologicalAgeViewModel.shared.forceCalculateBiologicalAge()

          // Get the calculated result and show it in the alert
          let calculatedAge = BiologicalAgeViewModel.shared.currentBiologicalAge
          let message: String

          if let age = calculatedAge {
            message = "Biological age calculated: \(String(format: "%.1f", age)) years"
          } else {
            message = "Biological age calculation completed. No result available - check that you have enough personal data logged."
          }

          alertDetails = AlertDetails(
            title: "Biological Age Calculated",
            message: message
          )
        } label: {
          LabeledContent("Calculate Biological Age") {
            Image(systemSymbol: .brainHeadProfile)
          }
          .multilineTextAlignment(.leading)
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.tint)
          .selectable()
          .frame(height: 60)
        }
      }
    }
  }

  var paywallSection: some View {
    VStack {
      SectionTitleView("Paywall")
        .padding(.horizontal)

      SettingsSectionContainer {
        Button {
          hasShownOnboarding = false
          onboardingCurrentStep = 0
          onboardingWasYesInWarmingStep = false
          onboardingPersonalizationFocus = nil
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

  var salesSection: some View {
    SalesDebugView()
  }

  var migrationSection: some View {
    VStack {
      SectionTitleView("Migrations")
        .padding(.horizontal)

      SettingsSectionContainer {
        AsyncButton {
          let conversationActor = ConversationModelActor(modelContainer: ContainerHolder.shared.container)
          try await conversationActor.fixUnassignedMessages()

          alertDetails = AlertDetails(
            title: "Messages Fixed",
            message: "All unassigned chat messages have been assigned to the legacy conversation."
          )
        } label: {
          LabeledContent("Fix Unassigned Chat Messages") {
            Image(systemSymbol: .arrowshapeTurnUpForwardCircle)
          }
          .multilineTextAlignment(.leading)
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

        Button {
          PngToJpegMigration.shared.resetMigration()
          alertDetails = AlertDetails(
            title: "Migration Reset",
            message: "PNG to JPEG migration flag has been reset. Migration will run on next app foreground."
          )
        } label: {
          LabeledContent("Reset PNG to JPEG Migration") {
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
          await PngToJpegMigration.shared.forceMigration()
          alertDetails = AlertDetails(
            title: "Migration Complete",
            message: "PNG to JPEG migration has been forced to run. Check console for logs."
          )
        } label: {
          LabeledContent("Force PNG to JPEG Migration") {
            Image(systemSymbol: .photoBadgeArrowDown)
          }
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.tint)
          .selectable()
          .frame(height: 60)
        }

        Divider()

        Button {
          ChatConversationMigration.shared.resetMigration()
          alertDetails = AlertDetails(
            title: "Migration Reset",
            message: "Chat conversation migration flag has been reset. Migration will run on next app foreground."
          )
        } label: {
          LabeledContent("Reset Chat Migration") {
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
          await ChatConversationMigration.shared.forceMigration()
          alertDetails = AlertDetails(
            title: "Migration Complete",
            message: "Chat conversation migration has been forced to run. Check console for logs."
          )
        } label: {
          LabeledContent("Force Chat Migration") {
            Image(systemSymbol: .bubbleLeftAndBubbleRight)
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

  var healthActionsSection: some View {
    VStack {
      SectionTitleView("Health Actions")
        .padding(.horizontal)

      SettingsSectionContainer {
        AsyncButton {
          await YouStatsCalculator.shared.refreshStats()
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

        AsyncButton {
          do {
            let results = try await MonitorCalculator.shared.calculateMetricsAndDetect()

            let summary = results.map { result in
              "\(result.monitorType.displayName): \(result.state.displayName) (\(result.findings.count) findings, \(Int(result.confidence * 100))% confidence)"
            }.joined(separator: "\n")

            await MainActor.run {
              alertDetails = AlertDetails(
                title: "Monitor Detection Results",
                message: summary.isEmpty ? "No results available" : summary
              )
            }
          } catch {
            await MainActor.run {
              self.error = error
            }
          }
        } label: {
          LabeledContent("Test Monitor Detection") {
            Image(systemSymbol: .heartTextSquare)
          }
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.tint)
          .selectable()
          .frame(height: 60)
        }

        Divider()

        SettingsCell("Monitor Historical Analysis", iconType: .disclosure) { }
          .onTapGesture {
            presentedSheet = NavigationStack { MonitorHistoricalAnalysisView() }.asAny
          }
      }
    }
  }

  var storageSection: some View {
    VStack {
      SectionTitleView("Storage")
        .padding(.horizontal)

      SettingsSectionContainer {
        SettingsCell("Storage Analysis", iconType: .disclosure) { }
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
        Menu {
          Button("No Override") {
            todayInsightsManager.budStateOverride = nil
          }

          Divider()

          ForEach(TodayReportResponse.BudState.allCases, id: \.self) { state in
            Button(budStateLabel(for: state)) {
              todayInsightsManager.budStateOverride = state.rawValue
            }
          }
        } label: {
          SettingsCell("Bud State Override") {
            Text(currentBudStateLabel)
              .foregroundStyle(.secondary)
          }
        }

        Divider()

        SettingsCell("Color Palette", iconType: .disclosure) { }
          .onTapGesture {
            presentedSheet = ColorPaletteView().asAny
          }

        Divider()

        SettingsCell("Sounds", iconType: .disclosure) { }
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
          Text(authTokenManager.authenticatedUserIdentifier?.value ?? "None")
        }

        Divider()

        SettingsCell("Auth Token") {
          Text(authTokenManager.authToken?.value ?? "None")
        }

        Divider()

        if authTokenManager.isAuthenticated {
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
        ForEach(Experiment.allCases) { experiment in
          ExperimentOverrideView(
            experimentId: experiment.id.value,
            experimentName: experiment.name
          )
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
          bypassPaywall = false
          enableOpenAIModelOverride = false
          mockMagicScanner = false
          mockBioAgeEnabled = false
          mockBioAgeDelta = 0.0
          todayInsightsManager.budStateOverride = nil
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
    for experiment in Experiment.allCases {
      let key = String.ExperimentOverrideKey.key(for: experiment.id.value)
      UserDefaults.standard.removeObject(forKey: key)
    }

    // Clear sale override
    UserDefaults.group.removeObject(forKey: String.SaleOverrideKey.overriddenSaleId)
  }

  private var currentBudStateLabel: String {
    guard let rawValue = todayInsightsManager.budStateOverride,
          let state = TodayReportResponse.BudState(rawValue: rawValue) else {
      return "No Override"
    }
    return budStateLabel(for: state)
  }

  private func budStateLabel(for state: TodayReportResponse.BudState) -> String {
    switch state {
    case .groggy:
      return "Groggy"
    case .sleepy:
      return "Sleepy"
    case .eatingSalad:
      return "Eating Salad"
    case .holdingSmoothie:
      return "Holding Smoothie"
    case .holdingTrophy:
      return "Holding Trophy"
    case .workingOut:
      return "Working Out"
    case .stressed:
      return "Stressed"
    case .proudCoach:
      return "Proud Coach"
    case .superhero:
      return "Superhero"
    case .running:
      return "Running"
    case .strengthTraining:
      return "Strength Training"
    case .yoga:
      return "Yoga"
    case .bicycleRiding:
      return "Bicycle Riding"
    @unknown default:
      return state.rawValue.capitalized
    }
  }

  // MARK: - Monitor Insight Context

  private func generateMonitorInsightContexts() async throws -> [MonitorInsightContextDebug] {
    let results = await MonitorCalculator.shared.getCachedStates()
    let enabledCategories = await AIDataSharingSettings.shared.enabledCategories

    var contexts: [MonitorInsightContextDebug] = []

    for result in results {
      // Check if required categories are enabled - skip entirely if not
      // to prevent leaking health data in the monitorContext
      let required = requiredCategories(for: result.monitorType)
      guard required.isSubset(of: enabledCategories) else {
        continue
      }

      let monitorContext = try JSONEncoder.bloomModel.encode(result)
      let monitorContextString = String(data: monitorContext, encoding: .utf8) ?? "{}"

      let healthContext = try await generateHealthContext(
        for: result.monitorType,
        enabledCategories: enabledCategories
      )

      contexts.append(MonitorInsightContextDebug(
        monitorType: result.monitorType.rawValue,
        monitorContext: monitorContextString,
        healthContext: healthContext,
        timezone: TimeZone.current.identifier
      ))
    }

    return contexts
  }

  private func generateHealthContext(
    for monitorType: MonitorType,
    enabledCategories: Set<AIHealthCategory>
  ) async throws -> String {
    let relevantCategories = requiredCategories(for: monitorType)
    let activeCategories = relevantCategories.intersection(enabledCategories)

    guard !activeCategories.isEmpty else {
      return "{}"
    }

    let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    guard let healthData = await ChatVitalConverter.shared.convertHealthData(
      from: startDate,
      enabledCategories: activeCategories
    ) else {
      return "{}"
    }

    let data = try JSONEncoder.bloomModel.encode(healthData)
    return String(data: data, encoding: .utf8) ?? "{}"
  }

  private func requiredCategories(for monitorType: MonitorType) -> Set<AIHealthCategory> {
    switch monitorType {
    case .sleep:
      return [.sleep, .physicalActivity]
    case .recovery:
      return [.bodyMetrics, .physicalActivity]
    case .stress:
      return [.physicalActivity, .bodyMetrics, .mentalWellness]
    }
  }
}

// MARK: - Debug Models

private struct MonitorInsightContextDebug: Codable {
  let monitorType: String
  let monitorContext: String
  let healthContext: String
  let timezone: String
}

#Preview {
  PreviewEnvironment {
    DeveloperSettingsView()
  }
}
