//
//  HealthSleepObserver.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-11.
//

import Foundation
import HealthKit
import CoreHealth

private extension String {
  static let lastSleepAnalysisKey = "HealthSleepObserver.lastSleepAnalysis"
}

public final actor HealthSleepObserver {
  public static let shared = HealthSleepObserver()

  private var sleepObserverQueryHandle: HKObserverQueryHandle?
  private var sleepBackgroundDeliveryHandle: HKBackgroundDeliveryHandle?

  private let healthStore = HKHealthStore()

  private var lastSleepAnalysis: SleepAnalysis?

  private init() { }
}

public extension HealthSleepObserver {

  func observeSleep() async {
    loadSleepAnalysis()

    sleepBackgroundDeliveryHandle = await HealthStoreFetcher.shared.enableBackgroundDelivery(
      objectType: HKCategoryType(.sleepAnalysis),
      frequency: .immediate
    )

    sleepObserverQueryHandle = healthStore.observeChanges(
      sampleType: HKCategoryType(.sleepAnalysis),
      startDate: Calendar.current.date(byAdding: .month, value: -2, to: .now) ?? .now
    ) { [weak self] in
      await self?.handleNewSleepData()
    }
  }
}

private extension HealthSleepObserver {

  func handleNewSleepData() async {
    let previousSleepAnalysis = lastSleepAnalysis

    let sleepAnalyses = await HealthStoreFetcher.shared.fetchSleepAnalysis(dateRange: .trailingDaysFromNow(3))

    let newLastSleepAnalysis = sleepAnalyses.last

    if newLastSleepAnalysis?.overallMinutesIncludingAwake != previousSleepAnalysis?.overallMinutesIncludingAwake && previousSleepAnalysis != nil {
      // Clear stale insights and trigger refresh when new sleep data is available
      await TodayInsightsManager.shared.forceRefreshContent()
    }

    lastSleepAnalysis = newLastSleepAnalysis
    saveSleepAnalysis()
  }

  func loadSleepAnalysis() {
    guard let data = UserDefaults.standard.data(forKey: .lastSleepAnalysisKey),
          let sleepAnalysis = try? JSONDecoder().decode(SleepAnalysis.self, from: data) else {
      return
    }
    lastSleepAnalysis = sleepAnalysis
  }

  func saveSleepAnalysis() {
    guard let sleepAnalysis = lastSleepAnalysis,
          let data = try? JSONEncoder().encode(sleepAnalysis) else {
      UserDefaults.standard.removeObject(forKey: .lastSleepAnalysisKey)
      return
    }
    UserDefaults.standard.set(data, forKey: .lastSleepAnalysisKey)
  }
}
