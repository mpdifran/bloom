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
            BarMark(
                x: .value("Date", soundLevel.startDate),
                yStart: .value("Min", soundLevel.decibelAWeightedSoundPressureLevelMin),
                yEnd: .value("Max", soundLevel.decibelAWeightedSoundPressureLevelMax)
            )
            .foregroundStyle(.yellow)
            .cornerRadius(5)
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
        soundLevels.min(by: { $0.decibelAWeightedSoundPressureLevelMin < $1.decibelAWeightedSoundPressureLevelMin })?.decibelAWeightedSoundPressureLevelMin
    }

    var maxY: Double? {
        soundLevels.max(by: { $0.decibelAWeightedSoundPressureLevelMax < $1.decibelAWeightedSoundPressureLevelMax })?.decibelAWeightedSoundPressureLevelMax
    }
}

#Preview {
    List {
        SleepSoundLevelChartView(
            soundLevels: SleepAnalysis.SoundLevelDataPoint.previewData
        )
    }
}
