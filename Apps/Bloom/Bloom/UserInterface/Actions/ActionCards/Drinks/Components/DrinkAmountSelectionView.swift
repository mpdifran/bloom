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
import CoreHealth
import HealthKit

struct DrinkAmountSelectionView: View {
  let drink: DrinkType
  let container: ContainerSizeModel
  let namespace: Namespace.ID
  let onTrack: (Double) -> Void

  @State private var fillPercentage: Double = 1.0
  @Bindable private var unitPreferences = HealthUnitPreferences.shared

  private var effectiveAmountML: Double {
    container.volumeML * fillPercentage
  }

  private var hydratedAmountML: Double {
    effectiveAmountML * drink.hydrationCoefficient
  }
  
  // Unit conversion helpers
  private var userLiquidUnit: HKUnit {
    unitPreferences.liquidVolumeUnit
  }
  
  private var effectiveAmountInUserUnit: Double {
    let mlQuantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: effectiveAmountML)
    return mlQuantity.doubleValue(for: userLiquidUnit)
  }
  
  private var hydratedAmountInUserUnit: Double {
    let mlQuantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: hydratedAmountML)
    return mlQuantity.doubleValue(for: userLiquidUnit)
  }
  
  private var userUnitString: String {
    userLiquidUnit.sensibleUnitString
  }
  
  private func formatAmount(_ amount: Double) -> String {
    // Use appropriate precision based on unit
    if userLiquidUnit == .literUnit(with: .milli) {
      // mL - show as integer
      return "\(Int(amount))"
    } else if userLiquidUnit == .fluidOunceUS() {
      // fl oz - show 1 decimal place for small amounts, integer for larger
      if amount < 10 {
        return amount.formatted(.number.precision(.fractionLength(1)))
      } else {
        return "\(Int(amount))"
      }
    } else if userLiquidUnit == .liter() {
      // Liters - show 1-2 decimal places
      return amount.formatted(.number.precision(.fractionLength(1)))
    } else {
      // Default - show 1 decimal place
      return amount.formatted(.number.precision(.fractionLength(1)))
    }
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
        Text(formatAmount(effectiveAmountInUserUnit))
          .font(.system(size: 48, weight: .heavy, design: .rounded))
          .foregroundStyle(drink.liquidColor)

        Text(userUnitString)
          .font(.title2)
          .fontWeight(.medium)
          .foregroundStyle(.secondary)
      }

      // Hydration info for alcoholic drinks
      if drink.hydrationCoefficient < 1.0 {
        Text("≈ \(formatAmount(hydratedAmountInUserUnit)) \(userUnitString) hydration")
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
