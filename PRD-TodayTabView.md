# PRD: TodayTabView for BloomWatch

## Overview

Build the TodayTabView for the watchOS companion app that displays today's AI-generated advice and the user's reminders scheduled for today, with the ability to mark reminders as complete directly from the watch.

## Goals

1. Display "Today's Advice" (AI-generated) at the top of the view
2. Show a list of today's reminders with status indicators (overdue, due now, upcoming, completed)
3. Allow users to tap reminders to mark them complete/incomplete
4. Support offline completion with automatic sync when phone becomes available

## User Experience

### Today Tab View
- **Advice Section**: Card displaying today's AI-generated health advice with a sparkles icon
- **Reminders Section**: List of today's reminders sorted by priority:
  1. Overdue (red status)
  2. Due now (orange status)
  3. Upcoming (shows scheduled time)
  4. Completed (checkmark, muted appearance)

### Reminder Cell
- Color indicator circle matching reminder color
- Checkmark inside circle when completed
- Reminder title
- Status text (time, "Due now", or "Overdue")
- Tap anywhere to toggle completion

### Empty States
- No data synced: "Open Bloom on iPhone to sync today's data"
- No reminders: Show only advice section
- No advice: Show only reminders section

## Technical Architecture

### Data Sync (iOS to Watch)

Uses WatchConnectivity Application Context pattern for one-way sync of read data.

**Data Model:**
```swift
struct WatchTodayData: Codable, Sendable {
  let todaysAdvice: String?
  let reminders: [WatchReminderData]
  let lastUpdated: Date
}

struct WatchReminderData: Codable, Sendable, Identifiable {
  let id: String
  let title: String
  let colorHex: String
  let scheduledTime: Date
  let occurrenceID: String
  let isCompleted: Bool
  let status: ReminderStatus  // .overdue, .dueNow, .upcoming, .completed
}
```

**Sync Trigger:** iOS app foreground event

**Data Sources:**
- Advice: `TodayInsightsManager.shared.todayContent?.todaysAdvice`
- Reminders: `context.fetchRemindersWithOccurrenceToday()` + `reminder.asDTO().todaysOccurrenceDisplays()`

### Reminder Completion (Watch to iOS)

Uses WatchConnectivity Direct Messaging for immediate sync with offline queue fallback.

**Message Model:**
```swift
struct WatchReminderCompletionMessage: Codable, Sendable {
  static let messageType = "reminderCompletion"
  let type: String
  let reminderID: String
  let occurrenceID: String
  let completionDate: Date
  let action: CompletionAction  // .complete or .uncomplete
}
```

**Flow:**
1. User taps reminder on watch
2. Optimistic UI update (immediate checkmark)
3. Haptic feedback
4. Send message to iOS via WatchChannel
5. iOS processes completion via RemindersManager
6. iOS syncs updated data back to watch
7. If phone unavailable: queue completion, sync on next app launch

## Files to Create

| File | Location | Purpose |
|------|----------|---------|
| WatchTodayData.swift | BloomFoundation/Watch/ | Shared data models for sync |
| WatchReminderCompletionData.swift | BloomFoundation/Watch/ | Message/response models |
| WatchTodaySyncer.swift | Bloom/Watch/ | iOS-side sync logic |
| WatchMessageRouter.swift | Bloom/Watch/ | Unified message handler |
| TodayProvider.swift | BloomWatch Watch App/Today/ | Watch-side data provider |
| PendingReminderCompletionManager.swift | BloomWatch Watch App/Today/ | Offline queue manager |
| WatchReminderCell.swift | BloomWatch Watch App/Today/Components/ | Reminder cell UI |

## Files to Modify

| File | Change |
|------|--------|
| WatchChannel.swift | Add `todayDataKey` constant |
| BloomApp.swift | Add `.onForegroundTask` for sync trigger |
| BloomWatchApp.swift | Add pending completions sync on launch |
| RootView.swift | Uncomment TodayTabView in TabView |
| TodayTabView.swift | Replace placeholder with full implementation |

## Success Metrics

1. Reminders sync within 2 seconds of iOS app foreground
2. Completion reflected on iOS within 1 second (when phone reachable)
3. Offline completions sync successfully when connection restored
4. Zero data loss for queued completions

## Testing Plan

1. **Sync Flow**: Create reminder on iOS → verify appears on watch
2. **Completion**: Tap reminder on watch → verify iOS shows completed
3. **Offline Queue**: Complete on watch with airplane mode → disable → verify sync
4. **Empty States**: Delete all reminders → verify appropriate UI
5. **Advice Display**: Verify AI advice syncs and displays correctly
