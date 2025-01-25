//
//  TargetMetricPicker.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-01-25.
//

import SwiftUI
import DataContainer

struct TargetMetricPicker: View {
  @Binding var selectedTargetMetric: TargetMetric

  let excludedTargetMetrics: [TargetMetric]

  init(
    selectedTargetMetric: Binding<TargetMetric>,
    excludedTargetMetrics: [TargetMetric] = []
  ) {
    self._selectedTargetMetric = selectedTargetMetric
    self.excludedTargetMetrics = excludedTargetMetrics
  }

  @State private var presentedSheet: AnyView?

  var body: some View {
    HStack {
      Label(selectedTargetMetric.name, systemImage: selectedTargetMetric.systemImage)
        .lineLimit(1)
      Image(systemName: "chevron.up.chevron.down")
    }
    .bold()
    .foregroundStyle(.tint)
    .tint(selectedTargetMetric.color)
    .selectable()
    .onTapGesture {
      presentedSheet = TargetMetricSelectionView(
        selectedTargetMetric: $selectedTargetMetric,
        excludingTargetMetrics: excludedTargetMetrics
      ).asAny
    }
    .sheet($presentedSheet)
  }
}

#Preview {
  @Previewable @State var selectedTargetMetric: TargetMetric = .bikeDistance

  TargetMetricPicker(
    selectedTargetMetric: $selectedTargetMetric,
    excludedTargetMetrics: []
  )
}
