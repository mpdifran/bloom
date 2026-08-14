//
//  HeightEditorTextField.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-15.
//

import SwiftUI
import CoreHealth

struct HeightEditorTextField: View {

  @ObservedObject private var healthManager = HealthManager.shared
  @Bindable private var unitPreferences = HealthUnitPreferences.shared

  @State private var heightCM: Double
  @State private var heightFeet: Int
  @State private var heightInches: Int

  @FocusState private var isTextFieldFocused: Bool

  init() {
    let (feet, inches) = HealthManager.shared.heightCM.toFeetInches()
    self._heightFeet = State(initialValue: feet)
    self._heightInches = State(initialValue: inches)
    self._heightCM = State(initialValue: HealthManager.shared.heightCM)
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
    let (feet, inches) = HealthManager.shared.heightCM.toFeetInches()

    heightFeet = feet
    heightInches = inches
    healthManager.heightCM = heightCM
  }

  func recalculateHeightCMFromInches() {
    guard !isMetric else { return } // We do this to avoid recursively setting heightCM from imperial when heightCM changes.

    heightCM = Double.from(feet: heightFeet, inches: heightInches)
    healthManager.heightCM = heightCM
  }
}

private extension HeightEditorTextField {

  var imperialHeightEditor: some View {
    HStack {
      Picker("Feet", selection: $heightFeet) {
        ForEach(1 ..< 9) { feet in
          Text(verbatim: "\(feet)'")
            .tag(feet)
        }
      }
      .pickerStyle(.wheel)
      .frame(width: 60, height: 80)
      .clipped()

      Picker("Inches", selection: $heightInches) {
        ForEach(0 ..< 12) { inches in
          Text(verbatim: "\(inches)\"")
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
    .focused($isTextFieldFocused)
    .onSubmit {
      recalculateHeightCMFromCM()
    }
    .onChange(of: isTextFieldFocused) { _, newValue in
      if !newValue {
        recalculateHeightCMFromCM()
      }
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
