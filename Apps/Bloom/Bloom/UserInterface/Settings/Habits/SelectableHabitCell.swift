//
//  SelectableHabitCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-21.
//

import SFSafeSymbols
import SwiftUI
import DataContainer

struct SelectableHabitCell: View {
  let targetMetric: TargetMetric
  let isSelected: Bool

  var body: some View {
    HStack {
      Image(systemSymbol: SFSymbol(rawValue: targetMetric.systemImage))
        .font(.title3)
        .foregroundStyle(targetMetric.color)
        .frame(width: 40)

      Text(targetMetric.name)
        .font(.title3)
        .bold()

      Spacer()

      if isSelected {
        Image(systemSymbol: .checkmark)
          .font(.title3)
          .bold()
          .foregroundStyle(targetMetric.color)
      }
    }
    .foregroundStyle(.text)
    .fontDesign(.rounded)
    .selectable()
    .contentShape(Rectangle())
    .frame(height: 40)
  }
}

#Preview {
  List {
    SelectableHabitCell(targetMetric: .stepCount, isSelected: true)
    SelectableHabitCell(targetMetric: .walkingRunningDistance, isSelected: false)
  }
}
