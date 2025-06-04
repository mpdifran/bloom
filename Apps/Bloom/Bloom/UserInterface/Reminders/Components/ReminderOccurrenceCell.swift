import SwiftUI
import BloomFoundation
import DataContainer

struct ReminderOccurrenceCell: View {
  let occurrence: ReminderOccurrence
  
  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(occurrence.cadenceType.displayName)
          .font(.headline)
        
        Text(occurrence.cadenceDescription)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      
      Spacer()
      
      DisclosureIndicator()
    }
    .selectable()
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      ReminderOccurrenceCell(
        occurrence: ReminderOccurrence(
          cadenceType: .daily,
          timeOfDay: 9 * 3600
        )
      )
      
      ReminderOccurrenceCell(
        occurrence: ReminderOccurrence(
          cadenceType: .weekly,
          timeOfDay: 14 * 3600,
          daysOfWeek: [2, 4, 6]
        )
      )
      
      ReminderOccurrenceCell(
        occurrence: ReminderOccurrence(
          cadenceType: .monthly,
          timeOfDay: 10 * 3600,
          dayOfMonth: 15
        )
      )
    }
    .padding()
  }
}
