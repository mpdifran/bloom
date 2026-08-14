//
//  SleepSoundLevelChartView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-26.
//

import SwiftUI
import Charts
import CoreHealth

struct SleepSoundLevelChartView: View {
    let soundLevels: [SleepAnalysis.SoundLevelDataPoint]

    var body: some View {
        Chart(soundLevels) { soundLevel in
            AreaMark(
                x: .value("Date", soundLevel.startDate),
                y: .value("Average", soundLevel.decibelAWeightedSoundPressureLevelAverage)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.mutedYellow.opacity(0.4), Color.mutedYellow.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            LineMark(
                x: .value("Date", soundLevel.startDate),
                y: .value("Average", soundLevel.decibelAWeightedSoundPressureLevelAverage)
            )
            .foregroundStyle(Color.mutedYellow)
            .lineStyle(StrokeStyle(lineWidth: 3))
        }
        .chartYScale(
            domain: ((minY ?? 0) - 10)...((maxY ?? 0) + 10),
            range: .plotDimension
        )
        .chartYAxis {
            AxisMarks(position: .trailing) { value in
                AxisGridLine()
                    .foregroundStyle(.secondary.opacity(0.3))
                if let doubleValue = value.as(Double.self) {
                    AxisValueLabel {
                        Text(verbatim: "\(Int(doubleValue))")
                            .font(.caption2)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .chartForegroundStyleScale([
            "Sound Levels": .mutedYellow
        ])
        .chartLegend(.hidden)
    }
}

private extension SleepSoundLevelChartView {

    var minY: Double? {
        soundLevels.min(keyPath: \.decibelAWeightedSoundPressureLevelAverage)
    }

    var maxY: Double? {
        soundLevels.max(keyPath: \.decibelAWeightedSoundPressureLevelAverage)
    }
}

#Preview {
    List {
        SleepSoundLevelChartView(
            soundLevels: SleepAnalysis.SoundLevelDataPoint.previewData
        )
    }
}
