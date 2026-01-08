//
//  StatTimePeriodPicker.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-01-08.
//

import SwiftUI

struct StatTimePeriodPicker: View {
  @Binding var selectedPeriod: StatTimePeriod
  var includeOneDay: Bool = false

  private var periods: [StatTimePeriod] {
    if includeOneDay {
      return StatTimePeriod.allCases
    }
    return StatTimePeriod.allCases.filter { $0 != .oneDay }
  }

  var body: some View {
    Picker("Time Period", selection: $selectedPeriod) {
      ForEach(periods) { period in
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
