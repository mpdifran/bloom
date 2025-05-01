//
//  SleepHeartRateSummaryCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-26.
//

import SFSafeSymbols
import SwiftUI
import CoreHealth

struct SleepHeartRateSummaryCell: View {
    let heartRates: [SleepAnalysis.HeartRateDataPoint]

    var body: some View {
        Section {
            VStack {
                SleepSectionTitleView(
                    title: "Heart Rate",
                    symbol: .heartFill
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
