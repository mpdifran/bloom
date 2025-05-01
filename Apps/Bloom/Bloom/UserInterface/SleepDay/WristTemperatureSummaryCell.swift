//
//  WristTemperatureSummaryCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-08.
//

import SFSafeSymbols
import SwiftUI
import CoreHealth

struct WristTemperatureSummaryCell: View {
    let wristTemperature: SleepAnalysis.WristTemperatureDataPoint

    var body: some View {
        Section {
            VStack {
                SleepSectionTitleView(
                    title: "Wrist Temperature",
                    symbol: .thermometerMedium
                )

                HStack {
                    Spacer()

                    Text("\(wristTemperature.averageWristTemperature.format())°F")
                        .font(.system(size: 60))
                        .fontDesign(.rounded)
                        .bold()
                        .foregroundStyle(.tint)
                }
            }
            .padding(.bottom)
        }
        .tint(.mutedIndigo)
    }
}

#Preview {
    WristTemperatureSummaryCell(
        wristTemperature: SleepAnalysis.WristTemperatureDataPoint.previewData
    )
}
