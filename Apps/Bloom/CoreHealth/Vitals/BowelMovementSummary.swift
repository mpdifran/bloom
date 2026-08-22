//
//  BowelMovementSummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-28.
//

import SwiftUI
import DataContainer
import BloomFoundation
import AppFoundations
internal import Algorithms

private enum Constants {
  static let stoolTypeScoreMap = [
    1: 0.7,
    2: 0.95,
    3: 1.1,
    4: 1.1,
    5: 0.95,
    6: 0.7,
    7: 0.2,
  ]
}

public extension BowelMovementSummary {
  enum Rating {
    case poor
    case fair
    case good
    case excellent

    public var name: String {
      switch self {
      case .poor:
        String(localized: "Poor", bundle: Bundle.coreHealth, comment: "Display name for bowel movement summary")
      case .fair:
        String(localized: "Fair", bundle: Bundle.coreHealth, comment: "Display name for bowel movement summary")
      case .good:
        String(localized: "Good", bundle: Bundle.coreHealth, comment: "Display name for bowel movement summary")
      case .excellent:
        String(localized: "Excellent", bundle: Bundle.coreHealth, comment: "Display name for bowel movement summary")
      }
    }

    public var color: Color {
      switch self {
      case .poor:
          .vitalSevere
      case .fair:
          .vitalWarning
      case .good:
          .vitalGood
      case .excellent:
          .vitalGreat
      }
    }
  }
}

public struct BowelMovementSummary: Sendable {
  public let bowelMovements: [BowelMovementDTO]

  public init(bowelMovements: [BowelMovementDTO]) {
    self.bowelMovements = bowelMovements

    self.calculateScore()
  }

  public var hasNoData: Bool {
    bowelMovements.isEmpty
  }

  public var barLevel: VitalModel.BarLevel? {
    guard let rating else { return nil }

    switch rating {
    case .poor:
      return VitalModel.BarLevel(
        level: .low,
        proportion: score.scaledPercent(lower: 0, upper: 0.4)
      )
    case .fair:
      return VitalModel.BarLevel(
        level: .medium,
        proportion: score.scaledPercent(lower: 0.4, upper: 0.6)
      )
    case .good:
      return VitalModel.BarLevel(
        level: .high,
        proportion: score.scaledPercent(lower: 0.6, upper: 0.9)
      )
    case .excellent:
      return VitalModel.BarLevel(
        level: .optimal,
        proportion: score.scaledPercent(lower: 0.9, upper: 1)
      )
    }
  }

  private(set) public var score: Double = 1
  private(set) public var subtitle: String?
  private(set) public var regularityScore: Double = 1
  private(set) public var coefficientOfVariation: Double?
}

public extension BowelMovementSummary {

  mutating func calculateScore() {
    guard bowelMovements.isNotEmpty else {
      return
    }

    var typeAndDurationScores = [Double]()
    var intervalScores = [Double]()
    var previousBowelMovement: BowelMovementDTO?

    for bowelMovement in bowelMovements.sorted(keyPath: \.date) {
      guard let score = Constants.stoolTypeScoreMap[bowelMovement.bristolStoolType] else { continue }

      let typeScore = score * bowelMovement.duration.scoreModifier
      typeAndDurationScores.append(typeScore)

      if let previousBowelMovement {
        let hours = bowelMovement.date.timeIntervalSince(previousBowelMovement.date) / 3600

        let intervalScore: Double
        if hours < 8 {
          intervalScore = Double(hours).scaledPercent(lower: 4, upper: 8)
        } else if hours > 72 {
          intervalScore = Double(hours).scaledPercent(lower: 120, upper: 72)
        } else {
          intervalScore = 1
        }
        
        intervalScores.append(intervalScore)
      }

      previousBowelMovement = bowelMovement
    }
    
    // Calculate regularity score if we have enough data
    let statistics = bowelMovementStatistics()
    if let statistics = statistics, bowelMovements.count >= 3 {
      self.regularityScore = calculateRegularityScore(from: statistics)
      self.coefficientOfVariation = statistics.coefficientOfVariation
    } else {
      self.regularityScore = 1.0
      self.coefficientOfVariation = nil
    }
    
    // Calculate weighted average score
    let avgTypeAndDuration = typeAndDurationScores.average(keyPath: \.self)
    let avgInterval = intervalScores.isEmpty ? 1.0 : intervalScores.average(keyPath: \.self)
    
    // Weighted scoring:
    // 60% Type and Duration (existing weight)
    // 20% Interval (existing)
    // 20% Regularity (new)
    if bowelMovements.count >= 3 && coefficientOfVariation != nil {
      self.score = (avgTypeAndDuration * 0.6) + (avgInterval * 0.2) + (regularityScore * 0.2)
    } else {
      // Fall back to original scoring if insufficient data for regularity
      self.score = (avgTypeAndDuration * 0.75) + (avgInterval * 0.25)
    }
    
    self.subtitle = calculateSubtitle()
  }

  func calculateSubtitle() -> String {
    guard let start = bowelMovements.min(keyPath: \.date) else {
      return "No Data"
    }

    let daySpan = (Calendar.current.dateComponents([.day], from: start, to: .now).day ?? 0) + 1

    let pace = Double(daySpan) / Double(bowelMovements.count)
    let paceFormat = pace.format()
    
    var frequencyText: String
    if paceFormat == "1" {
      frequencyText = "Once a Day"
    } else if pace > 1 {
      frequencyText = "Every \(paceFormat) Days"
    } else {
      let inversePaceFormat = (1 / pace).format(using: .oneDecimalPlace)
      frequencyText = "\(inversePaceFormat)x a Day"
    }
    
    // Add regularity indicator if we have enough data
    if let cv = coefficientOfVariation, bowelMovements.count >= 3 {
      let regularityText: String
      if cv < 0.2 {
        regularityText = "Very Regular"
      } else if cv < 0.4 {
        regularityText = "Regular"
      } else if cv < 0.6 {
        regularityText = "Somewhat Regular"
      } else if cv < 0.8 {
        regularityText = "Irregular"
      } else {
        regularityText = "Very Irregular"
      }
      
      return "\(frequencyText)\n\(regularityText)"
    }

    return frequencyText
  }

  var rating: BowelMovementSummary.Rating? {
    guard bowelMovements.isNotEmpty else {
      return nil
    }

    if score < 0.4 {
      return .poor
    } else if score < 0.6 {
      return .fair
    } else if score < 0.9 {
      return .good
    } else {
      return .excellent
    }
  }

  var timeOfDayDistribution: [Calendar.TimeOfDay: [BowelMovementDTO]] {
    bowelMovements
      .grouped(by: { Calendar.current.timeOfDay(for: $0.date) })
  }

  var stoolTypeDistribution: [Int: [BowelMovementDTO]] {
    bowelMovements.grouped(by: { $0.bristolStoolType })
  }

  func prioritizedBristolStoolType() -> Int {
    var scores = Array(repeating: 0.0, count: 7)

    for (index, bowelMovement) in self.bowelMovements.enumerated() {
      guard bowelMovement.bristolStoolType != 3 && bowelMovement.bristolStoolType != 4 else { continue }

      scores[bowelMovement.bristolStoolType - 1] += Double(index)
    }

    var maxIndex = 0
    var maxScore: Double = 0

    for (index, score) in scores.enumerated() {
      if score > maxScore {
        maxIndex = index
        maxScore = score
      }
    }

    return maxIndex + 1
  }
  
  // MARK: - Regularity Visualization Data
  
  /// Returns interval data for bar chart visualization showing time between movements
  func intervalData() -> [(date: Date, intervalHours: Double)] {
    var intervals = [(date: Date, intervalHours: Double)]()
    var previousBowelMovement: BowelMovementDTO?

    for bowelMovement in bowelMovements.sorted(keyPath: \.date) {
      defer {
        previousBowelMovement = bowelMovement
      }

      guard let previousBowelMovement else { continue }
      
      let hours = bowelMovement.date.timeIntervalSince(previousBowelMovement.date) / 3600
      intervals.append((date: bowelMovement.date, intervalHours: hours))
    }

    return intervals
  }
  
  /// Returns regularity level for a given coefficient of variation
  func regularityLevel(for cv: Double?) -> RegularityLevel {
    guard let cv = cv else { return .unknown }
    
    if cv < 0.2 {
      return .excellent
    } else if cv < 0.4 {
      return .good
    } else if cv < 0.6 {
      return .moderate
    } else if cv < 0.8 {
      return .poor
    } else {
      return .veryPoor
    }
  }
  
  /// Enum for regularity levels with associated colors and names
  enum RegularityLevel: String, CaseIterable {
    case excellent = "Excellent"
    case good = "Good" 
    case moderate = "Moderate"
    case poor = "Poor"
    case veryPoor = "Very Poor"
    case unknown = "Unknown"
    
    /// The user-facing name. `rawValue` stays canonical English — it is a persistence identifier.
    public var displayName: String {
      switch self {
      case .excellent: String(localized: "Excellent", bundle: Bundle.coreHealth, comment: "Display name for bowel movement regularity level")
      case .good: String(localized: "Good", bundle: Bundle.coreHealth, comment: "Display name for bowel movement regularity level")
      case .moderate: String(localized: "Moderate", bundle: Bundle.coreHealth, comment: "Display name for bowel movement regularity level")
      case .poor: String(localized: "Poor", bundle: Bundle.coreHealth, comment: "Display name for bowel movement regularity level")
      case .veryPoor: String(localized: "Very Poor", bundle: Bundle.coreHealth, comment: "Display name for bowel movement regularity level")
      case .unknown: String(localized: "Unknown", bundle: Bundle.coreHealth, comment: "Display name for bowel movement regularity level")
      }
    }

    public var color: Color {
      switch self {
      case .excellent:
        return .vitalGreat
      case .good:
        return .vitalGood
      case .moderate:
        return .vitalWarning
      case .poor, .veryPoor:
        return .vitalSevere
      case .unknown:
        return .secondary
      }
    }
    
    var shortName: String {
      switch self {
      case .veryPoor:
        return String(localized: "Very Poor", bundle: Bundle.coreHealth, comment: "Short display name for bowel movement summary")
      default:
        return displayName
      }
    }
  }
}

private extension BowelMovementSummary {

  struct BowelMovementIntervalStatistics {
    let averageIntervalHours: Double
    let standardDeviationIntervalHours: Double
    
    var coefficientOfVariation: Double? {
      guard averageIntervalHours > 0 else { return nil }
      return standardDeviationIntervalHours / averageIntervalHours
    }
  }

  func bowelMovementStatistics() -> BowelMovementIntervalStatistics? {
    var intervals = [Double]()
    var previousBowelMovement: BowelMovementDTO?

    for bowelMovement in bowelMovements.sorted(keyPath: \.date) {
      defer {
        previousBowelMovement = bowelMovement
      }

      guard
        let previousBowelMovement,
        let hours = Calendar.current.dateComponents([.hour], from: previousBowelMovement.date, to: bowelMovement.date).hour
      else { continue }

      intervals.append(Double(hours))
    }

    let averageInterval = intervals.average(keyPath: \.self)

    guard let standardDeviation = intervals.standardDeviation(keyPath: \.self) else { return nil }

    return BowelMovementIntervalStatistics(
      averageIntervalHours: averageInterval,
      standardDeviationIntervalHours: standardDeviation
    )
  }
  
  func calculateRegularityScore(from statistics: BowelMovementIntervalStatistics) -> Double {
    guard let cv = statistics.coefficientOfVariation else { return 1.0 }
    
    // Lower CV means more regular, higher CV means less regular
    // CV < 0.2: Excellent regularity (score = 1.0)
    // CV 0.2-0.4: Good regularity (score = 0.9)
    // CV 0.4-0.6: Moderate regularity (score = 0.7)
    // CV 0.6-0.8: Poor regularity (score = 0.5)
    // CV > 0.8: Very poor regularity (score = 0.3)
    
    if cv < 0.2 {
      return 1.0
    } else if cv < 0.4 {
      // Linear interpolation between 1.0 and 0.9
      return 1.0 - (cv - 0.2) * 0.5
    } else if cv < 0.6 {
      // Linear interpolation between 0.9 and 0.7
      return 0.9 - (cv - 0.4) * 1.0
    } else if cv < 0.8 {
      // Linear interpolation between 0.7 and 0.5
      return 0.7 - (cv - 0.6) * 1.0
    } else if cv < 1.2 {
      // Linear interpolation between 0.5 and 0.3
      return 0.5 - (cv - 0.8) * 0.5
    } else {
      // Very irregular pattern
      return 0.3
    }
  }
}
