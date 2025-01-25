//
//  SelectableHabitCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-21.
//

import SwiftUI
import DataContainer

struct SelectableHabitCell: View {
  let targetMetric: TargetMetric
  let isSelected: Bool

  var body: some View {
    HStack {
      Image(systemName: targetMetric.systemImage)
        .font(.title3)
        .foregroundStyle(targetMetric.color)
        .frame(width: 40)

      Text(targetMetric.name)
        .bold()

      Spacer()

      if isSelected {
        Image(systemName: "checkmark")
          .foregroundStyle(targetMetric.color)
      }
    }
    .fontDesign(.rounded)
    .selectable()
    .contentShape(Rectangle())
    .frame(height: 50)
  }
}

#Preview {
  List {
    SelectableHabitCell(targetMetric: .stepCount, isSelected: true)
    SelectableHabitCell(targetMetric: .walkingRunningDistance, isSelected: false)
  }
}
