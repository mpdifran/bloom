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
                .fontDesign(.rounded)
                .frame(width: 40)

            VStack(alignment: .leading) {
                Text(vital.id.name)
                    .bold()
                    .font(.headline)
                    .fontDesign(.rounded)

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
                    color: .vitalWarning,
                    barLevel: .init(level: .medium, proportion: 1),
                    hasNoData: false
                )
            )

            MonthlyVitalCardCell(
                vital: .init(
                    id: .sleepQuality,
                    subtitle: "45% Core\n12% Deep",
                    status: "Good",
                    color: .vitalGreat,
                    barLevel: .init(level: .optimal, proportion: 0.9),
                    hasNoData: false
                )
            )

            MonthlyVitalCardCell(
                vital: .init(
                    id: .activityLevel,
                    subtitle: "1700 Cal Basal\n451 Cal Active",
                    status: "Light",
                    color: .vitalGood,
                    barLevel: .init(level: .high, proportion: 0.6),
                    hasNoData: false
                )
            )

            MonthlyVitalCardCell(
                vital: .init(
                    id: .bowelMovements,
                    subtitle: "Once a Day",
                    status: "Irregular",
                    color: .vitalSevere,
                    barLevel: .init(level: .low, proportion: 0.4),
                    hasNoData: false
                )
            )
        }
        .padding()
    }
    .gradientRootBackground()
}
