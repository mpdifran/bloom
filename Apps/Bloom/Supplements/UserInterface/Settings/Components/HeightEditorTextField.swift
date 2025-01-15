//
//  HeightEditorTextField.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-15.
//

import SwiftUI

struct HeightEditorTextField: View {

  @ObservedObject private var healthManager = HealthManager.shared
  @Bindable private var unitPreferences = HealthUnitPreferences.shared

  @State private var heightCM: Double
  @State private var heightFeet: Int
  @State private var heightInches: Int

  init() {
    let totalInches = HealthManager.shared.heightCM / 2.54
    let feet = Int(floor(totalInches / 12))
    let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
    self._heightFeet = .init(initialValue: feet)
    self._heightInches = .init(initialValue: inches)
    self._heightCM = .init(initialValue: HealthManager.shared.heightCM)
  }

  var body: some View {
    HStack {
      if isMetric {
        metricHeightEditor
      } else {
        imperialHeightEditor
      }
      LocalizedUnitPickerView(unit: $unitPreferences.heightUnit)
        .fixedSize(horizontal: true, vertical: true)
    }
    .animation(.easeInOut, value: isMetric)
    .onChange(of: heightFeet) { _, _ in
      recalculateHeightCMFromInches()
    }
    .onChange(of: heightInches) { _, _ in
      recalculateHeightCMFromInches()
    }
  }
}

private extension HeightEditorTextField {

  var isMetric: Bool {
    unitPreferences.heightUnit.unitString == "cm"
  }

  func recalculateHeightCMFromCM() {
    let totalInches = heightCM / 2.54
    let feet = Int(floor(totalInches / 12))
    let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))

    heightFeet = feet
    heightInches = inches
    healthManager.heightCM = heightCM
  }

  func recalculateHeightCMFromInches() {
    guard !isMetric else { return } // We do this to avoid recursively setting heightCM from imperial when heightCM changes.

    heightCM = Double(heightFeet) * 30.4 + Double(heightInches) * 2.54
    healthManager.heightCM = heightCM
  }
}

private extension HeightEditorTextField {

  var imperialHeightEditor: some View {
    HStack {
      Picker("Feet", selection: $heightFeet) {
        ForEach(1 ..< 9) { feet in
          Text("\(feet)'")
            .tag(feet)
        }
      }
      .pickerStyle(.wheel)
      .frame(width: 60, height: 80)
      .clipped()

      Picker("Inches", selection: $heightInches) {
        ForEach(0 ..< 12) { inches in
          Text("\(inches)\"")
            .tag(inches)
        }
      }
      .pickerStyle(.wheel)
      .frame(width: 60, height: 80)
      .clipped()
    }
    .padding(.vertical, -18)
  }

  var metricHeightEditor: some View {
    TextField(
      "",
      value: $heightCM,
      formatter: NumberFormatter.oneDecimalPlace
    )
    .multilineTextAlignment(.trailing)
    .submitLabel(.done)
    .keyboardType(.decimalPad)
    .frame(width: 70)
    .textFieldStyle(.roundedBorder)
    .onSubmit {
      recalculateHeightCMFromCM()
    }
  }
}

#Preview {
  VStack {
    LabeledContent("Height") {
      HeightEditorTextField()
    }
    .cardContainer(fill: .background.secondary)
  }
  .padding()
}
