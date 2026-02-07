//
//  CompleteReminderIntent.swift
//  BloomWatchWidgetsExtension
//
//  Created by Claude on 2026-02-07.
//

import AppIntents
import BloomFoundation
import Foundation
import WidgetKit

struct CompleteReminderIntent: AppIntent {
  nonisolated(unsafe) static var title: LocalizedStringResource = "Complete Reminder"
  nonisolated(unsafe) static var description = IntentDescription("Marks a reminder as completed.")

  @Parameter(title: "Reminder ID")
  var reminderID: String

  @Parameter(title: "Occurrence ID")
  var occurrenceID: String

  init() {
    self.reminderID = ""
    self.occurrenceID = ""
  }

  init(reminderID: String, occurrenceID: String) {
    self.reminderID = reminderID
    self.occurrenceID = occurrenceID
  }

  private static let remindersKey = "TodayProvider.reminders"
  static let widgetQueueKey = "WidgetPendingReminderCompletions"

  func perform() async throws -> some IntentResult {
    // 1. Load current reminders from UserDefaults
    guard let data = UserDefaults.group.data(forKey: Self.remindersKey),
          var reminders = try? JSONDecoder.watch.decode([WatchReminderData].self, from: data) else {
      return .result()
    }

    // 2. Find and mark the reminder as completed
    guard let index = reminders.firstIndex(where: {
      $0.reminderID == reminderID && $0.occurrenceID == occurrenceID
    }) else {
      return .result()
    }

    let completionDate = Date()

    reminders[index].isCompleted = true
    reminders[index].status = .completed
    reminders[index].completionDate = completionDate

    // 3. Save updated reminders back
    if let encoded = try? JSONEncoder.watch.encode(reminders) {
      UserDefaults.group.set(encoded, forKey: Self.remindersKey)
    }

    // 4. Queue a pending completion for later sync to the phone
    queueCompletion(completionDate: completionDate)

    // 5. Reload widget timeline to show next reminder
    WidgetCenter.shared.reloadTimelines(ofKind: String.WidgetKind.watchReminder)

    return .result()
  }

  private func queueCompletion(completionDate: Date) {
    var pending: [WatchReminderCompletionMessage] = []
    if let existingData = UserDefaults.group.data(forKey: Self.widgetQueueKey),
       let existing = try? JSONDecoder.watch.decode([WatchReminderCompletionMessage].self, from: existingData) {
      pending = existing
    }

    let message = WatchReminderCompletionMessage(
      reminderID: reminderID,
      occurrenceID: occurrenceID,
      completionDate: completionDate,
      action: .complete
    )

    pending.append(message)

    if let encoded = try? JSONEncoder.watch.encode(pending) {
      UserDefaults.group.set(encoded, forKey: Self.widgetQueueKey)
    }
  }
}
