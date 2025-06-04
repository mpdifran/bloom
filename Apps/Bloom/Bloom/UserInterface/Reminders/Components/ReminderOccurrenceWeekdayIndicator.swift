//
//  ReminderOccurrenceWeekdayIndicator.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-06-03.
//

import SwiftUI

struct ReminderOccurrenceWeekdayIndicator: View {
  let title: String
  let isSelected: Bool

  var body: some View {
    Circle()
      .fill(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.fill))
      .frame(square: 30)
      .overlay {
        Text(title)
          .font(.caption)
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(foregroundColor)
      }
  }
}

private extension ReminderOccurrenceWeekdayIndicator {

  var foregroundColor: Color {
    if isSelected {
      return .white
    }
    return .primary
  }
}

#Preview {
  HStack {
    ReminderOccurrenceWeekdayIndicator(title: "S", isSelected: false)
    ReminderOccurrenceWeekdayIndicator(title: "M", isSelected: true)
    ReminderOccurrenceWeekdayIndicator(title: "T", isSelected: true)
    ReminderOccurrenceWeekdayIndicator(title: "W", isSelected: true)
    ReminderOccurrenceWeekdayIndicator(title: "T", isSelected: false)
    ReminderOccurrenceWeekdayIndicator(title: "F", isSelected: true)
    ReminderOccurrenceWeekdayIndicator(title: "S", isSelected: false)
  }
}
