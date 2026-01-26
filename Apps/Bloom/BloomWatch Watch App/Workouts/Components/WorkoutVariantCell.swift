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

  var body: some View {
    HStack(spacing: 10) {
      WorkoutIcon(symbol: variant.symbol)

      Text(variant.name)
        .font(.title3)
        .bold()
        .fontDesign(.rounded)
        .foregroundStyle(.white)
        .multilineTextAlignment(.leading)
        .lineLimit(4)
    }
    .padding(.vertical, 20)
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
    WorkoutVariantCell(variant: .outdoorCycling)
    WorkoutVariantCell(variant: .indoorRunning)
    WorkoutVariantCell(variant: .simple(.climbing))
    WorkoutVariantCell(variant: .simple(.highIntensityIntervalTraining))
  }
  .listStyle(.carousel)
}
