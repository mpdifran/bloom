//
//  BloodPressureActionCardView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-27.
//

import SwiftUI
import AppUI
@preconcurrency import HealthKit
import TelemetryDeck

extension BloodPressureActionCardView {
  enum FocusedTextField {
    case systolic
    case diastolic
  }
}

struct BloodPressureActionCardView: View {

  let performDismiss: (() -> Void)?

  init(performDismiss: (() -> Void)?) {
    self.performDismiss = performDismiss
  }

  @State private var systolic: Double = 120
  @State private var diastolic: Double = 80
  @State private var didError = false
  @State private var error: Error?

  @FocusState private var focusedTextField: FocusedTextField?
  @ObservedObject private var healthManager = HealthManager.shared

  @Environment(\.requestReview) private var requestReview

  var body: some View {
    CardView {
      LargeTitleActionCard("Log Blood Pressure") {
        HealthActionCardView(
          sampleTypes: [
            HKQuantityType(.bloodPressureSystolic),
            HKQuantityType(.bloodPressureDiastolic)
          ],
          performDismiss: performDismiss
        ) {
          try await logBloodPressure()
        } content: { (_, handleSave) in
          VStack {
            HStack {
              Text("Systolic")
              Spacer()
              TextField("", value: $systolic, formatter: NumberFormatter.noDecimalPlaces)
                .frame(width: 80)
                .fontDesign(.rounded)
                .keyboardType(.numberPad)
                .focused($focusedTextField, equals: .systolic)
                .selectAllTextOnBeginEditing()
            }

            Divider()

            HStack {
              Text("Diastolic")
              Spacer()
              TextField("", value: $diastolic, formatter: NumberFormatter.noDecimalPlaces)
                .frame(width: 80)
                .fontDesign(.rounded)
                .keyboardType(.numberPad)
                .focused($focusedTextField, equals: .diastolic)
                .selectAllTextOnBeginEditing()
            }
          }
          .cardContainer()
          .sensoryFeedback(.error, trigger: didError)
          .textFieldStyle(.roundedBorder)
          .fontDesign(.rounded)
          .bold()
          .multilineTextAlignment(.trailing)
        }
      }
    }
    .tint(.mutedPink)
  }
}

private extension BloodPressureActionCardView {

  func logBloodPressure() async throws -> Bool {
    let systolicQuantity = HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: systolic)
    let diastolicQuantity = HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: diastolic)

    let systolicSample = HKQuantitySample(
      type: HKQuantityType(.bloodPressureSystolic),
      quantity: systolicQuantity,
      start: .now,
      end: .now,
      metadata: [
        HKMetadataKeyWasUserEntered : true
      ]
    )
    let diastolicSample = HKQuantitySample(
      type: HKQuantityType(.bloodPressureDiastolic),
      quantity: diastolicQuantity,
      start: .now,
      end: .now,
      metadata: [
        HKMetadataKeyWasUserEntered : true
      ]
    )

    try await HealthStoreModifier.shared.write([systolicSample, diastolicSample])
    TelemetryDeck.signal("Log Blood Pressure")

    if RatingPromptTracker.shared.recordEvent() {
      requestReview()
    }

    return true
  }
}

#Preview {
  PreviewSheetPresent {
    BloodPressureActionCardView(performDismiss: nil)
  }
}
