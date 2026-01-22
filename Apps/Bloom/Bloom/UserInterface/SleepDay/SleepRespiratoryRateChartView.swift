//
//  SleepRespiratoryRateChartView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-06.
//

import SwiftUI
import Charts
import CoreHealth

struct SleepRespiratoryRateChartView: View {
    let respiratoryRates: [SleepAnalysis.RespiratoryRateDataPoint]

    var body: some View {
        Chart(respiratoryRates) { respiratoryRate in
            AreaMark(
                x: .value("Date", respiratoryRate.startDate),
                y: .value("Average", respiratoryRate.averageRespiratoryRate)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.mutedLightBlue.opacity(0.4), Color.mutedLightBlue.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value("Date", respiratoryRate.startDate),
                y: .value("Average", respiratoryRate.averageRespiratoryRate)
            )
            .foregroundStyle(Color.mutedLightBlue)
            .lineStyle(StrokeStyle(lineWidth: 3))
            .interpolationMethod(.catmullRom)
        }
        .chartYScale(
            domain: ((minY ?? 0) - 5)...((maxY ?? 0) + 5),
            range: .plotDimension
        )
        .chartYAxis {
            AxisMarks(position: .trailing) { value in
                AxisGridLine()
                    .foregroundStyle(.secondary.opacity(0.3))
                if let doubleValue = value.as(Double.self) {
                    AxisValueLabel {
                        Text("\(Int(doubleValue))")
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
            "Respiratory Rate": .mutedLightBlue
        ])
        .chartLegend(.hidden)
    }
}

private extension SleepRespiratoryRateChartView {

    var minY: Double? {
        respiratoryRates.min(keyPath: \.averageRespiratoryRate)
    }

    var maxY: Double? {
        respiratoryRates.max(keyPath: \.averageRespiratoryRate)
    }
}

#Preview {
    SleepRespiratoryRateChartView(
        respiratoryRates: SleepAnalysis.RespiratoryRateDataPoint.previewData
    )
}
