//
//  SleepRespiratoryRateSummaryCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-06.
//

import SwiftUI

struct SleepRespiratoryRateSummaryCell: View {
    let respiratoryRates: [SleepAnalysis.RespiratoryRateDataPoint]

    var body: some View {
        Section {
            VStack {
                TodaySectionTitleView(
                    title: "Respiratory Rate",
                    systemImage: "lungs.fill"
                )

                SleepRespiratoryRateChartView(respiratoryRates: respiratoryRates)
                    .frame(height: 120)
            }
            .padding(.bottom)
        }
        .tint(.teal)
    }
}

#Preview {
    List {
        SleepRespiratoryRateSummaryCell(
            respiratoryRates: SleepAnalysis.RespiratoryRateDataPoint.previewData
        )
    }
}
