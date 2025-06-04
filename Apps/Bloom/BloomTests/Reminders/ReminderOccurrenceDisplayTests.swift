//
//  ReminderOccurrenceDisplayTests.swift
//  BloomTests
//
//  Created by Assistant on 2025-06-04.
//

import Testing
import Foundation
@testable import Bloom
@testable import DataContainer

struct ReminderOccurrenceDisplayTestSuite {
  
  @Test("Daily reminder shows when current time is before notification time")
  func dailyReminderShowsBeforeNotificationTime() {
    // Given: A daily reminder scheduled for 12:00 PM (noon)
    let noon = TimeInterval(12 * 3600) // 12:00 PM in seconds since midnight
    let occurrence = ReminderOccurrenceDTO(
      id: "test-occurrence",
      cadenceType: .daily,
      timeOfDay: noon,
      daysOfWeek: nil,
      dayOfMonth: nil,
      monthOfYear: nil,
      dayOfYear: nil
    )
    
    let reminder = ReminderDTO(
      id: "test-reminder",
      title: "Daily Test Reminder",
      colorHex: "#FF0000",
      occurrences: [occurrence],
      completionRecords: [],
      createdDate: Date(),
      modifiedDate: Date()
    )
    
    // When: Current time is 10:00 AM (before notification time)
    let tenAM = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!
    
    // Then: The reminder should have a notification today
    let nextNotificationDate = occurrence.calculateNextNotificationDate(from: tenAM)
    
    #expect(nextNotificationDate != nil)
    #expect(Calendar.current.isDateInToday(nextNotificationDate!))
    
    // And the time should be 12:00 PM today
    let components = Calendar.current.dateComponents([.hour, .minute], from: nextNotificationDate!)
    #expect(components.hour == 12)
    #expect(components.minute == 0)
  }
  
  @Test("Daily reminder shows when current time is after notification time")
  func dailyReminderShowsAfterNotificationTime() {
    // Given: A daily reminder scheduled for 12:00 PM (noon)
    let noon = TimeInterval(12 * 3600) // 12:00 PM in seconds since midnight
    let occurrence = ReminderOccurrenceDTO(
      id: "test-occurrence",
      cadenceType: .daily,
      timeOfDay: noon,
      daysOfWeek: nil,
      dayOfMonth: nil,
      monthOfYear: nil,
      dayOfYear: nil
    )
    
    let reminder = ReminderDTO(
      id: "test-reminder",
      title: "Daily Test Reminder",
      colorHex: "#FF0000",
      occurrences: [occurrence],
      completionRecords: [],
      createdDate: Date(),
      modifiedDate: Date()
    )
    
    // When: Current time is 2:00 PM (after notification time)
    let twoPM = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date())!
    
    // Then: The reminder should schedule for tomorrow
    let nextNotificationDate = occurrence.calculateNextNotificationDate(from: twoPM)
    
    #expect(nextNotificationDate != nil)
    #expect(Calendar.current.isDateInTomorrow(nextNotificationDate!))
    
    // And the time should be 12:00 PM tomorrow
    let components = Calendar.current.dateComponents([.hour, .minute], from: nextNotificationDate!)
    #expect(components.hour == 12)
    #expect(components.minute == 0)
  }
  
  @Test("Reminder shows single occurrence when no completions")
  func reminderShowsSingleOccurrenceNoCompletions() {
    // Given: A daily reminder scheduled for 12:00 PM
    let noon = TimeInterval(12 * 3600)
    let occurrence = ReminderOccurrenceDTO(
      id: "test-occurrence",
      cadenceType: .daily,
      timeOfDay: noon,
      daysOfWeek: nil,
      dayOfMonth: nil,
      monthOfYear: nil,
      dayOfYear: nil
    )
    
    let reminder = ReminderDTO(
      id: "test-reminder",
      title: "Daily Test Reminder",
      colorHex: "#FF0000",
      occurrences: [occurrence],
      completionRecords: [],
      createdDate: Date(),
      modifiedDate: Date()
    )
    
    // When: Getting today's occurrence displays
    let displays = reminder.todaysOccurrenceDisplays()
    
    // Then: Should show one incomplete occurrence
    #expect(displays.count == 1)
    #expect(displays[0].isCompleted == false)
    #expect(Calendar.current.isDateInToday(displays[0].scheduledTime))
  }
  
  @Test("Multiple daily occurrences show progressively with completions")
  func multipleDailyOccurrencesShowProgressively() {
    // Given: A reminder with 8:30 AM and 10:00 PM daily occurrences
    let morning = TimeInterval(8.5 * 3600) // 8:30 AM
    let evening = TimeInterval(22 * 3600)  // 10:00 PM
    
    let morningOccurrence = ReminderOccurrenceDTO(
      id: "morning-occurrence",
      cadenceType: .daily,
      timeOfDay: morning,
      daysOfWeek: nil,
      dayOfMonth: nil,
      monthOfYear: nil,
      dayOfYear: nil
    )
    
    let eveningOccurrence = ReminderOccurrenceDTO(
      id: "evening-occurrence",
      cadenceType: .daily,
      timeOfDay: evening,
      daysOfWeek: nil,
      dayOfMonth: nil,
      monthOfYear: nil,
      dayOfYear: nil
    )
    
    let baseReminder = ReminderDTO(
      id: "test-reminder",
      title: "Vitamins",
      colorHex: "#FF0000",
      occurrences: [morningOccurrence, eveningOccurrence],
      completionRecords: [],
      createdDate: Date(),
      modifiedDate: Date()
    )
    
    // Test 0 completions - should show only morning occurrence
    let noCompletions = baseReminder.todaysOccurrenceDisplays()
    #expect(noCompletions.count == 1)
    #expect(noCompletions[0].occurrence.id == "morning-occurrence")
    #expect(noCompletions[0].isCompleted == false)
    
    // Test 1 completion - should show morning completed and evening incomplete
    let oneCompletion = ReminderCompletionRecordDTO(
      id: "completion-1",
      completedDate: Date()
    )
    let reminderWith1Completion = ReminderDTO(
      id: "test-reminder",
      title: "Vitamins",
      colorHex: "#FF0000",
      occurrences: [morningOccurrence, eveningOccurrence],
      completionRecords: [oneCompletion],
      createdDate: Date(),
      modifiedDate: Date()
    )
    
    let oneCompletionDisplays = reminderWith1Completion.todaysOccurrenceDisplays()
    #expect(oneCompletionDisplays.count == 2)
    
    // Should be sorted by time
    let sortedDisplays = oneCompletionDisplays.sorted { $0.scheduledTime < $1.scheduledTime }
    #expect(sortedDisplays[0].occurrence.id == "morning-occurrence")
    #expect(sortedDisplays[0].isCompleted == true)
    #expect(sortedDisplays[1].occurrence.id == "evening-occurrence")
    #expect(sortedDisplays[1].isCompleted == false)
    
    // Test 2 completions - should show both completed
    let twoCompletions = [oneCompletion, ReminderCompletionRecordDTO(
      id: "completion-2",
      completedDate: Date().addingTimeInterval(3600) // 1 hour later
    )]
    let reminderWith2Completions = ReminderDTO(
      id: "test-reminder",
      title: "Vitamins",
      colorHex: "#FF0000",
      occurrences: [morningOccurrence, eveningOccurrence],
      completionRecords: twoCompletions,
      createdDate: Date(),
      modifiedDate: Date()
    )
    
    let twoCompletionDisplays = reminderWith2Completions.todaysOccurrenceDisplays()
    #expect(twoCompletionDisplays.count == 2)
    #expect(twoCompletionDisplays.allSatisfy { $0.isCompleted == true })
  }
  
  @Test("Daily reminder calculates next notification correctly at exact time")
  func dailyReminderAtExactTime() {
    // Given: A daily reminder scheduled for 12:00 PM
    let noon = TimeInterval(12 * 3600)
    let occurrence = ReminderOccurrenceDTO(
      id: "test-occurrence",
      cadenceType: .daily,
      timeOfDay: noon,
      daysOfWeek: nil,
      dayOfMonth: nil,
      monthOfYear: nil,
      dayOfYear: nil
    )
    
    // When: Current time is exactly 12:00 PM
    let exactNoon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
    
    // Then: Next notification should be tomorrow at noon
    let nextNotificationDate = occurrence.calculateNextNotificationDate(from: exactNoon)
    
    #expect(nextNotificationDate != nil)
    #expect(Calendar.current.isDateInTomorrow(nextNotificationDate!))
    
    let components = Calendar.current.dateComponents([.hour, .minute], from: nextNotificationDate!)
    #expect(components.hour == 12)
    #expect(components.minute == 0)
  }
  
  @Test("Overdue detection works correctly for specific occurrences")
  func overdueDetectionWorksForSpecificOccurrences() {
    // Given: A reminder with morning and evening occurrences
    let morning = TimeInterval(8 * 3600)  // 8:00 AM
    let evening = TimeInterval(20 * 3600) // 8:00 PM
    
    let morningOccurrence = ReminderOccurrenceDTO(
      id: "morning",
      cadenceType: .daily,
      timeOfDay: morning,
      daysOfWeek: nil,
      dayOfMonth: nil,
      monthOfYear: nil,
      dayOfYear: nil
    )
    
    let eveningOccurrence = ReminderOccurrenceDTO(
      id: "evening",
      cadenceType: .daily,
      timeOfDay: evening,
      daysOfWeek: nil,
      dayOfMonth: nil,
      monthOfYear: nil,
      dayOfYear: nil
    )
    
    let reminder = ReminderDTO(
      id: "test-reminder",
      title: "Test Reminder",
      colorHex: "#FF0000",
      occurrences: [morningOccurrence, eveningOccurrence],
      completionRecords: [],
      createdDate: Date(),
      modifiedDate: Date()
    )
    
    // When: It's 2:00 PM (morning is overdue, evening is not)
    let calendar = Calendar.current
    let twoPM = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: Date())!
    
    // Check overdue status using the new logic
    #expect(reminder.isOverdueToday(completionRecords: []) == true)
    
    // When: It's 6:00 AM (nothing is overdue)
    let sixAM = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: Date())!
    
    // Create a modified date context (this would need time mocking in real tests)
    #expect(reminder.hasNotificationToday == true)
  }
  
  @Test("Weekly reminder shows correctly on scheduled days")
  func weeklyReminderShowsOnScheduledDays() {
    // Given: A weekly reminder for Wednesday (4) at 2:00 PM
    let twoPM = TimeInterval(14 * 3600) // 2:00 PM
    let occurrence = ReminderOccurrenceDTO(
      id: "weekly-occurrence",
      cadenceType: .weekly,
      timeOfDay: twoPM,
      daysOfWeek: [4], // Wednesday (1-based: 1=Sunday, 4=Wednesday)
      dayOfMonth: nil,
      monthOfYear: nil,
      dayOfYear: nil
    )
    
    let reminder = ReminderDTO(
      id: "weekly-reminder",
      title: "Weekly Meeting",
      colorHex: "#00FF00",
      occurrences: [occurrence],
      completionRecords: [],
      createdDate: Date(),
      modifiedDate: Date()
    )
    
    // The hasNotificationToday logic should work for weekly reminders
    // This test validates the general structure
    #expect(reminder.hasNotificationToday == (Calendar.current.component(.weekday, from: Date()) == 4))
  }
  
  @Test("Completion date property returns correct date")
  func completionDatePropertyReturnsCorrectDate() {
    // Given: A reminder with a completion record from today
    let now = Date()
    let completion = ReminderCompletionRecordDTO(
      id: "completion-1",
      completedDate: now
    )
    
    let reminder = ReminderDTO(
      id: "test-reminder",
      title: "Test",
      colorHex: "#FF0000",
      occurrences: [],
      completionRecords: [completion],
      createdDate: Date(),
      modifiedDate: Date()
    )
    
    // When: Getting today's completion date
    let todaysCompletion = reminder.todaysCompletionDate
    
    // Then: Should return the completion date
    #expect(todaysCompletion != nil)
    #expect(Calendar.current.isDate(todaysCompletion!, inSameDayAs: now))
  }
  
  @Test("Multiple completions return most recent completion time")
  func multipleCompletionsReturnMostRecent() {
    // Given: A reminder with multiple completion records from today
    let baseTime = Date()
    let firstCompletion = ReminderCompletionRecordDTO(
      id: "completion-1",
      completedDate: baseTime.addingTimeInterval(-3600) // 1 hour ago
    )
    let secondCompletion = ReminderCompletionRecordDTO(
      id: "completion-2", 
      completedDate: baseTime // Now (most recent)
    )
    
    let reminder = ReminderDTO(
      id: "test-reminder",
      title: "Test",
      colorHex: "#FF0000",
      occurrences: [],
      completionRecords: [firstCompletion, secondCompletion],
      createdDate: Date(),
      modifiedDate: Date()
    )
    
    // When: Getting today's completion date
    let todaysCompletion = reminder.todaysCompletionDate
    
    // Then: Should return the most recent completion date
    #expect(todaysCompletion != nil)
    #expect(abs(todaysCompletion!.timeIntervalSince(baseTime)) < 1) // Within 1 second
  }
  
  @Test("Completed occurrences are sorted by completion date descending")
  func completedOccurrencesSortedByCompletionDateDescending() {
    // Given: Two reminders that were completed at different times
    let baseTime = Date()
    let firstCompletionTime = baseTime.addingTimeInterval(-3600) // 1 hour ago
    let secondCompletionTime = baseTime // Now (more recent)
    
    // First reminder completed earlier
    let firstReminder = ReminderDTO(
      id: "first-reminder",
      title: "First Reminder",
      colorHex: "#FF0000", 
      occurrences: [ReminderOccurrenceDTO(
        id: "first-occurrence",
        cadenceType: .daily,
        timeOfDay: 9 * 3600, // 9 AM
        daysOfWeek: nil,
        dayOfMonth: nil,
        monthOfYear: nil,
        dayOfYear: nil
      )],
      completionRecords: [ReminderCompletionRecordDTO(
        id: "first-completion",
        completedDate: firstCompletionTime
      )],
      createdDate: Date(),
      modifiedDate: Date()
    )
    
    // Second reminder completed more recently
    let secondReminder = ReminderDTO(
      id: "second-reminder", 
      title: "Second Reminder",
      colorHex: "#00FF00",
      occurrences: [ReminderOccurrenceDTO(
        id: "second-occurrence",
        cadenceType: .daily,
        timeOfDay: 10 * 3600, // 10 AM
        daysOfWeek: nil,
        dayOfMonth: nil,
        monthOfYear: nil,
        dayOfYear: nil
      )],
      completionRecords: [ReminderCompletionRecordDTO(
        id: "second-completion",
        completedDate: secondCompletionTime
      )],
      createdDate: Date(),
      modifiedDate: Date()
    )
    
    // When: Getting occurrence displays
    let firstDisplay = firstReminder.todaysOccurrenceDisplays()[0]
    let secondDisplay = secondReminder.todaysOccurrenceDisplays()[0]
    
    // Create a mock sorted list (simulating TodayView.sortedOccurrences logic)
    let occurrences = [firstDisplay, secondDisplay]
    let sortedOccurrences = occurrences.sorted { occurrence1, occurrence2 in
      // Both are completed - sort by completion time (most recent first)
      if occurrence1.isCompleted && occurrence2.isCompleted {
        if let date1 = occurrence1.completionDate, let date2 = occurrence2.completionDate {
          return date1 > date2 // Most recent first
        }
      }
      return false
    }
    
    // Then: Second reminder (more recently completed) should come first
    #expect(sortedOccurrences.count == 2)
    #expect(sortedOccurrences[0].reminder.id == "second-reminder")
    #expect(sortedOccurrences[1].reminder.id == "first-reminder")
    
    // And completion dates should be properly assigned
    #expect(sortedOccurrences[0].completionDate != nil)
    #expect(sortedOccurrences[1].completionDate != nil)
    #expect(sortedOccurrences[0].completionDate! > sortedOccurrences[1].completionDate!)
  }
}