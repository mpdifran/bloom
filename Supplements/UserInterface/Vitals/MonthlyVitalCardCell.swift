//
//  MonthlyVitalCardCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-24.
//

import SwiftUI

extension MonthlyVitalCardCell {
    enum Trend {
        case increasing
        case decreasing
        case noTrend
    }
}

struct MonthlyVitalCardCell: View {
    let title: String
    let systemImage: String
    let subtitleText: String
    let metricValue: String
    let trend: Trend

    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .bold()
                .font(.title)

            VStack(alignment: .leading) {
                Text(title)
                    .bold()
                    .font(.headline)

                Text(subtitleText)
                    .font(.subheadline)
                    .bold()
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Group {
                    switch trend {
                    case .increasing:
                        Image(systemName: "chevron.up.circle")
                    case .decreasing:
                        Image(systemName: "chevron.down.circle")
                    case .noTrend:
                        Image(systemName: "minus.circle")
                            .foregroundStyle(.primary, .fill)
                    }
                }
                .foregroundStyle(.primary, .tint)
                .font(.title)

                Spacer()

                Text(metricValue)
                    .font(.subheadline)
                    .bold()
                    .fontDesign(.rounded)
                    .foregroundStyle(.tint)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 30)
                .fill(.background)
        }
    }
}

#Preview {
    ScrollView {
        VStack {
            MonthlyVitalCardCell(
                title: "Activity Level",
                systemImage: "figure.run",
                subtitleText: "Basal: 1756 Cal\nActive: 642 Cal",
                metricValue: "Moderate",
                trend: .increasing
            )
            .tint(.green)

            MonthlyVitalCardCell(
                title: "Sleep Quality",
                systemImage: "moon.zzz.fill",
                subtitleText: "45% Core\n12% Deep",
                metricValue: "Good",
                trend: .decreasing
            )
            .tint(.coreSleep)

            MonthlyVitalCardCell(
                title: "Activity",
                systemImage: "figure.run",
                subtitleText: "1700 Cal Basal\n451 Cal Active",
                metricValue: "Light",
                trend: .noTrend
            )
            .tint(.coreSleep)
        }
        .padding()
    }
    .background {
        Rectangle()
            .fill(.background.secondary)
            .ignoresSafeArea()
    }
}
