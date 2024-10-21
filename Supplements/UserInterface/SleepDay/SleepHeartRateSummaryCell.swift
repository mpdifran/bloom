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
            VStack {
                SleepSectionTitleView(
                    title: "Heart Rate",
                    systemImage: "heart.fill"
                )

                SleepHeartRateChartView(heartRates: heartRates)
                    .frame(height: 120)
            }
            .padding(.bottom)
        }
        .tint(.mutedPink)
    }
}

#Preview {
    List {
        SleepHeartRateSummaryCell(
            heartRates: SleepAnalysis.HeartRateDataPoint.previewData
        )
    }
}
