//
//  NutrientIssueReportCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-01-30.
//

import SwiftUI
import HealthKit

struct NutrientIssueReportCell: View {
  let name: String
  let originalQuantity: HKQuantity?
  @Binding var amount: Double
  @Binding var unit: HKUnit
  let validUnits: [HKUnit]

  @FocusState var isFocused: Bool

  var body: some View {
    FoodItemEditableCell(
      title: name,
      mode: mode
    ) { resetMode in
        switch resetMode {
        case .clearValue:
          amount = -1
        case .resetValue:
          amount = originalQuantity?.doubleValue(for: unit) ?? -1
        }
      } contentBuilder: {
        TextField("", value: $amount, formatter: NumberFormatter.twoDecimalPlaces)
          .textFieldStyle(.roundedBorder)
          .multilineTextAlignment(.trailing)
          .frame(width: 100)
          .bold()
          .foregroundStyle(mode == .modifiedValue ? .mutedOrange : .primary)
          .focused($isFocused)
          .fontDesign(.rounded)
          .keyboardType(.decimalPad)
          .selectAllTextOnBeginEditing()
          .opacity(amount < 0 ? 0 : 1)
          .overlay {
            if amount < 0 {
              Text(verbatim: "--")
                .bold()
                .foregroundStyle(.secondary)
                .zStackAlignment(.trailing)
            }
          }

        UnitPickerView(unit: $unit, units: validUnits)
      }
      .onChange(of: unit) { oldValue, newValue in
        let oldQuantity = HKQuantity(unit: oldValue, doubleValue: amount)
        amount = oldQuantity.doubleValue(for: newValue)
      }
      .selectable()
      .onTapGesture {
        guard amount < 0 else { return }

        amount = 0
        isFocused = true
      }
  }
}

extension NutrientIssueReportCell {

  var mode: FoodItemEditableCellMode {
    if let originalQuantity {
      if originalQuantity.doubleValue(for: unit).isWithinRange(of: amount, precision: 0.1) {
        return .value
      }
    } else {
      if amount < 0 {
        return .value
      }
    }
    return .modifiedValue
  }
}

#Preview {
  @Previewable @State var amount: Double = 200
  @Previewable @State var unit: HKUnit = .gramUnit(with: .micro)

  VStack {
    NutrientIssueReportCell(
      name: "Vitamin A",
      originalQuantity: HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 200),
      amount: $amount,
      unit: $unit,
      validUnits: [HKUnit.gramUnit(with: .milli), HKUnit.gramUnit(with: .micro)]
    )
    .cardContainer()
    .padding()
  }
  .groupedBackground()
}
