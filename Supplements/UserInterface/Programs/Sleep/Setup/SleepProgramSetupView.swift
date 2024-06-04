//
//  SleepProgramSetupView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-03.
//

import SwiftUI
import AppUI

struct SleepProgramSetupView: View {

    @ObservedObject private var viewModel = SleepProgramSetupViewModel()

    @State private var alertDetails: AlertDetails?

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
                    feedbackGenerator.notificationOccurred(.success)

                    alertDetails = .init(
                        title: "Not Yet Implemented",
                        message: "Whoa there cowboy, this feature isn't implemented yet. Soon though!"
                    ) {
                        dismiss()
                    }
                }, label: {
                    HStack {
                        Spacer()
                        Label("Start Program", systemImage: "moon.zzz.fill")
                        Spacer()
                    }
                })
                .buttonStyle(.tertiary)

                Button("Cancel") {
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
        .task {
            await viewModel.loadData()
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
    SleepProgramSetupView()
}
