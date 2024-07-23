//
//  VitalStatusCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-22.
//

import SwiftUI

struct VitalStatusCell: View {
    let title: String
    let statusValue: String
    let mode: VitalStatusData.Mode

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: mode.systemImage)
                    .foregroundStyle(.white, mode.color)
                    .font(.headline)
                    .fontDesign(.rounded)
                    .bold()

                VStack(alignment: .leading) {
                    Text(title)
                        .lineLimit(1)
                        .font(.headline)
                        .fontDesign(.rounded)
                        .bold()
                }

                Spacer(minLength: 0)

                Text(statusValue)
                    .font(.title2)
                    .fontDesign(.rounded)
                    .bold()
                    .foregroundStyle(mode.color)
            }
        }
    }
}

#Preview {
    List {
        VitalStatusCell(
            title: "Heart Rate Variability",
            statusValue: "35 ms",
            mode: .threat
        )

        VitalStatusCell(
            title: "Sleep Quality",
            statusValue: "Low",
            mode: .warning
        )

        VitalStatusCell(
            title: "Resting Heart Rate",
            statusValue: "59 bpm",
            mode: .excel
        )

        VitalStatusCell(
            title: "Resting Heart Rate",
            statusValue: "63 bpm",
            mode: .good
        )

        VitalStatusCell(
            title: "Sleep Quality",
            statusValue: "No Data",
            mode: .insufficientData
        )
    }
}
