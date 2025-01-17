//
//  BodyWeightActionCardView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-04.
//

import SwiftUI
@preconcurrency import HealthKit
import TelemetryDeck

struct BodyWeightActionCardView: View {

  @State private var weight: Double = 0

  @State private var didError = false
  @State private var error: Error?

  @FocusState private var isFocused: Bool
  @ObservedObject private var healthManager = HealthManager.shared

  @Bindable private var unitPreferences = HealthUnitPreferences.shared

  var body: some View {
    InsetCardView {
      LargeTitleActionCard("Log Weight") {
        HealthActionCardView(
          sampleTypes: [HKQuantityType(.bodyMass)]
        ) {
          try await logWeight()
        } content: { (_, handleSave) in
          VStack {
            HStack {
              Text("Weight")

              Spacer()

              TextField("", value: $weight, formatter: NumberFormatter.oneDecimalPlace)
                .selectAllTextOnBeginEditing()
                .focused($isFocused)
                .frame(width: 140)

              LocalizedUnitPickerView(unit: $unitPreferences.weightUnit)
            }
            .horizontallyCentered()
            .cardContainer()
            .fontDesign(.rounded)
            .keyboardType(.decimalPad)
            .sensoryFeedback(.error, trigger: didError)
            .textFieldStyle(.roundedBorder)
            .bold()
            .multilineTextAlignment(.trailing)
          }
        }
      }
    }
    .tint(.mutedIndigo)
  }
}

private extension BodyWeightActionCardView {

  func logWeight() async throws -> Bool {
    let date = Date.now
    let quantity = HKQuantity(unit: unitPreferences.weightUnit, doubleValue: weight)
    let sample = HKQuantitySample(
      type: .init(.bodyMass),
      quantity: quantity,
      start: date,
      end: date,
      metadata: [
        HKMetadataKeyWasUserEntered : true
      ]
    )

    try await HealthStoreModifier.shared.write(sample: sample)
    TelemetryDeck.signal("Log Weight")

    return true
  }
}

#Preview {
  PreviewSheetPresent {
    BodyWeightActionCardView()
  }
}
