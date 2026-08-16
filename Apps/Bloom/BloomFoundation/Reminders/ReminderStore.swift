//
//  ReminderStore.swift
//  BloomFoundation
//

import Foundation

/// A completion made on the watch that the phone hasn't confirmed yet.
public struct ReminderCompletionOverride: Codable, Sendable, Equatable {
  public let reminderID: String
  public let occurrenceID: String
  public let isCompleted: Bool
  public let date: Date

  public init(reminderID: String, occurrenceID: String, isCompleted: Bool, date: Date) {
    self.reminderID = reminderID
    self.occurrenceID = occurrenceID
    self.isCompleted = isCompleted
    self.date = date
  }
}

public extension ReminderSchedule {

  /// Folds locally-made completions into the phone's reminder data.
  static func applying(
    _ overrides: [ReminderCompletionOverride],
    to plan: ReminderPlan
  ) -> ReminderPlan {
    let planOverrides = overrides.filter { $0.reminderID == plan.id }
    guard planOverrides.isNotEmpty else { return plan }

    var completions = plan.completions.filter { completion in
      !planOverrides.contains { $0.occurrenceID == completion.occurrenceID }
    }

    completions.append(contentsOf: planOverrides
      .filter(\.isCompleted)
      .map { ReminderCompletionMark(occurrenceID: $0.occurrenceID, completedDate: $0.date) })

    return ReminderPlan(
      id: plan.id,
      title: plan.title,
      colorHex: plan.colorHex,
      occurrences: plan.occurrences,
      completions: completions
    )
  }

  static func applying(
    _ overrides: [ReminderCompletionOverride],
    to plans: [ReminderPlan]
  ) -> [ReminderPlan] {
    plans.map { applying(overrides, to: $0) }
  }
}

/// Shared storage for the reminder data synced from the phone.
///
/// The watch app and the widget extension both read it, so the rules and the pending completions
/// live in one place rather than being copied between them.
public enum ReminderStore {
  public static let plansKey = "TodayProvider.reminderPlans"
  public static let overridesKey = "TodayProvider.completionOverrides"

  /// The reminder rules the phone last sent, or nil if it has never sent any.
  public static func loadPlans() -> [ReminderPlan]? {
    guard let data = UserDefaults.group.data(forKey: plansKey) else { return nil }
    return try? JSONDecoder.watch.decode([ReminderPlan].self, from: data)
  }

  public static func savePlans(_ plans: [ReminderPlan]?) {
    guard let plans, let data = try? JSONEncoder.watch.encode(plans) else {
      UserDefaults.group.removeObject(forKey: plansKey)
      return
    }
    UserDefaults.group.set(data, forKey: plansKey)
  }

  public static func loadOverrides() -> [ReminderCompletionOverride] {
    guard let data = UserDefaults.group.data(forKey: overridesKey),
          let overrides = try? JSONDecoder.watch.decode([ReminderCompletionOverride].self, from: data) else {
      return []
    }
    return overrides
  }

  public static func saveOverrides(_ overrides: [ReminderCompletionOverride]) {
    guard let data = try? JSONEncoder.watch.encode(overrides) else { return }
    UserDefaults.group.set(data, forKey: overridesKey)
  }

  /// Records a completion made locally, replacing any earlier one for the same occurrence.
  public static func addOverride(_ override: ReminderCompletionOverride) {
    var overrides = loadOverrides()
    overrides.removeAll {
      $0.reminderID == override.reminderID && $0.occurrenceID == override.occurrenceID
    }
    overrides.append(override)
    saveOverrides(overrides)
  }

  /// Today's occurrences resolved from the stored rules, or nil when no rules are stored.
  public static func resolvedSlots(now: Date = Date(), calendar: Calendar = .current) -> [ReminderSlot]? {
    guard let plans = loadPlans() else { return nil }

    let resolved = ReminderSchedule.applying(loadOverrides(), to: plans)
    return ReminderSchedule.slots(for: resolved, now: now, calendar: calendar)
  }
}
