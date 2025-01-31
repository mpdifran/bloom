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
  let originalQuantity: HKQuantity
  @Binding var amount: Double
  @Binding var unit: HKUnit
  let validUnits: [HKUnit]

  var body: some View {
    HStack {
      Text(name)

      Spacer()

      TextField("", value: $amount, formatter: NumberFormatter.threeDecimalPlaces)
        .textFieldStyle(.roundedBorder)
        .multilineTextAlignment(.trailing)
        .frame(width: 70)
        .bold()
        .fontDesign(.rounded)
        .keyboardType(.decimalPad)
        .if(hasChangedValue) {
          $0.foregroundStyle(.mutedOrange)
        }
        .selectAllTextOnBeginEditing()

      UnitPickerView(unit: $unit, units: validUnits)
    }
    .onChange(of: unit) { oldValue, newValue in
      let oldQuantity = HKQuantity(unit: oldValue, doubleValue: amount)
      amount = oldQuantity.doubleValue(for: newValue)
    }
  }
}

extension NutrientIssueReportCell {

  var hasChangedValue: Bool {
    !originalQuantity.doubleValue(for: unit).isWithinRange(of: amount, precision: 0.1)
  }
}

#Preview {
  @Previewable @State var amount: Double = 200
  @Previewable @State var unit: HKUnit = .gramUnit(with: .micro)

  VStack {
    NutrientIssueReportCell(
      name: "Vitamin A",
      originalQuantity: .init(unit: .gramUnit(with: .micro), doubleValue: 200),
      amount: $amount,
      unit: $unit,
      validUnits: [.gramUnit(with: .milli), .gramUnit(with: .micro)]
    )
    .cardContainer()
    .padding()
  }
  .groupedBackground()
}
