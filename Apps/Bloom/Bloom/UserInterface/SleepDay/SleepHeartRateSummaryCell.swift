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
    VStack {
      SleepSectionTitleView(
        title: "Heart Rate",
        symbol: .heartFill
      )

      SleepHeartRateChartView(heartRates: heartRates)
        .frame(height: 180)
    }
    .cardContainer()
    .tint(.mutedRed)
  }
}

#Preview {
  List {
    SleepHeartRateSummaryCell(
      heartRates: SleepAnalysis.HeartRateDataPoint.previewData
    )
  }
}
