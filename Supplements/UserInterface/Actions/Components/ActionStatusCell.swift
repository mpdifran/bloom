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
                    .bold()
                    .padding()
                    .background {
                        Circle()
                            .fill(.thickMaterial)
                            .background {
                                Circle()
                                    .fill(.tint.opacity(0.5))
                            }
                    }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.tint.opacity(0.5))
                }

        }
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
            .tint(.indigo)
            ActionStatusCell(
                title: "Log Blood Pressure",
                systemImage: "gauge.open.with.lines.needle.67percent.and.arrowtriangle",
                latestValue: "120/80",
                latestTimestamp: "Today"
            )
            .tint(.pink)
            ActionStatusCell(
                title: "Log Water",
                systemImage: "waterbottle.fill",
                latestValue: "500 mL",
                latestTimestamp: "Today"
            )
            .tint(.blue)
        }
        .horizontallyCentered()
        .padding()
    }
    .gradientRootBackground()
}
