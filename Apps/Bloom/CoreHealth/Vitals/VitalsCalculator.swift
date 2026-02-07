//
//  VitalsCalculator.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-10.
//

import Foundation
import DataContainer
import BloomFoundation
import HealthKit

public final actor VitalsCalculator {
  public static let shared = VitalsCalculator()

  @AsyncStreamable public var vitals = [VitalModel]()

  private init() {
    if let date = UserDefaults.group.object(forKey: "VitalsCalculator.lastVitalFetchDate") as? Date {
      lastVitalFetchDate = date
    }
  }

  private var lastVitalFetchDate: Date? {
    didSet {
      UserDefaults.group.set(lastVitalFetchDate, forKey: "VitalsCalculator.lastVitalFetchDate")
    }
  }
}

public extension VitalsCalculator {

  func refreshVitals() async {
    if vitals.isNotEmpty {
      if let lastVitalFetchDate {
        let minutes = Calendar.current.dateComponents([.minute], from: lastVitalFetchDate, to: .now).minute ?? 0

        if minutes < 3 {
          print("Returning early since we, like, just fetched vitals.")
          return
        }
      }
    }

    await forceFetchVitals()
  }

  func forceFetchVitals() async {
    await createVitals()
  }

  func recalculateVitals() async {
    await createVitals()
  }

}

private extension VitalsCalculator {

  func createVitals() async {
    let vitals = [VitalModel]()
    self.vitals = vitals
  }
}
