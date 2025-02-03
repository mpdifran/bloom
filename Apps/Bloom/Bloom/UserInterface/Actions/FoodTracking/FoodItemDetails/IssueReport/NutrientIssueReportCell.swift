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
    HStack {
      if hasChangedValue {
        Button {
          amount = originalQuantity?.doubleValue(for: unit) ?? -1
        } label: {
          Image(systemName: "arrow.uturn.left")
            .foregroundStyle(.mutedOrange)
        }
      }

      Text(name)

      Spacer()

      TextField("", value: $amount, formatter: NumberFormatter.twoDecimalPlaces)
        .textFieldStyle(.roundedBorder)
        .multilineTextAlignment(.trailing)
        .frame(width: 100)
        .bold()
        .focused($isFocused)
        .fontDesign(.rounded)
        .keyboardType(.decimalPad)
        .if(hasChangedValue) {
          $0.foregroundStyle(.mutedOrange)
        }
        .selectAllTextOnBeginEditing()
        .opacity(amount < 0 ? 0 : 1)
        .overlay {
          if amount < 0 {
            Text("--")
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
    .animation(.easeInOut, value: hasChangedValue)
    .selectable()
    .onTapGesture {
      guard amount < 0 else { return }

      amount = 0
      isFocused = true
    }
  }
}

extension NutrientIssueReportCell {

  var hasChangedValue: Bool {
    if let originalQuantity {
      return !originalQuantity.doubleValue(for: unit).isWithinRange(of: amount, precision: 0.1)
    }
    return amount >= 0
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
