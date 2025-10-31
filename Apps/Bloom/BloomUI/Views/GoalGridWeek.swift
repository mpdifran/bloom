//
//  GoalGridWeek.swift
//  BloomUI
//
//  Created by Claude Code on 2025-10-30.
//

import SwiftUI
import BloomFoundation
import AppUI

public struct GoalGridWeek: View {
  let model: GoalGridWeekModel
  let minCellWidth: CGFloat
  let spacing: CGFloat
  let labelHeight: CGFloat

  public init(
    model: GoalGridWeekModel,
    minCellWidth: CGFloat = 20,
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
        ForEach(Array(model.weeks.enumerated()), id: \.element.id) { columnIndex, week in
          if recommendedMaxColumnCount(for: proxy.size.width) > (model.weeks.count - columnIndex - 1) {
            VStack(spacing: 0) {
              Spacer(minLength: labelHeight)

              GoalGridCell(
                id: "\(week.id)",
                isComplete: week.isComplete,
                isToday: week.isCurrentWeek,
                cornerRadius: minCellWidth * 0.3,
                aspectRatio: 1/7
              )
            }
          }
        }
      }
      .overlay {
        ZStack {
          ForEach(Array(model.weeks.enumerated()), id: \.element.id) { columnIndex, week in
            if recommendedMaxColumnCount(for: proxy.size.width) > (model.weeks.count - columnIndex - 1) {
              if let monthLabel = week.monthLabel {
                Text(monthLabel)
                  .font(.caption)
                  .bold()
                  .foregroundStyle(.secondary)
                  .fixedSize(horizontal: true, vertical: false)
                  .frame(height: labelHeight, alignment: .bottom)
                  .padding(.leading, CGFloat(columnIndex) * minCellWidth + CGFloat(columnIndex) * spacing)
                  .zStackAlignment(.topLeading)
              }
            }
          }
        }
      }
    }
    .frame(height: height)
  }
}

public extension GoalGridWeek {
  var height: CGFloat {
    let cellHeight = 7 * minCellWidth
    return cellHeight + labelHeight
  }

  func recommendedMaxColumnCount(for width: CGFloat) -> Int {
    let remainingWidth = width - minCellWidth
    return Int((remainingWidth / (minCellWidth + spacing)).rounded(.towardZero))
  }
}
