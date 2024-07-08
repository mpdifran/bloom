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

    @State private var remSleepPercent: CGFloat = 0
    @State private var coreSleepPercent: CGFloat = 0
    @State private var deepSleepPercent: CGFloat = 0
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
            HStack {
                VStack(alignment: .leading) {
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
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                SleepProgressRingView(
                    remSleepPercentage: $remSleepPercent,
                    coreSleepPercentage: $coreSleepPercent,
                    deepSleepPercentage: $deepSleepPercent
                )
            }

            SleepSegmentScoreView(
                title: "Sleep Length Score",
                color: .green,
                minutes: lastSleepAnalysis.overallMinutes,
                score: lastSleepAnalysis.sleepLengthScore
            )

            SleepSegmentScoreView(
                title: "REM Sleep Score",
                color: .remSleep,
                minutes: lastSleepAnalysis.remSleepMinutes,
                overallMinutes: lastSleepAnalysis.overallMinutes,
                score: lastSleepAnalysis.remSleepScore
            )

            SleepSegmentScoreView(
                title: "Core Sleep Score",
                color: .coreSleep,
                minutes: lastSleepAnalysis.coreSleepMinutes,
                overallMinutes: lastSleepAnalysis.overallMinutes,
                score: lastSleepAnalysis.coreSleepScore
            )

            SleepSegmentScoreView(
                title: "Deep Sleep Score",
                color: .deepSleep,
                minutes: lastSleepAnalysis.deepSleepMinutes,
                overallMinutes: lastSleepAnalysis.overallMinutes,
                score: lastSleepAnalysis.deepSleepScore
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
        .animation(.easeInOut(duration: 1.2), value: remSleepPercent)
        .animation(.easeInOut(duration: 1.2), value: coreSleepPercent)
        .animation(.easeInOut(duration: 1.2), value: deepSleepPercent)
        .onAppear {
            Delay(1500) {
                remSleepPercent = lastSleepAnalysis.remSleepPercent / .remSleepPercent
                coreSleepPercent = lastSleepAnalysis.coreSleepPercent / .coreSleepPercent
                deepSleepPercent = lastSleepAnalysis.deepSleepPercent / .deepSleepPercent
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
    let color: Color
    let minutes: Double
    let overallMinutes: Double?
    let score: Int

    init(
        title: String,
        color: Color,
        minutes: Double,
        overallMinutes: Double? = nil,
        score: Int
    ) {
        self.title = title
        self.color = color
        self.minutes = minutes
        self.overallMinutes = overallMinutes
        self.score = score
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Circle()
                        .fill(color)
                        .frame(width: 10, height: 10)

                    VStack(alignment: .leading) {
                        Text(title)
                            .fontDesign(.rounded)
                            .bold()

                        HStack(spacing: 2) {
                            Text(DateFormatter.timeIntervalHourMinuteShort.string(from: minutes * 60) ?? "")

                            if let overallMinutes {
                                Text("•")
                                Text("\(minutes / overallMinutes * 100, specifier: "%.0f")%")
                            }

                            Spacer()
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
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
                                awakeSleepMinutes: 32,
                                environmentalSoundLevels: SleepAnalysis.SoundLevelDataPoint.previewData,
                                heartRate: SleepAnalysis.HeartRateDataPoint.previewData,
                                respiratoryRate: SleepAnalysis.RespiratoryRateDataPoint.previewData,
                                wristTemperature: SleepAnalysis.WristTemperatureDataPoint.previewData
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
