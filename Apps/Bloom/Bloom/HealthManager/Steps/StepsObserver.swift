//
//  StepsObserver.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-30.
//

import Foundation
import HealthKit
import CoreHealth

actor StepsObserver {
  static let shared = StepsObserver()

  private var observerHandle: HKObserverQueryHandle?

  private let healthStore = HKHealthStore()

  private init() { }

  func startObserving() async {
    guard observerHandle == nil else { return }

    let stepType = HKQuantityType(.stepCount)

    // Observe step changes from start of current week (foreground only)
    var calendar = Calendar.current
    calendar.firstWeekday = 1  // Sunday
    let startOfWeek = calendar.date(
      from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
    ) ?? Date()

    observerHandle = healthStore.observeChanges(
      sampleType: stepType,
      startDate: startOfWeek
    ) {
      await YouStatsCalculator.shared.refreshSteps()
    }
  }

  func stopObserving() {
    observerHandle = nil
  }
}
