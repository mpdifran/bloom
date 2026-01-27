//
//  ContainerListView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-27.
//

import SwiftUI
import HealthKit
import CoreHealth
import TelemetryDeck
import BloomFoundation

struct ContainerListView: View {
  let drink: DrinkType
  let performDismiss: (() -> Void)?

  @State private var containers = ContainerSizeModel.defaults
  @State private var isSaving = false
  @State private var showingSaveConfirmation = false
  @State private var unitProvider = WatchUnitPreferencesProvider.shared

  var body: some View {
    List {
      ForEach(containers) { container in
        ContainerCell(
          container: container,
          drinkColor: drink.liquidColor,
          useMetric: unitProvider.useMetricVolume
        )
        .onTapGesture {
          Task { await save(container: container) }
        }
      }
    }
    .listStyle(.carousel)
    .navigationTitle("Container")
    .overlay {
      if isSaving {
        savingOverlay
      } else if showingSaveConfirmation {
        saveConfirmationOverlay
      }
    }
    .task {
      unitProvider.loadFromApplicationContext()
    }
  }
}

// MARK: - Container Cell

private struct ContainerCell: View {
  let container: ContainerSizeModel
  let drinkColor: Color
  let useMetric: Bool

  var body: some View {
    HStack(spacing: 12) {
      ContainerShapeView(
        shapeType: container.shapeType,
        fillColor: drinkColor.opacity(0.3),
        strokeColor: drinkColor.opacity(0.6),
        strokeWidth: 1.5
      )
      .frame(width: 36, height: 44)

      VStack(alignment: .leading, spacing: 2) {
        Text(container.name)
          .font(.headline)
          .fontDesign(.rounded)

        Text(container.displayValue(useMetric: useMetric))
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()
    }
    .padding(.vertical, 4)
  }
}

// MARK: - Save

private extension ContainerListView {

  func save(container: ContainerSizeModel) async {
    isSaving = true

    let amountML = container.volumeML
    let hydratedAmount = amountML * drink.hydrationCoefficient

    let now = Date.now
    let metadata: [String: Any] = [HKMetadataKeyWasUserEntered: true]

    do {
      // 1. Log water/hydration
      let waterSample = HKQuantitySample(
        type: HKQuantityType(.dietaryWater),
        quantity: HKQuantity(unit: .literUnit(with: .milli), doubleValue: hydratedAmount),
        start: now,
        end: now,
        metadata: metadata
      )
      try await HealthStoreModifier.shared.write(waterSample)

      // 2. Log caffeine (for caffeinated drinks)
      if let caffeineMG = drink.caffeineContent(forML: amountML), caffeineMG > 0 {
        let caffeineSample = HKQuantitySample(
          type: HKQuantityType(.dietaryCaffeine),
          quantity: HKQuantity(unit: .gramUnit(with: .milli), doubleValue: caffeineMG),
          start: now,
          end: now,
          metadata: metadata
        )
        try await HealthStoreModifier.shared.write(caffeineSample)
      }

      // 3. Log sugar (for sugary drinks)
      if let sugarG = drink.sugarContent(forML: amountML), sugarG > 0 {
        let sugarSample = HKQuantitySample(
          type: HKQuantityType(.dietarySugar),
          quantity: HKQuantity(unit: .gram(), doubleValue: sugarG),
          start: now,
          end: now,
          metadata: metadata
        )
        try await HealthStoreModifier.shared.write(sugarSample)
      }

      // 4. Log alcoholic beverages (for alcohol category)
      if drink.category == .alcohol {
        let alcoholSample = HKQuantitySample(
          type: HKQuantityType(.numberOfAlcoholicBeverages),
          quantity: HKQuantity(unit: .count(), doubleValue: 1),
          start: now,
          end: now,
          metadata: metadata
        )
        try await HealthStoreModifier.shared.write(alcoholSample)
      }

      isSaving = false
      SoundPlayer.playLogHealthData()

      TelemetryDeck.signal("Watch Log Drink", parameters: [
        "drink_type": drink.name,
        "category": drink.category.rawValue,
        "amount_ml": String(Int(amountML))
      ])

      withAnimation {
        showingSaveConfirmation = true
      }

      try? await Task.sleep(for: .seconds(1))

      performDismiss?()
    } catch {
      isSaving = false
    }
  }
}

// MARK: - Overlays

private extension ContainerListView {

  var savingOverlay: some View {
    ProgressView()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(.ultraThinMaterial)
  }

  var saveConfirmationOverlay: some View {
    VStack {
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 50))
        .foregroundStyle(.green)

      Text("Saved")
        .font(.headline)
        .bold()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.ultraThinMaterial)
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      ContainerListView(
        drink: DrinkType.defaultDrinks.first!,
        performDismiss: nil
      )
    }
  }
}
