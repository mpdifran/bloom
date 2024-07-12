//
//  WristTemperatureChartView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-08.
//

import SwiftUI
import Charts

struct WristTemperatureChartView: View {
    let wristTemperatures: [SleepAnalysis.WristTemperatureDataPoint]

    var body: some View {
        Chart(wristTemperatures) { wristTemperature in
            LineMark(
                x: .value("Date", wristTemperature.startDate),
                y: .value("Average", wristTemperature.averageWristTemperature)
            )
            .foregroundStyle(.indigo)
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
            "Wrist Temperature": .indigo
        ])
    }
}

private extension WristTemperatureChartView {

    var minY: Double? {
        wristTemperatures.min(keyPath: \.averageWristTemperature)
    }

    var maxY: Double? {
        wristTemperatures.max(keyPath: \.averageWristTemperature)
    }
}

#Preview {
    WristTemperatureChartView(
        wristTemperatures: SleepAnalysis.WristTemperatureDataPoint.previewData
    )
}
