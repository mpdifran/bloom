//
//  LogBloodPressureView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-27.
//

import SwiftUI
import HealthKit
import CoreHealth
import TelemetryDeck
import BloomFoundation

struct LogBloodPressureView: View {
  let performDismiss: (() -> Void)?

  @State private var systolic: Double = 120
  @State private var diastolic: Double = 80
  @State private var isSaving = false
  @State private var showingSaveConfirmation = false
  @FocusState private var focusedField: Field?

  private enum Field: Hashable {
    case systolic
    case diastolic
  }

  var body: some View {
    VStack(spacing: 8) {
      Spacer()

      bloodPressureDisplay

      Spacer()

      Button {
        Task { await save() }
      } label: {
        Text("Save")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .tint(.mutedPink)
      .disabled(isSaving)
    }
    .padding()
    .navigationTitle("Blood Pressure")
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
      await loadLatestReading()
      focusedField = .systolic
    }
  }
}

// MARK: - Blood Pressure Display

private extension LogBloodPressureView {

  var bloodPressureDisplay: some View {
    VStack(spacing: 4) {
      HStack(alignment: .firstTextBaseline, spacing: 4) {
        Text(Int(systolic).description)
          .font(.system(size: 36, weight: .bold, design: .rounded))
          .focusable()
          .focused($focusedField, equals: .systolic)
          .digitalCrownRotation($systolic, from: 60, through: 250, by: 1, sensitivity: .low)
          .foregroundStyle(focusedField == .systolic ? .mutedPink : .secondary)

        Text(verbatim: "/")
          .font(.system(size: 28, weight: .bold, design: .rounded))
          .foregroundStyle(.secondary)

        Text(Int(diastolic).description)
          .font(.system(size: 36, weight: .bold, design: .rounded))
          .focusable()
          .focused($focusedField, equals: .diastolic)
          .digitalCrownRotation($diastolic, from: 40, through: 150, by: 1, sensitivity: .low)
          .foregroundStyle(focusedField == .diastolic ? .mutedPink : .secondary)
      }

      Text("mmHg")
        .font(.caption)
        .bold()
        .fontDesign(.rounded)
        .foregroundStyle(.secondary)

      Text(focusedField == .systolic ? "Systolic" : "Diastolic")
        .font(.caption2)
        .foregroundStyle(.tertiary)
        .padding(.top, 4)
    }
  }
}

// MARK: - Data Loading

private extension LogBloodPressureView {

  func loadLatestReading() async {
    async let systolicSample = HealthStoreFetcher.shared.fetchLatestSample(for: .bloodPressureSystolic)
    async let diastolicSample = HealthStoreFetcher.shared.fetchLatestSample(for: .bloodPressureDiastolic)

    let (systolicResult, diastolicResult) = await (systolicSample, diastolicSample)

    if let systolicResult {
      systolic = systolicResult.quantity.doubleValue(for: .millimeterOfMercury())
    }
    if let diastolicResult {
      diastolic = diastolicResult.quantity.doubleValue(for: .millimeterOfMercury())
    }
  }
}

// MARK: - Save

private extension LogBloodPressureView {

  func save() async {
    isSaving = true

    let systolicQuantity = HKQuantity(unit: .millimeterOfMercury(), doubleValue: systolic)
    let diastolicQuantity = HKQuantity(unit: .millimeterOfMercury(), doubleValue: diastolic)

    let now = Date.now
    let metadata: [String: Any] = [HKMetadataKeyWasUserEntered: true]

    let systolicSample = HKQuantitySample(
      type: HKQuantityType(.bloodPressureSystolic),
      quantity: systolicQuantity,
      start: now,
      end: now,
      metadata: metadata
    )

    let diastolicSample = HKQuantitySample(
      type: HKQuantityType(.bloodPressureDiastolic),
      quantity: diastolicQuantity,
      start: now,
      end: now,
      metadata: metadata
    )

    do {
      try await HealthStoreModifier.shared.write(systolicSample)
      try await HealthStoreModifier.shared.write(diastolicSample)

      isSaving = false
      SoundPlayer.playLogHealthData()
      TelemetryDeck.signal("Watch Log Blood Pressure")

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

private extension LogBloodPressureView {

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
      LogBloodPressureView(performDismiss: nil)
    }
  }
}
