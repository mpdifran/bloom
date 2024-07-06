//
//  SleepSoundLevelChartView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-26.
//

import SwiftUI
import Charts

struct SleepSoundLevelChartView: View {
    let soundLevels: [SleepAnalysis.SoundLevelDataPoint]

    var body: some View {
        Chart(soundLevels) { soundLevel in
            LineMark(
                x: .value("Date", soundLevel.startDate),
                y: .value("Average", soundLevel.decibelAWeightedSoundPressureLevelAverage)
            )
            .foregroundStyle(.yellow)
        }
        .chartYScale(
            domain: ((minY ?? 0) - 10)...((maxY ?? 0) + 10),
            range: .plotDimension
        )
        .chartYAxis {
            AxisMarks { value in
                if let doubleValue = value.as(Double.self) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        Text("\(Int(doubleValue)) dB")
                    }
                }
            }
        }
        .chartForegroundStyleScale([
            "Sound Levels": .yellow
        ])
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
