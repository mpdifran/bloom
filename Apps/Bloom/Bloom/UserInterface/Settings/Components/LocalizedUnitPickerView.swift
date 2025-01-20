//
//  LocalizedUnitPickerView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-13.
//

import SwiftUI
import HealthKit

struct LocalizedUnitPickerView: View {
  @Binding var unit: HKUnit

  @Bindable private var unitPreferences = HealthUnitPreferences.shared

  var body: some View {
    if isWeightUnit {
      weightMenu
    } else if isLiquidVolumeUnit {
      liquidVolumeMenu
    } else if isDistanceUnit {
      distanceMenu
    } else if isHeightUnit {
      heightMenu
    } else {
      Text(unit.sensibleUnitString)
    }
  }
}

private extension LocalizedUnitPickerView {

  var isWeightUnit: Bool {
    HKUnit.weightUnits.contains(unit)
  }

  var isLiquidVolumeUnit: Bool {
    HKUnit.liquidVolumeUnits.contains(unit)
  }

  var isDistanceUnit: Bool {
    HKUnit.distanceUnits.contains(unit)
  }

  var isHeightUnit: Bool {
    HKUnit.heightUnits.contains(unit)
  }
}

private extension LocalizedUnitPickerView {

  var weightMenu: some View {
    Menu {
      ForEach(HKUnit.weightUnits, id: \.unitString) { unit in
        Button(unit.descriptiveUnitName) {
          unitPreferences.weightUnit = unit
          self.unit = unit
        }
      }
    } label: {
      Text(unit.sensibleUnitString)
      Image(systemName: "chevron.up.chevron.down")
    }
  }

  var liquidVolumeMenu: some View {
    Menu {
      ForEach(HKUnit.liquidVolumeUnits, id: \.unitString) { unit in
        Button(unit.descriptiveUnitName) {
          unitPreferences.liquidVolumeUnit = unit
          self.unit = unit
        }
      }
    } label: {
      Text(unit.sensibleUnitString)
      Image(systemName: "chevron.up.chevron.down")
    }
  }

  var distanceMenu: some View {
    Menu {
      ForEach(HKUnit.distanceUnits, id: \.unitString) { unit in
        Button(unit.descriptiveUnitName) {
          unitPreferences.distanceUnit = unit
          self.unit = unit
        }
      }
    } label: {
      Text(unit.sensibleUnitString)
      Image(systemName: "chevron.up.chevron.down")
    }
  }

  var heightMenu: some View {
    Menu {
      ForEach(HKUnit.heightUnits, id: \.unitString) { unit in
        Button(unit.descriptiveUnitName) {
          unitPreferences.heightUnit = unit
          self.unit = unit
        }
      }
    } label: {
      Text(unit.sensibleUnitString)
      Image(systemName: "chevron.up.chevron.down")
    }
  }
}

#Preview {
  @Previewable @State var weightUnit = HKUnit.pound()
  @Previewable @State var fluidVolumeUnit = HKUnit.literUnit(with: .milli)
  @Previewable @State var distanceUnit = HKUnit.meterUnit(with: .kilo)
  @Previewable @State var heightUnit = HKUnit.meterUnit(with: .centi)

  Group {
    LocalizedUnitPickerView(unit: .constant(.minute()))
    LocalizedUnitPickerView(unit: $weightUnit)
    LocalizedUnitPickerView(unit: $fluidVolumeUnit)
    LocalizedUnitPickerView(unit: $distanceUnit)
    LocalizedUnitPickerView(unit: $heightUnit)
  }
  .font(.title)
  .fontDesign(.rounded)
  .bold()
  .foregroundStyle(.secondary)
}
