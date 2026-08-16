//
//  ReminderScheduleTests.swift
//  BloomTests
//

import Testing
import Foundation
import BloomFoundation

@Suite("Reminder schedule")
struct ReminderScheduleTests {

  /// Fixed calendar so a test doesn't change meaning with the machine's timezone.
  private var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/Toronto")!
    return calendar
  }

  /// 2026-08-12 is a Wednesday (weekday 4).
  private func date(day: Int = 12, hour: Int, minute: Int = 0) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: 8, day: day, hour: hour, minute: minute))!
  }

  private func rule(
    id: String = "occurrence-1",
    cadence: ReminderCadence = .daily,
    hour: Int,
    minute: Int = 0,
    daysOfWeek: [Int]? = nil,
    dayOfMonth: Int? = nil,
    monthOfYear: Int? = nil,
    dayOfYear: Int? = nil
  ) -> ReminderOccurrenceRule {
    ReminderOccurrenceRule(
      id: id,
      cadence: cadence,
      timeOfDay: TimeInterval(hour * 3600 + minute * 60),
      daysOfWeek: daysOfWeek,
      dayOfMonth: dayOfMonth,
      monthOfYear: monthOfYear,
      dayOfYear: dayOfYear
    )
  }

  private func plan(
    id: String = "reminder-1",
    occurrences: [ReminderOccurrenceRule],
    completions: [ReminderCompletionMark] = []
  ) -> ReminderPlan {
    ReminderPlan(
      id: id,
      title: "Take vitamins",
      colorHex: "#FF0000",
      occurrences: occurrences,
      completions: completions
    )
  }

  // MARK: - Scheduled times

  @Test("Daily rules fire every day at their time")
  func dailyFiresToday() {
    let times = ReminderSchedule.scheduledTimes(for: rule(hour: 9), on: date(hour: 3), calendar: calendar)

    #expect(times == [date(hour: 9)])
  }

  @Test("Weekly rules only fire on their weekdays")
  func weeklyOnlyOnSelectedDays() {
    // Wednesday is weekday 4; the rule is Monday (2) and Friday (6).
    let mondayAndFriday = rule(cadence: .weekly, hour: 8, daysOfWeek: [2, 6])

    #expect(ReminderSchedule.scheduledTimes(for: mondayAndFriday, on: date(hour: 3), calendar: calendar).isEmpty)

    let wednesday = rule(cadence: .weekly, hour: 8, daysOfWeek: [4])
    #expect(ReminderSchedule.scheduledTimes(for: wednesday, on: date(hour: 3), calendar: calendar) == [date(hour: 8)])
  }

  @Test("Monthly and yearly rules match the day they're set to")
  func monthlyAndYearly() {
    let twelfth = rule(cadence: .monthly, hour: 7, dayOfMonth: 12)
    let thirteenth = rule(cadence: .monthly, hour: 7, dayOfMonth: 13)

    #expect(ReminderSchedule.scheduledTimes(for: twelfth, on: date(hour: 1), calendar: calendar) == [date(hour: 7)])
    #expect(ReminderSchedule.scheduledTimes(for: thirteenth, on: date(hour: 1), calendar: calendar).isEmpty)

    let augustTwelfth = rule(cadence: .yearly, hour: 7, monthOfYear: 8, dayOfYear: 12)
    let julyTwelfth = rule(cadence: .yearly, hour: 7, monthOfYear: 7, dayOfYear: 12)

    #expect(ReminderSchedule.scheduledTimes(for: augustTwelfth, on: date(hour: 1), calendar: calendar).isNotEmpty)
    #expect(ReminderSchedule.scheduledTimes(for: julyTwelfth, on: date(hour: 1), calendar: calendar).isEmpty)
  }

  // MARK: - Status

  @Test("Status follows the clock, not a synced value")
  func statusFollowsClock() {
    let scheduled = date(hour: 9)

    #expect(ReminderSchedule.status(scheduledTime: scheduled, isCompleted: false, now: date(hour: 8)) == .upcoming)
    #expect(ReminderSchedule.status(scheduledTime: scheduled, isCompleted: false, now: scheduled) == .dueNow)
    #expect(ReminderSchedule.status(
      scheduledTime: scheduled,
      isCompleted: false,
      now: scheduled.addingTimeInterval(14 * 60)
    ) == .dueNow)
    #expect(ReminderSchedule.status(
      scheduledTime: scheduled,
      isCompleted: false,
      now: scheduled.addingTimeInterval(16 * 60)
    ) == .overdue)
    #expect(ReminderSchedule.status(scheduledTime: scheduled, isCompleted: true, now: date(hour: 23)) == .completed)
  }

  // MARK: - Slots

  @Test("Occurrences show once their time has passed; later outstanding ones stay hidden")
  func hidesLaterOutstandingOccurrences() {
    let morning = rule(id: "morning", hour: 8)
    let noon = rule(id: "noon", hour: 12)
    let evening = rule(id: "evening", hour: 20)

    let slots = ReminderSchedule.slots(
      for: plan(occurrences: [morning, noon, evening]),
      now: date(hour: 13),
      calendar: calendar
    )

    // 8am and noon have passed. 8pm stays hidden: an earlier occurrence is still outstanding,
    // so there's nothing to act on at 8pm yet.
    #expect(slots.map(\.occurrenceID) == ["morning", "noon"])

    let earlySlots = ReminderSchedule.slots(
      for: plan(occurrences: [morning, noon, evening]),
      now: date(hour: 6),
      calendar: calendar
    )

    // Nothing has passed yet, so only the first outstanding one shows.
    #expect(earlySlots.map(\.occurrenceID) == ["morning"])
  }

  @Test("Completions only count on the day they were made")
  func completionsAreDayScoped() {
    let morning = rule(id: "morning", hour: 8)
    let yesterday = ReminderCompletionMark(occurrenceID: "morning", completedDate: date(day: 11, hour: 8, minute: 30))
    let today = ReminderCompletionMark(occurrenceID: "morning", completedDate: date(hour: 8, minute: 30))

    let stale = ReminderSchedule.slots(
      for: plan(occurrences: [morning], completions: [yesterday]),
      now: date(hour: 9),
      calendar: calendar
    )
    #expect(stale.first?.isCompleted == false)
    #expect(stale.first?.status == .overdue)

    let fresh = ReminderSchedule.slots(
      for: plan(occurrences: [morning], completions: [today]),
      now: date(hour: 9),
      calendar: calendar
    )
    #expect(fresh.first?.isCompleted == true)
    #expect(fresh.first?.status == .completed)
  }

  @Test("A completion only applies to its own occurrence")
  func completionsAreOccurrenceScoped() {
    let morning = rule(id: "morning", hour: 8)
    let noon = rule(id: "noon", hour: 12)
    let completedMorning = ReminderCompletionMark(occurrenceID: "morning", completedDate: date(hour: 8, minute: 5))

    let slots = ReminderSchedule.slots(
      for: plan(occurrences: [morning, noon], completions: [completedMorning]),
      now: date(hour: 13),
      calendar: calendar
    )

    #expect(slots.first { $0.occurrenceID == "morning" }?.isCompleted == true)
    #expect(slots.first { $0.occurrenceID == "noon" }?.isCompleted == false)
  }

  // MARK: - Ordering

  @Test("Outstanding occurrences sort by urgency, completed ones sink")
  func sortsByUrgency() {
    let now = date(hour: 12, minute: 30)

    let overdue = plan(id: "overdue", occurrences: [rule(id: "o", hour: 8)])
    let dueNow = plan(id: "due", occurrences: [rule(id: "d", hour: 12, minute: 25)])
    let upcoming = plan(id: "upcoming", occurrences: [rule(id: "u", hour: 18)])
    let completed = plan(
      id: "completed",
      occurrences: [rule(id: "c", hour: 7)],
      completions: [ReminderCompletionMark(occurrenceID: "c", completedDate: date(hour: 7, minute: 5))]
    )

    let slots = ReminderSchedule.slots(
      for: [upcoming, completed, dueNow, overdue],
      now: now,
      calendar: calendar
    )

    #expect(slots.map(\.reminderID) == ["overdue", "due", "upcoming", "completed"])
  }

  // MARK: - Local overrides

  @Test("A local completion overrides what the phone sent")
  func localOverrideWins() {
    let morning = rule(id: "morning", hour: 8)
    let synced = plan(occurrences: [morning])

    let override = ReminderCompletionOverride(
      reminderID: "reminder-1",
      occurrenceID: "morning",
      isCompleted: true,
      date: date(hour: 8, minute: 30)
    )

    let overridden = ReminderSchedule.applying([override], to: synced)
    let slots = ReminderSchedule.slots(for: overridden, now: date(hour: 9), calendar: calendar)

    #expect(slots.first?.isCompleted == true)
  }

  @Test("A local uncomplete clears a completion the phone sent")
  func localUncompleteWins() {
    let morning = rule(id: "morning", hour: 8)
    let synced = plan(
      occurrences: [morning],
      completions: [ReminderCompletionMark(occurrenceID: "morning", completedDate: date(hour: 8, minute: 10))]
    )

    let override = ReminderCompletionOverride(
      reminderID: "reminder-1",
      occurrenceID: "morning",
      isCompleted: false,
      date: date(hour: 9)
    )

    let overridden = ReminderSchedule.applying([override], to: synced)
    let slots = ReminderSchedule.slots(for: overridden, now: date(hour: 10), calendar: calendar)

    #expect(slots.first?.isCompleted == false)
    #expect(slots.first?.status == .overdue)
  }
}
