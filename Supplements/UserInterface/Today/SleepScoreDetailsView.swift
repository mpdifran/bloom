//
//  SleepScoreDetailsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-15.
//

import SwiftUI

struct SleepScoreDetailsView: View {
    let sleepAnalysis: SleepAnalysis

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 20) {
                LabelledText(
                    label: "Sleep Length",
                    systemImage: "clock",
                    value: "\(String(format: "%.1f", sleepAnalysis.overallHours)) hours"
                )
                .tint(.green)

                LabelledText(
                    label: "REM Sleep",
                    systemImage: "eyes",
                    value: "\(String(format: "%.1f", sleepAnalysis.remSleepHours)) hours"
                )
                .tint(.remSleep)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 20) {
                LabelledText(
                    label: "Sound Level",
                    systemImage: "speaker.zzz",
                    value: "\(String(format: "%.1f", sleepAnalysis.averageSoundLevel)) db"
                )
                .tint(.yellow)

                LabelledText(
                    label: "Core Sleep",
                    systemImage: "circle.dotted.circle",
                    value: "\(String(format: "%.1f", sleepAnalysis.coreSleepHours)) hours"
                )
                .tint(.coreSleep)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 20) {
                LabelledText(
                    label: "Heart Rate",
                    systemImage: "heart",
                    value: "\(String(format: "%.1f", sleepAnalysis.averageHeartRate)) bpm"
                )
                .tint(.pink)

                LabelledText(
                    label: "Deep Sleep",
                    systemImage: "arrow.down.to.line",
                    value: "\(String(format: "%.1f", sleepAnalysis.deepSleepHours)) hours"
                )
                .tint(.deepSleep.lighter())
            }
        }
    }
}

private struct LabelledText: View {
    let label: String
    let systemImage: String
    let value: String

    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 2) {
                Image(systemName: systemImage)
                Text(label)
            }
            .foregroundStyle(.secondary)
            .font(.caption)
            .bold()

            Text(value)
                .foregroundStyle(.tint)
                .bold()
                .font(.title3)
        }
    }
}

#Preview {
    List {
        SleepScoreDetailsView(sleepAnalysis: SleepAnalysis.previewData[0])
    }
    .listStyle(.plain)
}
