//
//  DrinkAmountSelectionView.swift
//  Bloom
//
//  Created by Claude on 2026-01-23.
//

import SwiftUI
import SFSafeSymbols
import BloomUI
import AppUI

struct DrinkAmountSelectionView: View {
  let drink: DrinkType
  let container: ContainerSizeModel
  let namespace: Namespace.ID
  let onTrack: (Double) -> Void

  @State private var fillPercentage: Double = 1.0

  private var effectiveAmountML: Double {
    container.volumeML * fillPercentage
  }

  private var hydratedAmountML: Double {
    effectiveAmountML * drink.hydrationCoefficient
  }

  var body: some View {
    VStack(spacing: 20) {
      // Subtitle
      Text("How much did you drink?")
        .font(.subheadline)
        .foregroundStyle(.secondary)

      Spacer()

      // Fill container
      DrinkFillContainerView(
        drink: drink,
        container: container,
        fillPercentage: $fillPercentage
      )
      .matchedGeometryEffect(id: "container-\(container.id)", in: namespace)
      .frame(width: 160, height: 260)

      Spacer()

      // Amount display
      amountDisplay

      Spacer()

      // Track button
      trackButton
    }
    .padding()
    .sensoryFeedback(.selection, trigger: container.id)
  }

  private var amountDisplay: some View {
    VStack(spacing: 4) {
      // Main amount
      HStack(alignment: .firstTextBaseline, spacing: 4) {
        Text("\(Int(effectiveAmountML))")
          .font(.system(size: 48, weight: .heavy, design: .rounded))
          .foregroundStyle(drink.liquidColor)

        Text("mL")
          .font(.title2)
          .fontWeight(.medium)
          .foregroundStyle(.secondary)
      }

      // Hydration info for alcoholic drinks
      if drink.hydrationCoefficient < 1.0 {
        Text("≈ \(Int(hydratedAmountML)) mL hydration")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      // Caffeine info
      if let caffeine = drink.caffeineContent(forML: effectiveAmountML), caffeine > 0 {
        Text("+ \(Int(caffeine)) mg caffeine")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
  }

  private var trackButton: some View {
    Button {
      onTrack(effectiveAmountML)
    } label: {
      HStack {
        Image(systemSymbol: .checkmarkCircleFill)
        Text("Track \(drink.name)")
      }
      .font(.headline)
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 16)
      .background {
        RoundedRectangle(cornerRadius: 16)
          .fill(drink.liquidColor)
      }
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  @Previewable @Namespace var namespace

  DrinkAmountSelectionView(
    drink: DrinkType.defaultDrinks.first!,
    container: ContainerSizeModel.defaults[2],
    namespace: namespace,
    onTrack: { amount in
      print("Track: \(amount) mL")
    }
  )
  .tint(.blue)
}
