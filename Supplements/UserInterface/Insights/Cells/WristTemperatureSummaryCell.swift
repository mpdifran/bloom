//
//  WristTemperatureSummaryCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-08.
//

import SwiftUI

struct WristTemperatureSummaryCell: View {
    let wristTemperature: [SleepAnalysis.WristTemperatureDataPoint]

    var body: some View {
        Section {
            VStack {
                TodaySectionTitleView(
                    title: "Wrist Temperature",
                    systemImage: "thermometer.medium"
                )

                WristTemperatureChartView(wristTemperatures: wristTemperature)
                    .frame(height: 120)
            }
            .padding(.bottom)
        }
        .tint(.indigo)
    }
}

#Preview {
    WristTemperatureSummaryCell(
        wristTemperature: SleepAnalysis.WristTemperatureDataPoint.previewData
    )
}
