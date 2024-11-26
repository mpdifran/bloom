//
//  ActionStatusCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-07.
//

import SwiftUI
import AppUI

struct ActionStatusCell: View {
    let title: String
    let systemImage: String
    let latestValue: String?
    let latestTimestamp: String?

    var body: some View {
        HStack {

            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: systemImage)
                    Text(title)
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                }
                .font(.caption)
                .bold()
                .fontDesign(.rounded)


                Text(latestValue ?? "No Data")
                    .font(.body)
                    .fontDesign(.rounded)
                    .bold()
                    .foregroundStyle(.tint)
                    .lineLimit(1)

                Group {
                    if let latestTimestamp {
                        Text(latestTimestamp)
                    } else {
                        Text("Never")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer()

//            VStack(alignment: .trailing) {
//                Image(systemName: "plus.circle.fill")
//                    .foregroundStyle(.tint, .tint.tertiary)
//                    .bold()
//                    .font(.title)
//            }
        }
        .cardContainer(fill: .tint.quinary, stroke: .tint.quaternary)
    }
}

#Preview {
    ScrollView {
        VStack {
            HStack {
                ActionStatusCell(
                    title: "Log Weight",
                    systemImage: "gauge.with.dots.needle.bottom.50percent.badge.plus",
                    latestValue: "159.2 lbs",
                    latestTimestamp: "Today"
                )
                .tint(.mutedIndigo)
                ActionStatusCell(
                    title: "Log Blood Pressure",
                    systemImage: "gauge.open.with.lines.needle.67percent.and.arrowtriangle",
                    latestValue: "120/80",
                    latestTimestamp: "Today"
                )
                .tint(.mutedPink)
            }
            HStack {
                ActionStatusCell(
                    title: "Log Water",
                    systemImage: "waterbottle.fill",
                    latestValue: "500 mL",
                    latestTimestamp: "Today"
                )
                .tint(.mutedBlue)
                Spacer()
            }
        }
        .horizontallyCentered()
        .padding()
    }
}
