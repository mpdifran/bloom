//
//  PreferencesView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-06.
//

import SwiftUI
import AppUI

@MainActor
struct PreferencesView: View {

    @ObservedObject private var healthManager = HealthManager.shared
    @ObservedObject private var reportCoordinator = ReportCoordinator.shared

    @AppStorage("PreferencesView.user.name") private(set) var userName: String = ""
    @AppStorage("PreferencesView.danieleMode") private var danieleMode = false
    @AppStorage("hasShownOnboardingV3") var hasShownOnboarding: Bool = false

    @State private var shouldPromptForNotificationPermissions = false
    @State private var presentedFullScreenView: AnyView?
    @State private var presentedSheet: AnyView?
    @State private var alertDetails: AlertDetails?

    var body: some View {
        List {
            appInfoSection
            feedbackSection
            healthPermissionsSection
            healthGoalsSection
            femaleSection
            reportsSection
            nameSection
            developerSection
        }
        .fullScreenCover($presentedFullScreenView)
        .sheet($presentedSheet)
        .safeAreaInset(edge: .top) {
            Rectangle()
                .fill(.thickMaterial)
                .ignoresSafeArea()
                .frame(height: 0)
        }
        .onAppear {
            checkNotificationPermissions()
        }
        .alert(alertDetails: $alertDetails)
        .animation(.default, value: healthManager.healthGoal)
        .tabItem {
            Label("Preferences", systemImage: "slider.horizontal.below.square.and.square.filled")
        }
    }
}

private extension PreferencesView {

    func checkNotificationPermissions() {
        Task {
            shouldPromptForNotificationPermissions = await NotificationManager.shared.shouldRequestAuthorization()
        }
    }
}

private extension PreferencesView {

    var nameSection: some View {
        Section("User Details") {
            LabeledContent("Name") {
                TextField("", text: $userName, prompt: Text("Name"))
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
                    .tag(HealthManager.HealthGoal.none)
                Text("Lose Weight")
                    .tag(HealthManager.HealthGoal.loseWeight)
                Text("Maintain Weight")
                    .tag(HealthManager.HealthGoal.maintainWeight)
                Text("Gain Weight")
                    .tag(HealthManager.HealthGoal.gainWeight)
            }

            if healthManager.healthGoal == .loseWeight {
                VStack(alignment: .leading) {
                    Text("Target Weight")
                    HStack {
                        TextField(
                            "",
                            value: $healthManager.targetWeight,
                            formatter: NumberFormatter.oneDecimalPlace
                        )
                        .selectAllTextOnBeginEditing()
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .scrollDismissesKeyboard(.immediately)
                        .fontDesign(.rounded)
                        .bold()

                        Text("lbs")
                    }
                }
                Picker("", selection: $healthManager.weightLossSpeed) {
                    ForEach(HealthManager.WeightLossSpeed.allCases) { speed in
                        Text(speed.name)
                            .tag(speed)
                    }
                }
                .pickerStyle(.segmented)
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
            Toggle(isOn: $reportCoordinator.showMorningReportOnWakeUp) {
                Text("Morning Report on Wake Up")
            }

            DatePicker("Evening Report", selection: $reportCoordinator.eveningReportDate, displayedComponents: .hourAndMinute)
        }
    }

    var feedbackSection: some View {
        Section("Feedback") {
            Button {
                if userName.isEmpty {
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
        if healthManager.authStatus == .shouldRequest || shouldPromptForNotificationPermissions {
            Section("Permissions") {
                if healthManager.authStatus == .shouldRequest {
                    Button(action: {
                        Task {
                            await healthManager.requestAccessIfNeeded()
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

    var developerSection: some View {
        Section("Developer") {
            Toggle("Daniele Mode", isOn: $danieleMode)

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
                Text("Debug Habits")
            }
            .buttonStyle(.plain)

            Button("Prompt Focus Area Review") {
                HabitsViewModel.shared.resetHabitCheckDate()
                alertDetails = AlertDetails(title: "Focus Area Review", message: "You will now be prompted to review your focus areas.")
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
