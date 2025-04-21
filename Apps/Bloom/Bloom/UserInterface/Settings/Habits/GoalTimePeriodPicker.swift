//
//  GoalTimePeriodPicker.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-21.
//

import SwiftUI
import DataContainer

struct GoalTimePeriodPicker: View {
  @Binding var selectedTimePeriod: GoalTimePeriod
  let targetMetric: TargetMetric

  var body: some View {
    Picker(selection: $selectedTimePeriod) {
      ForEach(targetMetric.supportedTimePeriods) { timePeriod in
        Text(timePeriod.name)
          .tag(timePeriod)
      }
    } label: {
      Text(selectedTimePeriod.name)
        .fontDesign(.rounded)
        .bold()
        .foregroundStyle(.tint)
    }
  }
}

#Preview {
  @Previewable @State var timePeriod: GoalTimePeriod = .daily

  PreviewEnvironment {
    GoalTimePeriodPicker(
      selectedTimePeriod: $timePeriod,
      targetMetric: .runDistance
    )
    .tint(.mutedOrange)
  }
}
