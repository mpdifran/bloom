//
//  WatchReminderCell.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-30.
//

import SwiftUI
import BloomFoundation
import SFSafeSymbols

struct WatchReminderCell: View {
  let reminder: WatchReminderData

  @State private var isProcessing = false

  private var reminderColor: Color {
    Color(hex: reminder.colorHex) ?? .blue
  }

  var body: some View {
    Button(action: handleTap) {
      HStack(spacing: 8) {
        // Color indicator + checkmark
        ZStack {
          Circle()
            .fill(reminder.isCompleted ? reminderColor : Color.clear)
            .frame(width: 24, height: 24)

          Circle()
            .strokeBorder(reminderColor, lineWidth: 2)
            .frame(width: 24, height: 24)

          if reminder.isCompleted {
            Image(systemSymbol: .checkmark)
              .font(.caption2.bold())
              .foregroundStyle(.white)
          }
        }

        VStack(alignment: .leading, spacing: 2) {
          Text(reminder.title)
            .font(.footnote)
            .fontWeight(.medium)
            .lineLimit(2)

          Text(statusText)
            .font(.caption2)
            .foregroundStyle(statusColor)
        }

        Spacer(minLength: 0)
      }
    }
    .buttonStyle(.plain)
    .disabled(isProcessing)
  }

  // Shared short time style - follows the locale and the user's 12/24-hour setting.
  private var scheduledTimeText: String {
    DateFormatter.justTimeShort.string(from: reminder.scheduledTime)
  }

  private var statusText: String {
    switch reminder.status {
    case .completed:
      return scheduledTimeText
    case .dueNow:
      return String(localized: "Due now", comment: "Reminder status when it is due right now")
    case .overdue:
      return String(
        localized: "Overdue \(scheduledTimeText)",
        comment: "Reminder status with the time it was due"
      )
    case .upcoming:
      return scheduledTimeText
    @unknown default:
      return ""
    }
  }

  private var statusColor: Color {
    switch reminder.status {
    case .completed:
      return .secondary
    case .dueNow:
      return .orange
    case .overdue:
      return .red
    case .upcoming:
      return .secondary
    @unknown default:
      return .secondary
    }
  }

  private func handleTap() {
    guard !isProcessing else { return }

    isProcessing = true

    Task {
      let action: WatchReminderCompletionMessage.CompletionAction =
        reminder.isCompleted ? .uncomplete : .complete

      _ = await PendingReminderCompletionManager.shared.complete(
        reminderID: reminder.reminderID,
        occurrenceID: reminder.occurrenceID,
        action: action
      )

      isProcessing = false
    }
  }
}

#Preview {
  PreviewEnvironment {
    List {
      WatchReminderCell(
        reminder: WatchReminderData(
          reminderID: "1",
          title: "Take Vitamins",
          colorHex: "#FF6B6B",
          scheduledTime: Date(),
          occurrenceID: "occ1",
          isCompleted: false,
          status: .dueNow
        )
      )

      WatchReminderCell(
        reminder: WatchReminderData(
          reminderID: "2",
          title: "Log Weight",
          colorHex: "#4ECDC4",
          scheduledTime: Date().addingTimeInterval(-3600),
          occurrenceID: "occ2",
          isCompleted: false,
          status: .overdue
        )
      )

      WatchReminderCell(
        reminder: WatchReminderData(
          reminderID: "3",
          title: "Drink Water",
          colorHex: "#45B7D1",
          scheduledTime: Date().addingTimeInterval(3600),
          occurrenceID: "occ3",
          isCompleted: true,
          status: .completed
        )
      )
    }
    .listStyle(.carousel)
  }
}
