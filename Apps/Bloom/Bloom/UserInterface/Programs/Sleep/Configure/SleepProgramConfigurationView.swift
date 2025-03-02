//
//  SleepProgramConfigurationView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-05.
//

import SFSafeSymbols
import SwiftUI
import AppUI
//import ScreenControl

struct SleepProgramConfigurationView: View {

    @ObservedObject private var viewModel = SleepProgramConfigurationViewModel()

    @ObservedObject private var sleepProgramCoordinator = SleepProgramCoordinator.shared
//    @ObservedObject private var screenUseController = ScreenUseController.shared

    @State private var isShowingFamilyActivityPicker = false
    @State private var confirmationDetails: ConfirmationDialogDetails?
    @State private var error: Error?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                statusSection
                screenUseSection
                environmentSection
                stopProgramSection
            }
            .navigationTitle("Configure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .bold()
                }
            }
        }
        .tint(.coreSleep)
        .alert(error: $error)
    }
}

private extension SleepProgramConfigurationView {

    var statusSection: some View {
        Section {
            HStack {
              Image(systemSymbol: .bedDoubleFill)
                    .font(.title2)
                    .foregroundStyle(.tint)
                
                Text("Sleep Program")
                    .font(.title2)
                    .bold()
            }

            if let startDate = sleepProgramCoordinator.startDate {
                TimelineView(.periodic(from: .now, by: 7200)) { context in
                    Text("Started \(startDate, formatter: DateFormatter.justRelativeDateMedium)")
                }
            }
        }
        .tint(.coreSleep)
    }

    var screenUseSection: some View {
        Section {
            SleepProgramSectionHeader(
                title: "Device Use",
                subtitle: "During Bedtime",
                symbol: .appsIphone
            )

            Text("Screen time before bed can affect your sleep quality. Allow Bloom to restrict app usage during bedtime.")

//            DatePicker(
//                "Wind Down",
//                selection: $screenUseController.startDate,
//                displayedComponents: .hourAndMinute
//            )
//
//            DatePicker(
//                "Wake Up",
//                selection: $screenUseController.endDate,
//                displayedComponents: .hourAndMinute
//            )
//
//            HStack {
//                LabeledContent("Apps") {
//                    if let summary = screenUseController.activitySelection.summaryText {
//                        Text(summary)
//                            .multilineTextAlignment(.trailing)
//                    } else {
//                        Text("No Apps Selected")
//                    }
//                }
//                DisclosureIndicator()
//            }
//            .frame(minHeight: 37)
//            .contentShape(Rectangle())
//            .onTapGesture {
//                isShowingFamilyActivityPicker = true
//            }
//            .familyActivityPicker(
//                headerText: "Bloom will restrict usage of these apps during bedtime",
//                isPresented: $isShowingFamilyActivityPicker,
//                selection: $screenUseController.activitySelection
//            )

//            if screenUseController.isMonitoring {
//                Button(action: {
//                    screenUseController.stopMonitoring()
//                }, label: {
//                    Text("Stop Monitoring")
//                        .expandHorizontally()
//                })
//                .tint(.red)
//                .buttonStyle(.primary)
//            } else {
//                Button(action: {
//                    do {
//                        try screenUseController.startMonitoring()
//                    } catch {
//                        self.error = error
//                    }
//                }, label: {
//                    Text("Start Monitoring")
//                        .expandHorizontally()
//                })
//                .tint(.green)
//                .buttonStyle(.primary)
//            }
        }
        .tint(.indigo)
    }

    var environmentSection: some View {
        Section {
            SleepProgramSectionHeader(
                title: "Environment",
                subtitle: "During Bedtime",
                symbol: .thermometerSnowflake
            )
            .tint(.remSleep)

            Text("Your sleep environment can play a major factor in your sleep quality. By giving Bloom an idea of how you sleep, it can provide better recommendations.")

            Picker(selection: $sleepProgramCoordinator.environmentTemperature) {
                ForEach(SleepEnvironmentTemperature.allCases) {
                    Text($0.name)
                        .tag($0)
                }
            } label: {
                Text("Temperature")
            }

            Picker(selection: $sleepProgramCoordinator.environmentSound) {
                ForEach(SleepEnvironmentSound.allCases) {
                    Text($0.name)
                        .tag($0)
                }
            } label: {
                Text("Sound")
            }

            Picker(selection: $sleepProgramCoordinator.environmentDarkness) {
                ForEach(SleepEnvironmentDarkness.allCases) {
                    Text($0.name)
                        .tag($0)
                }
            } label: {
                Text("Darkness")
            }
        }
    }

    var stopProgramSection: some View {
        Section {
            Button("Stop Program", systemImage: "exclamationmark.octagon.fill", role: .destructive) {
              confirmationDetails = ConfirmationDialogDetails(
                    title: "Are You Sure?",
                    message: "This will stop the program, and you'll have to start again from a new benchmark.",
                    buttons: [
                        ConfirmationDialogDetails.Button(title: "Stop Program", role: .destructive) {
                            sleepProgramCoordinator.stopProgram()
                            dismiss()
                        },
                        ConfirmationDialogDetails.Button(title: "Nevermind", role: .cancel) { }
                    ]
                )
            }
            .confirmationDialog($confirmationDetails)
            .foregroundStyle(.red)
        }
    }
}

#Preview {
    SleepProgramConfigurationView()
}
