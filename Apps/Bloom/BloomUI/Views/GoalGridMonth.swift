//
//  GoalGridMonth.swift
//  BloomUI
//
//  Created by Claude Code on 2025-10-30.
//

import SwiftUI
import BloomFoundation

public struct GoalGridMonth: View {
  let model: GoalGridMonthModel
  let minCellWidth: CGFloat
  let spacing: CGFloat
  let labelHeight: CGFloat

  public init(
    model: GoalGridMonthModel,
    minCellWidth: CGFloat = 80,
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
        ForEach(Array(model.months.enumerated()), id: \.element.id) { columnIndex, month in
          if recommendedMaxColumnCount(for: proxy.size.width) > (model.months.count - columnIndex - 1) {
            VStack(spacing: 0) {
              Text(month.monthLabel)
                .font(.caption)
                .bold()
                .foregroundStyle(.secondary)
                .frame(height: labelHeight, alignment: .bottom)

              GoalGridCell(
                id: "\(month.id)",
                isComplete: month.isComplete,
                isToday: month.isCurrentMonth,
                cornerRadius: minCellWidth * 0.3,
                aspectRatio: 4/7
              )
            }
          }
        }
      }
    }
    .frame(height: height)
  }
}

public extension GoalGridMonth {
  var height: CGFloat {
    let cellHeight = minCellWidth / 4 * 7 // Month cell height similar to week cell
    return cellHeight + labelHeight
  }

  func recommendedMaxColumnCount(for width: CGFloat) -> Int {
    let remainingWidth = width - minCellWidth
    return Int((remainingWidth / (minCellWidth + spacing)).rounded(.awayFromZero))
  }
}
