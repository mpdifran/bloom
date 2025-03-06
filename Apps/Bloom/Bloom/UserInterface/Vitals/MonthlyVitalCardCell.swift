//
//  MonthlyVitalCardCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-24.
//

import SFSafeSymbols
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

  @AppStorage(.FeatureFlag.danieleMode) private var danieleMode = false

  var body: some View {
    HStack {
      Image(systemSymbol: SFSymbol(rawValue: vital.id.systemImage))
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
          .fontDesign(.rounded)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
          .contentTransition(.interpolate)
      }

      Spacer()

      VStack(alignment: .trailing) {
        if let barLevel = vital.barLevel {
          VitalStatusBarView(
            level: VitalStatusBarView.Level(barLevel: barLevel.level),
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
    .cardContainer(fill: .background)
  }
}

#Preview {
  ScrollView {
    VStack {
      MonthlyVitalCardCell(
        vital: VitalModel(
          id: .activityLevel,
          subtitle: "Basal: 1756 Cal\nActive: 642 Cal",
          status: "Moderate",
          color: .vitalWarning,
          barLevel: VitalModel.BarLevel(level: .medium, proportion: 1),
          hasNoData: false
        )
      )

      MonthlyVitalCardCell(
        vital: VitalModel(
          id: .sleepQuality,
          subtitle: "45% Core\n12% Deep",
          status: "Good",
          color: .vitalGreat,
          barLevel: VitalModel.BarLevel(level: .optimal, proportion: 0.9),
          hasNoData: false
        )
      )

      MonthlyVitalCardCell(
        vital: VitalModel(
          id: .activityLevel,
          subtitle: "1700 Cal Basal\n451 Cal Active",
          status: "Light",
          color: .vitalGood,
          barLevel: VitalModel.BarLevel(level: .high, proportion: 0.6),
          hasNoData: false
        )
      )

      MonthlyVitalCardCell(
        vital: VitalModel(
          id: .bowelMovements,
          subtitle: "Once a Day",
          status: "Irregular",
          color: .vitalSevere,
          barLevel: VitalModel.BarLevel(level: .low, proportion: 0.4),
          hasNoData: false
        )
      )
    }
    .padding()
  }
}
