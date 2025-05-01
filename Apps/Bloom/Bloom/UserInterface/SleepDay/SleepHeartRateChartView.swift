//
//  SleepHeartRateChartView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-26.
//

import SwiftUI
import Charts
import CoreHealth

struct SleepHeartRateChartView: View {
    let heartRates: [SleepAnalysis.HeartRateDataPoint]

    var body: some View {
        Chart(heartRates) { heartRate in
            LineMark(
                x: .value("Date", heartRate.startDate),
                y: .value("Average", heartRate.averageHeartRate)
            )
            .foregroundStyle(.mutedPink)
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
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .chartForegroundStyleScale([
            "Heart Rate": .mutedPink
        ])
    }
}

private extension SleepHeartRateChartView {

    var minY: Double? {
        heartRates.min(keyPath: \.averageHeartRate)
    }

    var maxY: Double? {
        heartRates.max(keyPath: \.averageHeartRate)
    }
}

#Preview {
    List {
        SleepHeartRateChartView(
            heartRates: SleepAnalysis.HeartRateDataPoint.previewData
        )
    }
}
