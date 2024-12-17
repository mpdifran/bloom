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
    ActionCardView(
      title: "Target Weight",
      performDismiss: nil
    ) {
      saveTargetWeight()
    } content: { (_, handleSave) in
      VStack {
        Spacer()

        HStack {
          TextField("", value: $weight, formatter: NumberFormatter.oneDecimalPlace)
            .selectAllTextOnBeginEditing()
            .focused($isFocused)

          Menu {
            ForEach(HKUnit.weightUnits, id: \.unitString) { unit in
              Button(unit.descriptiveUnitName) {
                unitPreferences.weightUnit = unit
              }
            }
          } label: {
            Text(unitPreferences.weightUnit.sensibleUnitString)
            Image(systemName: "chevron.up.chevron.down")
              .font(.title2)
          }
        }
        .frame(width: 200)
        .fontDesign(.rounded)
        .keyboardType(.decimalPad)
        .textFieldStyle(.roundedBorder)
        .font(.largeTitle)
        .bold()
        .multilineTextAlignment(.trailing)

        Spacer()
      }
    }
    .tint(.mutedIndigo)
    .onAppear {
      isFocused = true
    }
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
  TargetWeightEditCard()
}
