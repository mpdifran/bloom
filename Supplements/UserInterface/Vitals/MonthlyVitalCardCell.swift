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
    let vital: VitalModel

    var body: some View {
        HStack {
            Image(systemName: vital.id.systemImage)
                .bold()
                .font(.title)

            VStack(alignment: .leading) {
                Text(vital.id.name)
                    .bold()
                    .font(.headline)

                Text(vital.subtitle)
                    .font(.subheadline)
                    .bold()
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Group {
                    switch vital.trend {
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

                Text(vital.status)
                    .font(.headline)
                    .bold()
                    .fontDesign(.rounded)
                    .foregroundStyle(.tint)
            }
        }
        .tint(vital.color)
        .cardContainer()
    }
}

#Preview {
    ScrollView {
        VStack {
            MonthlyVitalCardCell(
                vital: .init(
                    id: .activityLevel,
                    subtitle: "Basal: 1756 Cal\nActive: 642 Cal",
                    status: "Moderate",
                    color: .yellow,
                    trend: .increasing
                )
            )

            MonthlyVitalCardCell(
                vital: .init(
                    id: .sleepQuality,
                    subtitle: "45% Core\n12% Deep",
                    status: "Good",
                    color: .coreSleep,
                    trend: .decreasing
                )
            )

            MonthlyVitalCardCell(
                vital: .init(
                    id: .activityLevel,
                    subtitle: "1700 Cal Basal\n451 Cal Active",
                    status: "Light",
                    color: .green,
                    trend: .noTrend
                )
            )
        }
        .padding()
    }
    .background {
        Rectangle()
            .fill(.background.secondary)
            .ignoresSafeArea()
    }
}
