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
  @State private var showingSaveConfirmation = false
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
    .frame(maxWidth: .infinity)
    .background(.black)
    .overlay {
      if isSaving {
        savingOverlay
      } else if showingSaveConfirmation {
        saveConfirmationOverlay
      }
    }
    .task {
      unitProvider.loadFromApplicationContext()

      if let sample = await HealthStoreFetcher.shared.fetchLatestSample(for: .bodyMass) {
        weight = sample.quantity.doubleValue(for: unitProvider.weightUnit)
      } else {
        weight = isMetric ? 70.0 : 150.0
      }

      isFocused = true
    }
  }
}

private extension LogWeightView {

  func save() async {
    isSaving = true

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
      isSaving = false
      SoundPlayer.playLogHealthData()
      TelemetryDeck.signal("Watch Log Weight")

      withAnimation {
        showingSaveConfirmation = true
      }

      try? await Task.sleep(for: .seconds(1))

      performDismiss?()
    } catch {
      isSaving = false
      // Handle error silently for now
    }
  }
}

// MARK: - Overlays

private extension LogWeightView {

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
      LogWeightView(performDismiss: nil)
    }
  }
}
