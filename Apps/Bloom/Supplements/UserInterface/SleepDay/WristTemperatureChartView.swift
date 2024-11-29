//
//  WristTemperatureChartView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-08.
//

import SwiftUI
import Charts

struct WristTemperatureChartView: View {
    let wristTemperature: SleepAnalysis.WristTemperatureDataPoint

    var body: some View {
        Chart {
            BarMark(
                xStart: .value("", wristTemperature.averageWristTemperature - 2),
                xEnd: .value("Average", wristTemperature.averageWristTemperature),
                y: .value("Date", wristTemperature.startDate, unit: .day)
            )
            .foregroundStyle(.mutedIndigo)
            .cornerRadius(10)
        }
        .chartXScale(
            domain: minX...maxX,
            range: .plotDimension
        )
        .chartXAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.day())
            }
        }
        .chartForegroundStyleScale([
            "Wrist Temperature": .mutedIndigo
        ])
    }
}

private extension WristTemperatureChartView {

    var minX: Double {
        wristTemperature.averageWristTemperature - 2
    }

    var maxX: Double {
        wristTemperature.averageWristTemperature + 2
    }
}

#Preview {
    WristTemperatureChartView(
        wristTemperature: SleepAnalysis.WristTemperatureDataPoint.previewData
    )
}
