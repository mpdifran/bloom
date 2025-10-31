//
//  GoalGridYear.swift
//  BloomUI
//
//  Created by Claude Code on 2025-10-30.
//

import SwiftUI
import BloomFoundation

public struct GoalGridYear: View {
  let model: GoalGridYearModel
  let minCellWidth: CGFloat
  let spacing: CGFloat
  let labelHeight: CGFloat

  public init(
    model: GoalGridYearModel,
    minCellWidth: CGFloat = 120,
    spacing: CGFloat = 4,
    labelHeight: CGFloat = 20
  ) {
    self.model = model
    self.minCellWidth = minCellWidth
    self.spacing = spacing
    self.labelHeight = labelHeight
  }

  public var body: some View {
    GeometryReader { proxy in
      HStack(alignment: .bottom, spacing: spacing) {
        ForEach(Array(model.years.enumerated()), id: \.element.id) { columnIndex, year in
          if recommendedMaxColumnCount(for: proxy.size.width) > (model.years.count - columnIndex - 1) {
            VStack(spacing: 0) {
              Text(year.yearLabel)
                .font(.caption)
                .bold()
                .foregroundStyle(.secondary)
                .frame(height: labelHeight, alignment: .bottom)

              GoalGridCell(
                id: "\(year.id)",
                isComplete: year.isComplete,
                isToday: year.isCurrentYear,
                cornerRadius: 6
              )
            }
          }
        }
      }
    }
    .frame(height: minCellWidth + labelHeight)
  }
}

public extension GoalGridYear {
  func recommendedMaxColumnCount(for width: CGFloat) -> Int {
    let remainingWidth = width - minCellWidth
    return Int((remainingWidth / (minCellWidth + spacing)).rounded(.awayFromZero))
  }
}
