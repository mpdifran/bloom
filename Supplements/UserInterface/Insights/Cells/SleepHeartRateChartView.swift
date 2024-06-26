//
//  SleepHeartRateChartView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-26.
//

import SwiftUI
import Charts

struct SleepHeartRateChartView: View {
    let heartRates: [SleepAnalysis.HeartRateDataPoint]

    var body: some View {
        Chart(heartRates) { heartRate in
            BarMark(
                x: .value("Date", heartRate.startDate),
                yStart: .value("Min", heartRate.minHeartRate),
                yEnd: .value("Max", heartRate.maxHeartRate)
            )
            .foregroundStyle(.pink)
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
                        Text("\(Int(doubleValue)) bpm")
                    }
                }
            }
        }
        .chartForegroundStyleScale([
            "Heart Rate": .pink
        ])
    }
}

private extension SleepHeartRateChartView {

    var minY: Double? {
        heartRates.min(by: { $0.minHeartRate < $1.minHeartRate })?.minHeartRate
    }

    var maxY: Double? {
        heartRates.max(by: { $0.maxHeartRate < $1.maxHeartRate })?.maxHeartRate
    }
}

#Preview {
    List {
        SleepHeartRateChartView(
            heartRates: SleepAnalysis.HeartRateDataPoint.previewData
        )
    }
}
