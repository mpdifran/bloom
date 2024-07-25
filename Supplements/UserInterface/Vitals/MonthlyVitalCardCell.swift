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
        VStack {
            HStack(alignment: .top) {
                Label(title, systemImage: systemImage)
                    .bold()
                    .font(.title3)

                Spacer()

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
                .font(.largeTitle)
            }

            Spacer()

            HStack(alignment: .bottom) {
                Text(subtitleText)
                    .font(.body)
                    .bold()
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(metricValue)
                    .font(.title2)
                    .bold()
                    .fontDesign(.rounded)
                    .foregroundStyle(.tint)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 20)
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
