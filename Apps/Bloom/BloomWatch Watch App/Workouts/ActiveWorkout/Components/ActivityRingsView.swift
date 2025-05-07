//
//  ActivityRingsView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-06.
//

import Foundation
@preconcurrency import HealthKit
@preconcurrency import SwiftUI

struct ActivityRingsView: WKInterfaceObjectRepresentable {
  @Environment(\.calendar) private var calendar
  let healthStore: HKHealthStore

  func makeWKInterfaceObject(context: Context) -> some WKInterfaceObject {
    let activityRingsObject = WKInterfaceActivityRing()
    var components = calendar.dateComponents([.era, .year, .month, .day], from: Date())
    components.calendar = calendar

    let predicate = HKQuery.predicateForActivitySummary(with: components)
    let query = HKActivitySummaryQuery(predicate: predicate) { query, summaries, error in
      let firstSummary = summaries?.first
      Task { @MainActor in
        activityRingsObject.setActivitySummary(firstSummary, animated: true)
      }
    }

    healthStore.execute(query)
    return activityRingsObject
  }

  func updateWKInterfaceObject(_ wkInterfaceObject: WKInterfaceObjectType, context: Context) {
  }
}
