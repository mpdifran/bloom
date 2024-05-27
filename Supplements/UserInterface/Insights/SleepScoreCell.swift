//
//  SleepScoreCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-25.
//

import SwiftUI
import AppUI

@MainActor
struct SleepScoreCell: View {
    let sleepAnalysis: [SleepAnalysis]
    let showSleepSummaryView: () -> Void

    @State private var error: Error?

    @EnvironmentObject private var tabContorller: TabController
    @ObservedObject private var chatViewModel = ChatViewModel.shared

    var body: some View {
        if let lastSleepAnalysis {
            content(for: lastSleepAnalysis)
        } else {
            EmptyView()
        }
    }
}

private extension SleepScoreCell {

    func content(for lastSleepAnalysis: SleepAnalysis) -> some View {
        Section {
            VStack {
                Text("\(lastSleepAnalysis.overallScore)")
                    .font(.system(size: 80))
                    .fontDesign(.rounded)
                    .bold()
                    .foregroundStyle(lastSleepAnalysis.overallScore.scoreColor)

                Text("Sleep Score")
                    .font(.title)
                    .fontDesign(.rounded)
                    .bold()

                Text(lastSleepAnalysis.timeSpanDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .zStackAlignment(.center)

            SleepSegmentScoreView(
                title: "Core Sleep Score",
                minutes: lastSleepAnalysis.coreSleepMinutes,
                score: lastSleepAnalysis.coreSleepScore
            )

            SleepSegmentScoreView(
                title: "Deep Sleep Score",
                minutes: lastSleepAnalysis.deepSleepMinutes,
                score: lastSleepAnalysis.deepSleepScore
            )

            SleepSegmentScoreView(
                title: "REM Sleep Score",
                minutes: lastSleepAnalysis.remSleepMinutes,
                score: lastSleepAnalysis.remSleepScore
            )

            SleepSegmentScoreView(
                title: "Sleep Length Score",
                minutes: lastSleepAnalysis.timeIntervalMinutes,
                showHours: true,
                score: lastSleepAnalysis.sleepLengthScore
            )

            HStack {
                Button(action: {
                    sendAIMessage(for: lastSleepAnalysis)
                }, label: {
                    HStack {
                        Spacer(minLength: 0)
                        Image(systemName: "sparkles")
                        Text("Ask Bloom")
                        Spacer(minLength: 0)
                    }
                })
                .buttonStyle(.tertiary)

                Spacer()

                Button(action: {
                    showSleepSummaryView()
                }, label: {
                    HStack {
                        Spacer(minLength: 0)
                        Image(systemName: "bed.double.fill")
                        Text("See More")
                        Spacer(minLength: 0)
                    }
                })
                .buttonStyle(.tertiary)
                .tint(.teal)
            }
        }
        .alert(error: $error)
    }
}

private extension SleepScoreCell {

    var lastSleepAnalysis: SleepAnalysis? {
        sleepAnalysis.last
    }

    func sendAIMessage(for sleepAnalysis: SleepAnalysis) {
        tabContorller.select(.chat)

        Task {
            do {
                let secretContext = try JSONEncoder.main.encode(lastSleepAnalysis)
                try await chatViewModel.send(
                    prompt: "Can you elaborate on my sleep score?",
                    secretContext: String(data: secretContext, encoding: .utf8)
                )
            } catch {
                self.error = error
            }
        }
    }
}

struct SleepSegmentScoreView: View {
    let title: String
    let minutes: Double
    let showHours: Bool
    let score: Int

    init(
        title: String,
        minutes: Double,
        showHours: Bool = false,
        score: Int
    ) {
        self.title = title
        self.minutes = minutes
        self.showHours = showHours
        self.score = score
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .fontDesign(.rounded)
                    .bold()
                Group {
                    if showHours {
                        Text("\(minutes / 60, specifier: "%.0f") hours")
                    } else {
                        Text("\(minutes, specifier: "%.0f") minutes")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(score)")
                .font(.title)
                .fontDesign(.rounded)
                .bold()
                .foregroundStyle(score.scoreColor)
        }
    }
}

#Preview {
    struct PreviewView: View {
        @StateObject private var tabController = TabController()

        var body: some View {
            NavigationStack {
                List {
                    SleepScoreCell(
                        sleepAnalysis: [
                            .init(
                                startDate: Date().addingTimeInterval(-25200),
                                endDate: Date(),
                                deepSleepMinutes: 45.2,
                                coreSleepMinutes: 180,
                                remSleepMinutes: 93,
                                awakeSleepMinutes: 32
                            )
                        ]
                    ) { }
                }
                .navigationTitle("Insights")
            }
            .environmentObject(tabController)
        }
    }

    return PreviewView()
}
