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
    HStack(spacing: 10) {
      WorkoutIcon(
        symbol: variant.symbol,
        scale: .small
      )

      Text(variant.name)
        .font(.caption)
        .bold()
        .fontDesign(.rounded)
        .foregroundStyle(.white)
        .multilineTextAlignment(.leading)
        .lineLimit(4)

      Spacer(minLength: 0)

      if isPinned {
        Image(systemSymbol: .starFill)
          .font(.system(size: 10))
          .foregroundStyle(.mutedOrange)
      }
    }
    .padding(.vertical, 10)
    .foregroundStyle(.mutedGreen)
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
