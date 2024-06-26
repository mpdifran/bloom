//
//  SleepHeartRateSummaryCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-26.
//

import SwiftUI

struct SleepHeartRateSummaryCell: View {
    let heartRates: [SleepAnalysis.HeartRateDataPoint]

    var body: some View {
        Section {
            SleepProgramSectionHeader(
                title: "Heart Rate",
                subtitle: "Last Night",
                systemImage: "heart.fill"
            )

            SleepHeartRateChartView(heartRates: heartRates)
                .padding(.bottom)
        }
        .tint(.pink)
    }
}

#Preview {
    List {
        SleepHeartRateSummaryCell(
            heartRates: SleepAnalysis.HeartRateDataPoint.previewData
        )
    }
}
