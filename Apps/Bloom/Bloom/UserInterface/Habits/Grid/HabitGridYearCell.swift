//
//  HabitGridYearCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-06-28.
//

import SwiftUI

struct HabitGridYearCell: View {
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
//      .aspectRatio(3/2, contentMode: .fit)
      .id(id)
  }
}

private extension HabitGridYearCell {

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
    HabitGridYearCell(id: "1", isComplete: false, isToday: false)
    HabitGridYearCell(id: "2", isComplete: false, isToday: true)
    HabitGridYearCell(id: "3", isComplete: true, isToday: false)
    HabitGridYearCell(id: "4", isComplete: true, isToday: true)
    HabitGridYearCell(id: "5", isComplete: nil, isToday: false)
  }
  .tint(.mutedPink)
}
