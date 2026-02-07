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

  @AsyncStreamable public var menstrualSummary: MenstrualSummary?

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
    menstrualSummary = await HealthStoreFetcher.shared.fetchMenstrualSummary()

    await createVitals()
  }

  func forceFectchMenstrualSummary() async {
    menstrualSummary = await HealthStoreFetcher.shared.fetchMenstrualSummary()

    await createVitals()
  }

  func recalculateVitals() async {
    await createVitals()
  }

}

private extension VitalsCalculator {

  func createVitals() async {
    var vitals = [VitalModel]()
    if await HealthManager.shared.sex() == .female {
      if let menstrualSummary {
        vitals.append(
          VitalModel(
            id: .cycleTracking,
            subtitle: menstrualSummary.subtitle,
            status: menstrualSummary.phaseName,
            color: menstrualSummary.color,
            barLevel: nil,
            hasNoData: menstrualSummary.hasNoData
          )
        )
      } else {
        vitals.append(VitalModel(id: .cycleTracking))
      }
    }

    vitals.sort(by: { lhs, rhs in
      guard let lhsLevel = lhs.barLevel else { return false }
      guard let rhsLevel = rhs.barLevel else { return true }

      return lhsLevel < rhsLevel
    })

    self.vitals = vitals
  }
}
