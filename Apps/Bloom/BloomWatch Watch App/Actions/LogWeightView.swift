//
//  LogWeightView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-26.
//

import SwiftUI
import HealthKit
import CoreHealth
import TelemetryDeck
import BloomFoundation

struct LogWeightView: View {
  let performDismiss: (() -> Void)?

  @State private var weight: Double = 150
  @State private var isSaving = false
  @State private var unitProvider = WatchUnitPreferencesProvider.shared
  @FocusState private var isFocused: Bool

  private var isMetric: Bool { unitProvider.weightUnit == .gramUnit(with: .kilo) }
  private var step: Double { 0.1 }
  private var minWeight: Double { isMetric ? 20.0 : 50.0 }
  private var maxWeight: Double { isMetric ? 250.0 : 550.0 }
  private var unitLabel: String { isMetric ? "kg" : "lb" }

  var body: some View {
    VStack(spacing: 12) {
      Spacer()

      Text(weight.formatted(.number.precision(.fractionLength(1))))
        .font(.system(size: 40, weight: .bold, design: .rounded))
        .focusable()
        .focused($isFocused)
        .digitalCrownRotation($weight, from: minWeight, through: maxWeight, by: step, sensitivity: .low)
        .foregroundStyle(.mutedIndigo)

      Text(unitLabel)
        .font(.title3)
        .bold()
        .fontDesign(.rounded)
        .foregroundStyle(.secondary)

      Spacer()

      Button {
        Task { await save() }
      } label: {
        Text("Save")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .tint(.mutedIndigo)
      .disabled(isSaving)
    }
    .padding()
    .navigationTitle("Weight")
    .onAppear {
      unitProvider.loadFromApplicationContext()
      weight = isMetric ? 70.0 : 150.0
      isFocused = true
    }
  }
}

private extension LogWeightView {

  func save() async {
    isSaving = true
    defer { isSaving = false }

    let quantity = HKQuantity(unit: unitProvider.weightUnit, doubleValue: weight)
    let sample = HKQuantitySample(
      type: HKQuantityType(.bodyMass),
      quantity: quantity,
      start: .now,
      end: .now,
      metadata: [HKMetadataKeyWasUserEntered: true]
    )

    do {
      try await HealthStoreModifier.shared.write(sample)
      TelemetryDeck.signal("Watch Log Weight")
      performDismiss?()
    } catch {
      // Handle error silently for now
    }
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      LogWeightView(performDismiss: nil)
    }
  }
}
