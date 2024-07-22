//
//  VitalStatusCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-22.
//

import SwiftUI

extension VitalStatusCell {
    enum Mode: Hashable {
        case insufficientData
        case threat
        case warning
        case good
        case excel
    }
}

private extension VitalStatusCell.Mode {

    var systemImage: String {
        switch self {
        case .insufficientData: "questionmark.diamond.fill"
        case .threat: "exclamationmark.octagon.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .good: "checkmark.circle.fill"
        case .excel: "checkmark.seal.fill"
        }
    }

    var color: Color {
        switch self {
        case .insufficientData: .gray
        case .threat: .pink
        case .warning: .yellow
        case .good: .green
        case .excel: .coreSleep
        }
    }
}

struct VitalStatusCell: View {
    let title: String
    let statusValue: String
    let mode: Mode

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
