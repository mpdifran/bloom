//
//  StatTimePeriodPicker.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-01-08.
//

import SwiftUI

struct StatTimePeriodPicker: View {
  @Binding var selectedPeriod: StatTimePeriod

  var body: some View {
    Picker("Time Period", selection: $selectedPeriod) {
      ForEach(StatTimePeriod.allCases) { period in
        Text(period.rawValue).tag(period)
      }
    }
    .pickerStyle(.segmented)
    .sensoryFeedback(.selection, trigger: selectedPeriod)
  }
}

#Preview {
  PreviewEnvironment {
    StatTimePeriodPicker(selectedPeriod: .constant(.sevenDays))
      .padding()
  }
}
