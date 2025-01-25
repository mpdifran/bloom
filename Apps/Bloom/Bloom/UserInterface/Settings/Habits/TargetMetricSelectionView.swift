//
//  TargetMetricSelectionView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-01-25.
//

import SwiftUI
import DataContainer

struct TargetMetricSelectionView: View {
  @Binding var selectedTargetMetric: TargetMetric
  let excludingTargetMetrics: [TargetMetric]

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ScrollView {
      VStack {
        ForEach(TargetMetric.userSelectableMetrics(excluding: excludingTargetMetrics)) { targetMetric in
          SelectableHabitCell(
            targetMetric: targetMetric,
            isSelected: selectedTargetMetric == targetMetric
          )
          .cardContainer()
          .onTapGesture {
            selectedTargetMetric = targetMetric
            dismiss()
          }
        }
      }
      .padding()
      .presentationDetentSelfSizing()
    }
    .presentationCornerRadius(30)
    .presentationDragIndicator(.visible)
    .groupedBackground()
  }
}

#Preview {
  @Previewable @State var selectedTargetMetric: TargetMetric = .bikeDistance

  PreviewSheetPresent {
    TargetMetricSelectionView(
      selectedTargetMetric: $selectedTargetMetric,
      excludingTargetMetrics: []
    )
  }
}
