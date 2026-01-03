//
//  BowelMovementsStoolTypeStatCard.swift
//  Bloom
//
//  Created by Assistant on 2025-01-02.
//

import SwiftUI
import SFSafeSymbols
import CoreHealth

struct BowelMovementsStoolTypeStatCard: View {
  let summary: BowelMovementMonthlySummary?

  private var typeCounts: [Int] {
    guard let summary else { return Array(repeating: 0, count: 7) }
    return (1...7).map { type in
      summary.stoolTypeDistribution[type]?.count ?? 0
    }
  }

  private var mostCommonType: Int? {
    guard let summary, !summary.bowelMovements.isEmpty else { return nil }
    return summary.stoolTypeDistribution
      .max(by: { $0.value.count < $1.value.count })?
      .key
  }

  private func color(for bristolStoolType: Int) -> Color {
    switch bristolStoolType {
    case 7: .vitalSevere
    case 1, 6: .vitalWarning
    case 2, 5: .vitalGood
    case 3, 4: .vitalGreat
    default: .brown
    }
  }

  var body: some View {
    if let mostCommon = mostCommonType {
      StatCard(
        symbol: .listBulletCircleFill,
        title: "Stool Type",
        value: "Type \(mostCommon)",
        valueStyle: .largeTinted("Last 7 Days")
      ) {
        barChart
      }
      .tint(color(for: mostCommon))
    } else {
      StatCard(
        symbol: .listBulletCircleFill,
        title: "Stool Type",
        value: "No Data",
        valueStyle: .largeTinted(nil)
      )
    }
  }
}

private extension BowelMovementsStoolTypeStatCard {

  @ViewBuilder
  var barChart: some View {
    let counts = typeCounts
    let maxCount = counts.max() ?? 1

    if maxCount > 0 {
      VStack(spacing: 2) {
        GeometryReader { geometry in
          HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<7, id: \.self) { index in
              let count = counts[index]
              let height = maxCount > 0 ? (Double(count) / Double(maxCount)) * geometry.size.height : 0
              let stoolType = index + 1

              RoundedRectangle(cornerRadius: 2)
                .fill(color(for: stoolType))
                .frame(height: max(height, count > 0 ? 4 : 2))
                .opacity(count > 0 ? 1 : 0.3)
            }
          }
        }

        HStack(spacing: 2) {
          ForEach(1...7, id: \.self) { stoolType in
            Text("\(stoolType)")
              .font(.caption2)
              .foregroundStyle(.secondary)
              .frame(maxWidth: .infinity)
          }
        }
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HStack {
        BowelMovementsStoolTypeStatCard(summary: nil)
        BowelMovementsStoolTypeStatCard(summary: nil)
      }
    }
  }
}
