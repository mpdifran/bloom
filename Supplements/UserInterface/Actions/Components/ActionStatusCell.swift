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
                }
                .bold()
                .fontDesign(.rounded)
                .padding(.bottom, 6)

                Text(latestValue ?? "No Data")
                    .font(.title)
                    .fontDesign(.rounded)
                    .bold()
                    .foregroundStyle(.tint)

                Group {
                    if let latestTimestamp {
                        Text(latestTimestamp)
                    } else {
                        Text("Never")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Image(systemName: "plus")
                    .foregroundStyle(.tint)
                    .bold()
                    .padding()
                    .background {
                        Circle()
                            .fill(.tint.tertiary)
                    }
            }
        }
        .cardContainer()
    }
}

#Preview {
    ScrollView {
        VStack {
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
            ActionStatusCell(
                title: "Log Water",
                systemImage: "waterbottle.fill",
                latestValue: "500 mL",
                latestTimestamp: "Today"
            )
            .tint(.mutedBlue)
        }
        .horizontallyCentered()
        .padding()
    }
    .gradientRootBackground()
}
