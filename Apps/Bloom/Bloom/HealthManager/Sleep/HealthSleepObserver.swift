//
//  HealthSleepObserver.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-11.
//

import Foundation
import HealthKit
import CoreHealth

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

    if
      (newLastSleepAnalysis?.endDate ?? .distantPast) > (previousSleepAnalysis?.endDate ?? .distantPast) &&
        previousSleepAnalysis != nil
    {
      // We've triggered from new data, not from app launch
      // Check if user has Bloom Plus before triggering report
      let hasBloomPro = await EntitlementController.shared.hasBloomPro
      if hasBloomPro == true {
        await ReportCoordinator.shared.didDetectWakeUp(sleepAnalysis: newLastSleepAnalysis)
      }
    }

    lastSleepAnalysis = newLastSleepAnalysis
  }
}
