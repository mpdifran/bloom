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
                .tint(.mutedGreen)

                LabelledText(
                    label: "REM Sleep",
                    systemImage: "eyes",
                    value: remDescription
                )
                .tint(sleepAnalysis.remSleepHours == nil ? Color.gray : Color.remSleep)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 20) {
                LabelledText(
                    label: "Awake Time",
                    systemImage: "bolt.horizontal",
                    value: awakeDescription
                )
                .tint(sleepAnalysis.awakeSleepHours == nil ? .gray : .awakeSleep)

                LabelledText(
                    label: "Core Sleep",
                    systemImage: "circle.dotted.circle",
                    value: coreDescription
                )
                .tint(sleepAnalysis.coreSleepHours == nil ? .gray : .coreSleep)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 20) {
                LabelledText(
                    label: "Heart Rate",
                    systemImage: "heart",
                    value: heartRateDescription
                )
                .tint(sleepAnalysis.averageHeartRate == nil ? .gray : .mutedPink)

                LabelledText(
                    label: "Deep Sleep",
                    systemImage: "arrow.down.to.line",
                    value: deepDescription
                )
                .tint(sleepAnalysis.deepSleepHours == nil ? .gray : .deepSleep.lighter())
            }
        }
    }
}

extension SleepScoreDetailsView {

    var remDescription: String {
        if let remSleepHours = sleepAnalysis.remSleepHours {
            return "\(remSleepHours.format(using: .oneDecimalPlace)) hours"
        } else {
            return "-- hours"
        }
    }

    var coreDescription: String {
        if let coreSleepHours = sleepAnalysis.coreSleepHours {
            return "\(coreSleepHours.format(using: .oneDecimalPlace)) hours"
        } else {
            return "-- hours"
        }
    }

    var deepDescription: String {
        if let deepSleepHours = sleepAnalysis.deepSleepHours {
            return "\(deepSleepHours.format(using: .oneDecimalPlace)) hours"
        } else {
            return "-- hours"
        }
    }

    var awakeDescription: String {
        if let awakeSleepHours = sleepAnalysis.awakeSleepHours {
            return "\(awakeSleepHours.format(using: .oneDecimalPlace)) hours"
        } else {
            return "-- hours"
        }
    }

    var heartRateDescription: String {
        if let heartRate = sleepAnalysis.averageHeartRate {
            return "\(heartRate.format()) bpm"
        } else {
            return "-- bpm"
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
            .font(.caption)
            .bold()

            Text(value)
                .foregroundStyle(.tint)
                .bold()
                .font(.title3)
                .fontDesign(.rounded)
        }
    }
}

#Preview {
    List {
        SleepScoreDetailsView(sleepAnalysis: SleepAnalysis.previewData[0])

        SleepScoreDetailsView(
            sleepAnalysis: .init(
                startDate: .now.addingTimeInterval(-30000),
                endDate: .now,
                hasDetailedSleepCategories: false,
                deepSleepMinutes: 0,
                coreSleepMinutes: 0,
                remSleepMinutes: 0,
                awakeSleepMinutes: 0,
                averageRestingHeartRate: nil,
                environmentalSoundLevels: [],
                heartRate: [],
                respiratoryRate: [],
                wristTemperature: nil
            )
        )
    }
    .listStyle(.plain)
}
