//
//  SleepProgramSetupView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-03.
//

import SwiftUI
import AppUI

struct SleepProgramSetupView: View {

    let onSetup: () -> Void

    @ObservedObject private var viewModel = SleepProgramSetupViewModel()
    @ObservedObject private var sleepProgramCoordinator = SleepProgramCoordinator.shared

    @State private var alertDetails: AlertDetails?
    @State private var hasStarted = false

    @Environment(\.dismiss) private var dismiss

    private let feedbackGenerator = UINotificationFeedbackGenerator()

    var body: some View {
        List {
            introductionSection
            segmentSection
            sleepDurationSection
        }
        .listStyle(.plain)
        .shelf {
            VStack(spacing: 20) {
                Button(action: {
                    guard !hasStarted else { return }

                    feedbackGenerator.notificationOccurred(.success)
                    sleepProgramCoordinator.startProgram()
                    hasStarted = true

                    Delay(1500) {
                        dismiss()
                        onSetup()
                    }
                }, label: {
                    HStack {
                        Spacer()
                        if hasStarted {
                            Image(systemName: "checkmark")
                                .bold()
                        } else {
                            Text("Start Program")
                        }
                        Spacer()
                    }
                })
                .buttonStyle(.tertiary)

                Button("Cancel") {
                    guard !hasStarted else { return }

                    dismiss()
                }
                .bold()
            }
        }
        .tint(.coreSleep)
        .safeAreaInset(edge: .top, spacing: 0) {
            Rectangle()
                .fill(.bar)
                .ignoresSafeArea()
                .safeAreaPadding(.top, 0)
                .frame(height: 0)
        }
        .presentationCompactAdaptation(.fullScreenCover)
        .alert(alertDetails: $alertDetails)
    }
}

private extension SleepProgramSetupView {

    var introductionSection: some View {
        Section {
            VStack(alignment: .leading) {
                Image(systemName: "moon.zzz.fill")
                    .foregroundStyle(.orange)
                    .font(.system(size: 80))
                    .horizontallyCentered()
                    .padding(.vertical, 50)

                VStack(alignment: .leading, spacing: 20) {
                    Text("Sleep Program")
                        .font(.title)
                        .bold()
                        .fontDesign(.rounded)

                    Text("Bloom will analyze your sleep data and make recommendations to improve your sleep. If things aren't working, Bloom will suggest changing the strategy. You can stop the program at any time.")
                    Text("View your current sleep data below. Bloom will aim to bring each segment into the necessary range.")
                }
            }
        }
        .removeListSeparator()
    }

    var segmentSection: some View {
        Section("Sleep Segments") {
            ForEach(viewModel.segmentSummary) { summary in
                SleepSegmentSummaryCell(summary: summary)
                    .standardListSeparatorInset()
            }
        }
    }

    var sleepDurationSection: some View {
        Section("Sleep Duration") {
            SleepDurationSummaryCell(sleepAnalyses: viewModel.sleepAnalyses)
        }
    }
}

#Preview {
    SleepProgramSetupView() { }
}
