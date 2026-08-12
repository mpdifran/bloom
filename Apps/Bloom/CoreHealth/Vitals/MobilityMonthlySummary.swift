//
//  MobilityMonthlySummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-25.
//

import SwiftUI
import HealthKit
import DataContainer

private extension Double {
  static let lowerDoubleSupportTime: Double = 0.4
  static let upperDoubleSupportTime: Double = 0.8
  static let lowerSixMinuteWalk: Double = 100
  static let upperSixMinuteWalk: Double = 500
  static let maxWalkingSteadiness: Double = 6
}

public extension MobilityMonthlySummary {
  enum Status {
    case unknown
    case poor
    case concern
    case good
    case excellent

    public var name: String {
      switch self {
      case .unknown: String(localized: "Unknown", bundle: Bundle.coreHealth)
      case .poor: String(localized: "Poor", bundle: Bundle.coreHealth)
      case .concern: String(localized: "Concern", bundle: Bundle.coreHealth)
      case .good: String(localized: "Good", bundle: Bundle.coreHealth)
      case .excellent: String(localized: "Excellent", bundle: Bundle.coreHealth)
      }
    }

    public var color: Color {
      switch self {
      case .unknown: .gray
      case .poor: .vitalSevere
      case .concern: .vitalWarning
      case .good: .vitalGood
      case .excellent: .vitalGreat
      }
    }
  }
}

public struct MobilityMonthlySummary: Equatable {
  public let doubleSupportTimePercent: Double
  public let sixMinuteWalkDistance: Double
  public let walkingSteadiness: [HKCategoryValueAppleWalkingSteadinessEvent]
  public let lastMonthDoubleSupportTimePercent: Double
  public let lastMonthSixMinuteWalkDistance: Double
  public let lastMonthWalkingSteadiness: [HKCategoryValueAppleWalkingSteadinessEvent]

  public init(
    doubleSupportTimePercent: Double,
    sixMinuteWalkDistance: Double,
    walkingSteadiness: [HKCategoryValueAppleWalkingSteadinessEvent],
    lastMonthDoubleSupportTimePercent: Double,
    lastMonthSixMinuteWalkDistance: Double,
    lastMonthWalkingSteadiness: [HKCategoryValueAppleWalkingSteadinessEvent]
  ) {
    self.doubleSupportTimePercent = doubleSupportTimePercent
    self.sixMinuteWalkDistance = sixMinuteWalkDistance
    self.walkingSteadiness = walkingSteadiness
    self.lastMonthDoubleSupportTimePercent = lastMonthDoubleSupportTimePercent
    self.lastMonthSixMinuteWalkDistance = lastMonthSixMinuteWalkDistance
    self.lastMonthWalkingSteadiness = lastMonthWalkingSteadiness
  }
}

public extension MobilityMonthlySummary {

  var score: Double {
    internalScore.scaledPercent(lower: 0.5, upper: 0.9)
  }

  private var internalScore: Double {
    let doubleSupportScore = doubleSupportTimePercent.scaledPercent(
      lower: .upperDoubleSupportTime,
      upper: .lowerDoubleSupportTime
    )
    let walkingScore = sixMinuteWalkDistance.scaledPercent(lower: .lowerSixMinuteWalk, upper: .upperSixMinuteWalk)
    let steadinessEvent = Double(walkingSteadiness
      .map { event in
        switch event {
        case .initialLow: 1
        case .repeatLow: 2
        case .initialVeryLow: 3
        case .repeatVeryLow: 4
        default: 0
        }
      }
      .reduce(0) { $0 + $1 })
    let steadinessScore = steadinessEvent.scaledPercent(lower: .maxWalkingSteadiness, upper: 0)

    return [doubleSupportScore, walkingScore, steadinessScore].average(keyPath: \.self)
  }

  var lastMonthScore: Double {
    let doubleSupportScore = lastMonthDoubleSupportTimePercent.scaledPercent(
      lower: .upperDoubleSupportTime,
      upper: .lowerDoubleSupportTime
    )
    let walkingScore = lastMonthSixMinuteWalkDistance.scaledPercent(lower: .lowerSixMinuteWalk, upper: .upperSixMinuteWalk)
    let steadinessEvent = Double(lastMonthWalkingSteadiness
      .map { event in
        switch event {
        case .initialLow: 1
        case .repeatLow: 2
        case .initialVeryLow: 3
        case .repeatVeryLow: 4
        default: 0
        }
      }
      .reduce(0) { $0 + $1 })
    let steadinessScore = steadinessEvent / .maxWalkingSteadiness

    return [doubleSupportScore, walkingScore, steadinessScore].average(keyPath: \.self)
  }

  var barLevel: VitalModel.BarLevel? {
    return nil // TODO: implement
  }

  var subtitle: String {
    let doubleSupport = "Double Support: \(String(format: "%.0fString(localized: ", doubleSupportTimePercent * 100))%", bundle: Bundle.coreHealth)
    let sixMinuteWalk = "6 Min Walk: \(String(format: "%.0fString(localized: ", sixMinuteWalkDistance))m", bundle: Bundle.coreHealth)
    return [doubleSupport, sixMinuteWalk].joined(separator: String(localized: "\n", bundle: Bundle.coreHealth))
  }

  var status: Status {
    if internalScore < 0.5 {
      return .poor
    } else if internalScore < 0.7 {
      return .concern
    } else if internalScore < 0.9 {
      return .good
    } else {
      return .excellent
    }
  }
}
