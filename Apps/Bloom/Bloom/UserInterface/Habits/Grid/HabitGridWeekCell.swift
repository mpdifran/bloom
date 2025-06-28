//
//  HabitGridWeekCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-06-28.
//

import SwiftUI

struct HabitGridWeekCell: View {
  let id: String
  let isComplete: Bool?
  let isToday: Bool

  var body: some View {
    RoundedRectangle(cornerRadius: 6)
      .stroke(.tint.opacity(strokeOpacity))
      .overlay {
        if let isComplete {
          RoundedRectangle(cornerRadius: 6)
            .fill(.tint.opacity(cellOpacity))
            .overlay {
              if isToday {
                if isComplete {
                  RoundedRectangle(cornerRadius: 4)
                    .stroke(.background, lineWidth: 2)
                    .padding(2)
                } else {
                  RoundedRectangle(cornerRadius: 6)
                    .stroke(.tint, lineWidth: 2)
                }
              }
            }
        }
      }
      .aspectRatio(1/7, contentMode: .fit)
      .id(id)
  }
}

private extension HabitGridWeekCell {

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
  HStack {
    HabitGridWeekCell(id: "1", isComplete: false, isToday: false)
    HabitGridWeekCell(id: "2", isComplete: false, isToday: true)
    HabitGridWeekCell(id: "3", isComplete: true, isToday: false)
    HabitGridWeekCell(id: "4", isComplete: true, isToday: true)
    HabitGridWeekCell(id: "5", isComplete: nil, isToday: false)
    HabitGridWeekCell(id: "6", isComplete: false, isToday: false)
    HabitGridWeekCell(id: "7", isComplete: false, isToday: false)
    HabitGridWeekCell(id: "8", isComplete: false, isToday: false)
    HabitGridWeekCell(id: "9", isComplete: false, isToday: false)
    HabitGridWeekCell(id: "10", isComplete: false, isToday: false)
  }
  .tint(.mutedYellow)
}
