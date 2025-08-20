//
//  ChatReminderCell.swift
//  Bloom
//
//  Created by Assistant on 2025-06-05.
//

import SwiftUI
import BloomFoundation
import DataContainer
import SwiftData

struct ChatReminderCell: View {
  let reminder: ReminderDTO
  let occurrence: ReminderOccurrenceDTO?
  let isCompleted: Bool
  
  init(
    reminder: ReminderDTO,
    occurrence: ReminderOccurrenceDTO? = nil,
    isCompleted: Bool = false
  ) {
    self.reminder = reminder
    self.occurrence = occurrence
    self.isCompleted = isCompleted
  }

  var body: some View {
    HStack {
      HStack {
        CompletionCheckmarkView(state: isCompleted ? .metGoal : .unmetGoal, colorize: true)

        VStack(alignment: .leading) {
          Text(reminder.title)
            .font(.title3)

          Text(reminder.combinedCadenceDescription)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
        }
        .bold()
        .fontDesign(.rounded)
        .lineLimit(1)

        Spacer()

        DisclosureIndicator()
      }
      .tint(reminder.color)
      .chatCardContainer()
      .frame(width: 300)

      Spacer()
    }
    .padding(.horizontal)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      ChatReminderCell(
        reminder: Reminder.Preview.dailyVitamins.asDTO(),
        isCompleted: false
      )
      
      ChatReminderCell(
        reminder: Reminder.Preview.weeklyWaterPlants.asDTO(),
        isCompleted: true
      )
      
      ChatReminderCell(
        reminder: Reminder.Preview.monthlyPayRent.asDTO(),
        isCompleted: false
      )
    }
  }
}
