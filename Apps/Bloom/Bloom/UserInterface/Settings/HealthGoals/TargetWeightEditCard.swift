//
//  TargetWeightEditCard.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-07.
//

import SwiftUI
import HealthKit

struct TargetWeightEditCard: View {

  @State private var weight: Double

  init() {
    let weightQuantity = HKQuantity(unit: .pound(), doubleValue: HealthManager.shared.targetWeight)
    self._weight = State(initialValue: weightQuantity.localizedValue(for: .pound()))
  }

  @FocusState private var isFocused: Bool
  @ObservedObject private var healthManager = HealthManager.shared
  @Bindable private var unitPreferences = HealthUnitPreferences.shared

  var body: some View {
    CardView {
      LargeTitleActionCard("Target Weight") {
        HealthActionCardView {
          saveTargetWeight()
        } content: { _, handleSave in
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
            .cardContainer()
            .fontDesign(.rounded)
            .keyboardType(.decimalPad)
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

private extension TargetWeightEditCard {

  func saveTargetWeight() -> Bool {
    let quantity = HKQuantity(unit: unitPreferences.weightUnit, doubleValue: weight)
    HealthManager.shared.targetWeight = quantity.doubleValue(for: .pound())
    return true
  }
}

#Preview {
  PreviewSheetPresent {
    TargetWeightEditCard()
  }
}
