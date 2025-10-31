//
//  GoalGridCell.swift
//  BloomUI
//
//  Created by Mark DiFranco on 2024-09-11.
//

import SwiftUI
import BloomFoundation

public struct GoalGridCell: View {
  let id: String
  let isComplete: Bool?
  let isToday: Bool
  let cornerRadius: CGFloat
  let aspectRatio: CGFloat?

  public init(
    id: String,
    isComplete: Bool?,
    isToday: Bool,
    cornerRadius: CGFloat = 6,
    aspectRatio: CGFloat? = nil
  ) {
    self.id = id
    self.isComplete = isComplete
    self.isToday = isToday
    self.cornerRadius = cornerRadius
    self.aspectRatio = aspectRatio
  }

  public var body: some View {
    RoundedRectangle(cornerRadius: cornerRadius)
      .stroke(.tint.opacity(strokeOpacity))
      .overlay {
        if let isComplete {
          RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.tint.opacity(cellOpacity))
            .overlay {
              if isToday {
                if isComplete {
                  RoundedRectangle(cornerRadius: cornerRadius - 2)
                    .stroke(.background, lineWidth: 2)
                    .padding(2)
                } else {
                  RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.tint, lineWidth: 2)
                }
              }
            }
        }
      }
      .aspectRatio(aspectRatio, contentMode: .fit)
      .id(id)
  }
}

private extension GoalGridCell {

  var strokeOpacity: Double {
    switch isComplete {
    case .none: 0.4
    default: 0
    }
  }

  var cellOpacity: Double {
    switch isComplete {
    case true: 1
    case false: 0.4
    default: 0.4
    }
  }
}

#Preview {
  VStack {
    GoalGridCell(id: "1", isComplete: false, isToday: false)
    GoalGridCell(id: "2", isComplete: false, isToday: true)
    GoalGridCell(id: "3", isComplete: true, isToday: false)
    GoalGridCell(id: "4", isComplete: true, isToday: true)
    GoalGridCell(id: "5", isComplete: nil, isToday: false)
  }
  .frame(width: 20)
  .tint(.mutedBlue)
}
