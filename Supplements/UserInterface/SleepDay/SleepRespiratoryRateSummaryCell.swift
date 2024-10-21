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
                SleepSectionTitleView(
                    title: "Respiratory Rate",
                    systemImage: "lungs.fill"
                )

                SleepRespiratoryRateChartView(respiratoryRates: respiratoryRates)
                    .frame(height: 120)
            }
            .padding(.bottom)
        }
        .tint(.mutedTeal)
    }
}

#Preview {
    List {
        SleepRespiratoryRateSummaryCell(
            respiratoryRates: SleepAnalysis.RespiratoryRateDataPoint.previewData
        )
    }
}
