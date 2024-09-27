//
//  MonthlyVitalCardCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-24.
//

import SwiftUI
import DataContainer

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

                if let barLevel = vital.barLevel {
                    VitalStatusBarView(
                        level: .init(barLevel: barLevel.level),
                        levelPercent: barLevel.proportion
                    )
                }

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
                    barLevel: .init(level: .medium, proportion: 1)
                )
            )

            MonthlyVitalCardCell(
                vital: .init(
                    id: .sleepQuality,
                    subtitle: "45% Core\n12% Deep",
                    status: "Good",
                    score: 0.7,
                    color: .vitalGreat,
                    barLevel: .init(level: .optimal, proportion: 0.9)
                )
            )

            MonthlyVitalCardCell(
                vital: .init(
                    id: .activityLevel,
                    subtitle: "1700 Cal Basal\n451 Cal Active",
                    status: "Light",
                    score: 0.7,
                    color: .vitalGood,
                    barLevel: .init(level: .high, proportion: 0.6)
                )
            )

            MonthlyVitalCardCell(
                vital: .init(
                    id: .bowelMovements,
                    subtitle: "Once a Day",
                    status: "Irregular",
                    score: 0.1,
                    color: .vitalSevere,
                    barLevel: .init(level: .low, proportion: 0.4)
                )
            )
        }
        .padding()
    }
    .gradientRootBackground()
}
