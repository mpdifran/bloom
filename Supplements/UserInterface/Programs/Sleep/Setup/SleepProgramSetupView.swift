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
        NavigationStack {
            List {
                introductionSection
                segmentSection
            }
            .listStyle(.plain)
            .navigationTitle("Sleep Program Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .shelf {
                Button(action: {
                    feedbackGenerator.notificationOccurred(.success)

                    alertDetails = .init(
                        title: "Not Yet Implemented",
                        message: "Whoa there cowboy, this feature isn't implemented yet. Soon though!"
                    ) {
                        dismiss()
                    }
                },
                       label: {
                    HStack {
                        Spacer()
                        Label("Start Program", systemImage: "moon.zzz.fill")
                        Spacer()
                    }
                })
                .buttonStyle(.tertiary)
            }
        }
        .tint(.coreSleep)
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
                    Text("Bloom will analyze your sleep data and make recommendations to improve your sleep. If things aren't working, Bloom will suggest changing the strategy.")
                    Text("View your current sleep segments below.")
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 25.0)
                        .fill(.background.secondary)
                }
            }
        }
    }

    var segmentSection: some View {
        Section("Sleep Segments") {
            ForEach(viewModel.segmentSummary) { summary in
                SleepSegmentSummaryCell(summary: summary)
            }
        }
    }
}

#Preview {
    SleepProgramSetupView()
}
