//
//  WorkoutVariantCell.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2025-05-05.
//

import SwiftUI
import HealthKit
import CoreHealth
import SFSafeSymbols
import BloomFoundation

struct WorkoutVariantCell: View {
  let variant: WorkoutVariant
  var isPinned: Bool = false

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .top) {
        WorkoutIcon(
          symbol: variant.symbol,
          scale: .small
        )

        Spacer()

        if isPinned {
          Image(systemSymbol: .starFill)
            .font(.system(size: 10))
            .foregroundStyle(.mutedOrange)
        }
      }

      Text(variant.name)
        .font(.title3)
        .bold()
        .fontDesign(.rounded)
        .foregroundStyle(.white)
        .multilineTextAlignment(.leading)
        .lineLimit(4)
    }
    .padding(.vertical, 16)
    .foregroundStyle(.mutedBlue)
    .listRowBackground(
      RoundedRectangle(cornerRadius: 24)
        .fill(.blue.tertiary)
    )
    .selectable()
  }
}

private extension WorkoutVariantCell {

  var listRowBackground: some View {
    RoundedRectangle(cornerRadius: 20)
      .fill(.background.secondary)
  }
}

#Preview {
  List {
    WorkoutVariantCell(variant: .outdoorCycling, isPinned: true)
    WorkoutVariantCell(variant: .indoorRunning)
    WorkoutVariantCell(variant: .simple(.climbing), isPinned: true)
    WorkoutVariantCell(variant: .simple(.highIntensityIntervalTraining))
  }
  .listStyle(.carousel)
}
