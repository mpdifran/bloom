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
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
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
            "Respiratory Rate": .teal
        ])
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
