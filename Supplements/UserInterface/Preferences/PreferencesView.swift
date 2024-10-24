//
//  PreferencesView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-06.
//

import SwiftUI
import AppUI
import HealthKit

@MainActor
struct PreferencesView: View {

    @ObservedObject private var healthManager = HealthManager.shared
    @Bindable private var reportViewModel = ReportCoordinatorViewModel.shared

    @Bindable private var unitPreferences = HealthUnitPreferences.shared

    @AppStorage("PreferencesView.danieleMode") private var danieleMode = false
    @AppStorage("hasShownOnboardingV3") var hasShownOnboarding: Bool = false

    @State private var authStatus: HKAuthorizationRequestStatus = .unknown
    @State private var shouldPromptForNotificationPermissions = false
    @State private var presentedFullScreenView: AnyView?
    @State private var presentedSheet: AnyView?
    @State private var alertDetails: AlertDetails?
    @State private var error: Error?

    private let vitalsViewModel = VitalsViewModel.shared

    var body: some View {
        List {
            appInfoSection
            feedbackSection
            healthPermissionsSection
            healthGoalsSection
            unitsSection
            femaleSection
            reportsSection
            nameSection
            developerSection
        }
        .fullScreenCover($presentedFullScreenView)
        .sheet($presentedSheet)
        .topSafeAreaBlur()
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
        .animation(.default, value: healthManager.healthGoal)
        .tabItem {
            Label("Preferences", systemImage: "slider.horizontal.below.square.and.square.filled")
        }
    }
}

private extension PreferencesView {

    var nameSection: some View {
        Section("User Details") {
            LabeledContent("Name") {
                TextField("", text: $healthManager.name, prompt: Text("Name"))
                    .multilineTextAlignment(.trailing)
                    .textContentType(.name)
                    .submitLabel(.done)
            }
            LabeledContent("ID") {
                Text(UserID.value)
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
            }
        }
    }

    var healthGoalsSection: some View {
        Section {
            Picker("Goal", selection: $healthManager.healthGoal) {
                Text("None")
                    .tag(HealthGoal.none)
                Text("Lose Weight")
                    .tag(HealthGoal.loseWeight)
                Text("Maintain Weight")
                    .tag(HealthGoal.maintainWeight)
                Text("Gain Weight")
                    .tag(HealthGoal.gainWeight)
            }

            LabeledContent("Target Weight") {
                HStack {
                    Text("\(healthManager.targetWeight.format(using: .oneDecimalPlace)) lbs")
                    DisclosureIndicator()
                }
            }
            .onTapGesture {
                presentedSheet = TargetWeightEditCard().asAny
            }

            if healthManager.healthGoal == .loseWeight || healthManager.healthGoal == .gainWeight {
                Picker("", selection: $healthManager.weightLossSpeed) {
                    ForEach(WeightLossSpeed.allCases) { speed in
                        Text(speed.name)
                            .tag(speed)
                    }
                }
                .pickerStyle(.segmented)
            }

            if
                vitalsViewModel.activityLevelSummary?.details.activityLevel == nil
            {
                LabeledContent("Activity Level") {
                    HStack {
                        Text(healthManager.userReportedActivityLevel?.name ?? "Unknown")
                        DisclosureIndicator()
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    presentedSheet = ActivityLevelEditCard().asAny
                }
            }
        } header: {
            Text("Health Goals")
        } footer: {
            if healthManager.healthGoal == .loseWeight {
                Text(healthManager.weightLossSpeed.weightLossDescription)
            }
        }
    }

    var appInfoSection: some View {
        Section {
            LabeledContent("App Version", value: appVersion ?? "Unknown")
        } header: {
            VStack {
                Image(.bloomAppIcon)
                    .resizable()
                    .frame(square: 150)
                Text("Bloom")
                    .font(.title)
                    .bold()
                    .foregroundStyle(.text)
            }
            .padding(.bottom)
            .horizontallyCentered()
            .textCase(.none)
        }
    }

    var reportsSection: some View {
        Section("Reports") {
            Toggle(isOn: $reportViewModel.showMorningReportOnWakeUp) {
                Text("Morning Report on Wake Up")
            }

            DatePicker("Evening Report", selection: $reportViewModel.eveningReportDate, displayedComponents: .hourAndMinute)
        }
    }

    var unitsSection: some View {
        Section("Units") {
            Picker("Distance", selection: $unitPreferences.distanceUnit) {
                ForEach(HKUnit.distanceUnits, id: \.unitString) { unit in
                    Text(unit.descriptiveUnitName)
                        .tag(unit)
                }
            }
            Picker("Liquid Volume", selection: $unitPreferences.liquidVolumeUnit) {
                ForEach(HKUnit.liquidVolumeUnits, id: \.unitString) { unit in
                    Text(unit.descriptiveUnitName)
                        .tag(unit)
                }
            }
            Picker("Weight", selection: $unitPreferences.weightUnit) {
                ForEach(HKUnit.weightUnits, id: \.unitString) { unit in
                    Text(unit.descriptiveUnitName)
                        .tag(unit)
                }
            }
        }
    }

    var feedbackSection: some View {
        Section("Feedback") {
            Button {
                if healthManager.name.isEmpty {
                    presentedSheet = UserNamePrompt {
                        showFeedbackView()
                    }
                    .asAny
                } else {
                    showFeedbackView()
                }
            } label: {
                LabeledContent("Submit Feedback") {
                    Image(systemName: "heart")
                        .foregroundStyle(.red)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    func showFeedbackView() {
        presentedFullScreenView = FeatureRequestScreen().asAny
    }

    @ViewBuilder
    var femaleSection: some View {
        if healthManager.healthStore.sex() == .female {
            Section("Health Context") {
                Toggle("Is Breastfeeding", isOn: healthManager.$isBreastfeeding)
                Toggle("Is Pregnant", isOn: healthManager.$isPregnant)
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

    func checkHealthAuthStatus() async {
        self.authStatus = (try? await HealthPermissionChecker.shared.checkAccessForAllTypes()) ?? .unknown
    }

    var developerSection: some View {
        Section("Developer") {
            Toggle("Daniele Mode", isOn: $danieleMode)

            Button {
                presentedSheet = ColorPaletteView().asAny
            } label: {
                LabeledContent("Color Palette") {
                    Image(systemName: "palette")
                }
            }
            .buttonStyle(.plain)

            Button {
                hasShownOnboarding = false
            } label: {
                LabeledContent("Reset Onboarding") {
                    Image(systemName: "arrow.uturn.backward.square.fill")
                }
            }
            .buttonStyle(.plain)

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
                    await NotificationManager.shared.sendGoodMorningNotification(message: "Test")
                }
            } label: {
                HStack {
                    Text("Send Good Morning Notification")
                    Spacer()
                    DisclosureIndicator()
                }
            }
            .buttonStyle(.plain)

            Button {
                Task {
                    do {
                        let jsonString = try await JSONGenerator.shared.generateJSONString()
                        UIPasteboard.general.string = jsonString

                        await MainActor.run {
                            alertDetails = AlertDetails(
                                title: "Copied to Clipboard",
                                message: "The data for your Vitals have been copied to your clipboard."
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
                    Text("Copy Vitals JSON to Clipboard")
                    Spacer()
                    DisclosureIndicator()
                }
            }
            .buttonStyle(.plain)
        }
    }
}

private extension PreferencesView {

    var appVersion: String? {
        guard let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else { return nil }

        if let buildString = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "\(versionString) (\(buildString))"
        }
        return versionString
    }
}

#Preview {
    TabView {
        PreferencesView()
    }
}
