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

    @AppStorage("PreferencesView.danieleMode") private var danieleMode = false

    var body: some View {
        HStack {
            Image(systemName: vital.id.systemImage)
                .bold()
                .font(.title)
                .frame(width: 40)

            VStack(alignment: .leading) {
                Text(vital.id.name)
                    .bold()
                    .font(.headline)

                Text(vital.subtitle)
                    .font(.subheadline)
                    .bold()
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.interpolate)
            }

            Spacer()

            VStack(alignment: .trailing) {
//                Group {
//                    switch vital.trend {
//                    case .increasing:
//                        Image(systemName: "chevron.up.circle.fill")
//                    case .decreasing:
//                        Image(systemName: "chevron.down.circle.fill")
//                    case .noTrend:
//                        Image(systemName: "minus.circle.fill")
//                            .foregroundStyle(.fill, .fill.secondary)
//                    }
//                }
//                .foregroundStyle(.tint, .tint.tertiary)
//                .font(.title)
//                .contentTransition(.symbolEffect)
//
//                Spacer()

                Text(vital.status)
                    .font(.headline)
                    .bold()
                    .fontDesign(.rounded)
                    .foregroundStyle(.tint)
                    .contentTransition(.interpolate)

                if danieleMode {
                    Text(vital.score.format(using: .twoDecimalPlaces))
                        .font(.subheadline)
                        .fontDesign(.rounded)
                        .foregroundStyle(.tint)
                        .contentTransition(.interpolate)
                }
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
                    score: 0.7,
                    color: .vitalWarning,
                    trend: .increasing
                )
            )

            MonthlyVitalCardCell(
                vital: .init(
                    id: .sleepQuality,
                    subtitle: "45% Core\n12% Deep",
                    status: "Good",
                    score: 0.7,
                    color: .vitalGreat,
                    trend: .decreasing
                )
            )

            MonthlyVitalCardCell(
                vital: .init(
                    id: .activityLevel,
                    subtitle: "1700 Cal Basal\n451 Cal Active",
                    status: "Light",
                    score: 0.7,
                    color: .vitalGood,
                    trend: .noTrend
                )
            )

            MonthlyVitalCardCell(
                vital: .init(
                    id: .bowelMovements,
                    subtitle: "Once a Day",
                    status: "Irregular",
                    score: 0.1,
                    color: .vitalSevere,
                    trend: .increasing
                )
            )
        }
        .padding()
    }
    .gradientRootBackground()
}
