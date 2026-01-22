//
//  SleepRespiratoryRateSummaryCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-06.
//

import SFSafeSymbols
import SwiftUI
import CoreHealth

struct SleepRespiratoryRateSummaryCell: View {
  let respiratoryRates: [SleepAnalysis.RespiratoryRateDataPoint]

  var body: some View {
    VStack {
      SleepSectionTitleView(
        title: "Respiratory Rate",
        symbol: .lungsFill
      )
      .padding(.top)
      .padding(.horizontal)

      SleepRespiratoryRateChartView(respiratoryRates: respiratoryRates)
        .frame(height: 180)
        .padding(.trailing)
    }
    .cardContainer(includePadding: false)
    .tint(.mutedLightBlue)
  }
}

#Preview {
  List {
    SleepRespiratoryRateSummaryCell(
      respiratoryRates: SleepAnalysis.RespiratoryRateDataPoint.previewData
    )
  }
}
