//
//  SleepRespiratoryRateChartView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-06.
//

import SwiftUI
import Charts

struct SleepRespiratoryRateChartView: View {
    let respiratoryRates: [SleepAnalysis.RespiratoryRateDataPoint]

    var body: some View {
        Chart(respiratoryRates) { respiratoryRate in
            LineMark(
                x: .value("Date", respiratoryRate.startDate),
                y: .value("Average", respiratoryRate.averageRespiratoryRate)
            )
            .foregroundStyle(.teal)
        }
        .chartYScale(
            domain: ((minY ?? 0) - 5)...((maxY ?? 0) + 5),
            range: .plotDimension
        )
        .chartYAxis {
            AxisMarks { value in
                if let doubleValue = value.as(Double.self) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
        }
        .chartForegroundStyleScale([
            "Heart Rate": .teal
        ])
    }
}

private extension SleepRespiratoryRateChartView {

    var minY: Double? {
        respiratoryRates.min(by: { $0.averageRespiratoryRate < $1.averageRespiratoryRate })?.averageRespiratoryRate
    }

    var maxY: Double? {
        respiratoryRates.max(by: { $0.averageRespiratoryRate < $1.averageRespiratoryRate })?.averageRespiratoryRate
    }
}

#Preview {
    SleepRespiratoryRateChartView(
        respiratoryRates: SleepAnalysis.RespiratoryRateDataPoint.previewData
    )
}
