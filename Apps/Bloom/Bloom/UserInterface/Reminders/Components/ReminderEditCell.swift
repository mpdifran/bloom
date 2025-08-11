import SwiftUI
import BloomFoundation
import DataContainer
import SFSafeSymbols

struct ReminderEditCell: View {
  let reminder: Reminder

  var body: some View {
    HStack {
      ReminderDot(color: reminder.color)

      VStack(alignment: .leading) {
        Text(reminder.title)
          .font(.headline)
          .bold()
          .fontDesign(.rounded)

        Text(reminder.combinedCadenceDescription)
          .font(.subheadline)
          .foregroundStyle(.secondary)

        if let triggerDescription = reminder.triggerDescription {
          Text(triggerDescription)
            .font(.subheadline)
            .foregroundStyle(reminder.color)
        }

        if let sideEffectDescription = reminder.sideEffectDescription {
          Text(sideEffectDescription)
            .font(.subheadline)
            .foregroundStyle(reminder.color)
        }
      }

      Spacer()

      DisclosureIndicator()
    }
    .cardContainer()
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      ReminderEditCell(
        reminder: Reminder(
          title: "Take vitamins",
          occurrences: [
            ReminderOccurrence(
              cadenceType: .daily,
              timeOfDay: 9 * 3600 // 9 AM
            )
          ]
        )
      )

      ReminderEditCell(
        reminder: Reminder(
          title: "Water plants",
          occurrences: [
            ReminderOccurrence(
              cadenceType: .weekly,
              timeOfDay: 10 * 3600, // 10 AM
              daysOfWeek: [2, 6] // Monday and Friday
            )
          ]
        )
      )

      ReminderEditCell(
        reminder: Reminder(
          title: "Pay rent",
          occurrences: [
            ReminderOccurrence(
              cadenceType: .monthly,
              timeOfDay: 8 * 3600, // 8 AM
              dayOfMonth: 1
            )
          ]
        )
      )
      
      ReminderEditCell(
        reminder: Reminder(
          title: "Take medication",
          occurrences: [
            ReminderOccurrence(
              cadenceType: .daily,
              timeOfDay: 9 * 3600 // 9 AM
            ),
            ReminderOccurrence(
              cadenceType: .daily,
              timeOfDay: 22 * 3600 // 10 PM
            )
          ],
          sideEffects: [
            ReminderSideEffect.Preview.logVitamins,
            ReminderSideEffect.Preview.logWater16oz
          ]
        )
      )
      
      ReminderEditCell(
        reminder: Reminder(
          title: "Hydration goal",
          triggerType: "log_water",
          occurrences: [
            ReminderOccurrence(
              cadenceType: .daily,
              timeOfDay: 8 * 3600 // 8 AM
            )
          ],
          sideEffects: [
            ReminderSideEffect.Preview.logWater16oz
          ]
        )
      )
    }
  }
}
