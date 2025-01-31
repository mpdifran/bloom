//
//  UnitPickerView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-01-30.
//

import SwiftUI
import HealthKit

struct UnitPickerView: View {
  @Binding var unit: HKUnit
  let units: [HKUnit]

  var body: some View {
    if units.count == 1, let unit = units.first {
      Text(unit.sensibleUnitString)
    } else {
      Menu {
        ForEach(units, id: \.unitString) { unit in
          Button(unit.descriptiveUnitName) {
            self.unit = unit
          }
        }
      } label: {
        Text(unit.sensibleUnitString)
        Image(systemName: "chevron.up.chevron.down")
      }
    }
  }
}

#Preview {
  @Previewable @State var unit: HKUnit = .gramUnit(with: .micro)

  UnitPickerView(
    unit: $unit,
    units: [.gramUnit(with: .milli), .gramUnit(with: .micro)]
  )
}
