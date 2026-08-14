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
            .foregroundStyle(Color.mutedRed)
            .lineStyle(StrokeStyle(lineWidth: 3))
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value("Date", heartRate.startDate),
                y: .value("Average", heartRate.averageHeartRate)
            )
            .foregroundStyle(Color(.systemBackground))
            .symbolSize(60)

            PointMark(
                x: .value("Date", heartRate.startDate),
                y: .value("Average", heartRate.averageHeartRate)
            )
            .foregroundStyle(Color.mutedRed)
            .symbolSize(30)
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
            "Heart Rate": .mutedRed
        ])
        .chartLegend(.hidden)
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
