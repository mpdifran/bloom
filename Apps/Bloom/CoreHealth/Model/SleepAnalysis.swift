//
//  SleepAnalysis.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-25.
//

import Foundation

// https://www.mindbodygreen.com/articles/what-is-core-sleep
// https://www.healthline.com/health/how-much-deep-sleep-do-you-need#deep-sleep
extension Double {
  static let coreSleepPercentMin: Double = 0.2
  static let coreSleepPercentMax: Double = 0.45
  static let coreSleepMinMinutes: Double = 84
  static let coreSleepMaxMinutes: Double = 189
  static let deepSleepPercentMin: Double = 0.05
  static let deepSleepPercentMax: Double = 0.15
  static let deepSleepMinMinutes: Double = 21
  static let deepSleepMaxMinutes: Double = 63
  static let remSleepPercentMin: Double = 0.05
  static let remSleepPercentMax: Double = 0.20
  static let remSleepMinMinutes: Double = 21
  static let remSleepMaxMinutes: Double = 84
  static let awakeSleepMinPercent: Double = 0.05
  static let awakeSleepMaxPercent: Double = 0.15
  static let awakeSleepMinMinutes: Double = 21
  static let awakeSleepMaxMinutes: Double = 63
  static let zeroSleepLengthMinutes: Double = 4 * 60
  static let fullSleepLengthMinutes: Double = 7 * 60
  static let minSoundLevel: Double = 35
  static let maxSoundLevel: Double = 60
  static let maxRestingHeartRatePercent: Double = 0.9
  static let minHeartRate: Double = 60
  static let maxHeartRate: Double = 68
  static let maxScore: Double = 100
}

public struct SleepAnalysis: Codable, Hashable, Identifiable, Sendable {
  public var id: String { "\(startDate)-\(endDate)" }

  public let startDate: Date
  public let endDate: Date
  public let hasDetailedSleepCategories: Bool
  public let deepSleepMinutes: Double
  public let coreSleepMinutes: Double
  public let remSleepMinutes: Double
  public let awakeSleepMinutes: Double
  public let averageRestingHeartRate: Double?
  public let environmentalSoundLevels: [SoundLevelDataPoint]
  public let heartRate: [HeartRateDataPoint]
  public let respiratoryRate: [RespiratoryRateDataPoint]
  public let wristTemperature: WristTemperatureDataPoint?

  public init(
    startDate: Date,
    endDate: Date,
    hasDetailedSleepCategories: Bool,
    deepSleepMinutes: Double,
    coreSleepMinutes: Double,
    remSleepMinutes: Double,
    awakeSleepMinutes: Double,
    averageRestingHeartRate: Double?,
    environmentalSoundLevels: [SoundLevelDataPoint],
    heartRate: [HeartRateDataPoint],
    respiratoryRate: [RespiratoryRateDataPoint],
    wristTemperature: WristTemperatureDataPoint?
  ) {
    self.startDate = startDate
    self.endDate = endDate
    self.hasDetailedSleepCategories = hasDetailedSleepCategories
    self.deepSleepMinutes = deepSleepMinutes
    self.coreSleepMinutes = coreSleepMinutes
    self.remSleepMinutes = remSleepMinutes
    self.awakeSleepMinutes = awakeSleepMinutes
    self.averageRestingHeartRate = averageRestingHeartRate
    self.environmentalSoundLevels = environmentalSoundLevels
    self.heartRate = heartRate
    self.respiratoryRate = respiratoryRate
    self.wristTemperature = wristTemperature
  }
}

public extension SleepAnalysis {
  struct SoundLevelDataPoint: Codable, Hashable, Identifiable, Sendable {
    public var id: Int { hashValue }

    public let decibelAWeightedSoundPressureLevelAverage: Double
    public let startDate: Date
    public let timeRangeSeconds: TimeInterval

    public init(
      decibelAWeightedSoundPressureLevelAverage: Double,
      startDate: Date,
      timeRangeSeconds: TimeInterval
    ) {
      self.decibelAWeightedSoundPressureLevelAverage = decibelAWeightedSoundPressureLevelAverage
      self.startDate = startDate
      self.timeRangeSeconds = timeRangeSeconds
    }
  }
}

public extension SleepAnalysis {
  struct HeartRateDataPoint: Codable, Hashable, Identifiable, Sendable {
    public var id: Int { hashValue }

    public let averageHeartRate: Double
    public let startDate: Date
    public let timeRangeSeconds: TimeInterval

    public init(
      averageHeartRate: Double,
      startDate: Date,
      timeRangeSeconds: TimeInterval
    ) {
      self.averageHeartRate = averageHeartRate
      self.startDate = startDate
      self.timeRangeSeconds = timeRangeSeconds
    }
  }
}

public extension SleepAnalysis {
  struct RespiratoryRateDataPoint: Codable, Hashable, Identifiable, Sendable {
    public var id: Int { hashValue }

    public let averageRespiratoryRate: Double
    public let startDate: Date
    public let timeRangeSeconds: TimeInterval

    public init(
      averageRespiratoryRate: Double,
      startDate: Date,
      timeRangeSeconds: TimeInterval
    ) {
      self.averageRespiratoryRate = averageRespiratoryRate
      self.startDate = startDate
      self.timeRangeSeconds = timeRangeSeconds
    }
  }
}

public extension SleepAnalysis {
  struct WristTemperatureDataPoint: Codable, Hashable, Identifiable, Sendable {
    public var id: Int { hashValue }

    public let averageWristTemperature: Double
    public let startDate: Date
    public let timeRangeSeconds: TimeInterval

    public init(
      averageWristTemperature: Double,
      startDate: Date,
      timeRangeSeconds: TimeInterval
    ) {
      self.averageWristTemperature = averageWristTemperature
      self.startDate = startDate
      self.timeRangeSeconds = timeRangeSeconds
    }
  }
}

public extension SleepAnalysis {

  var beginningOfStartDate: Date {
    Calendar.current.startOfDay(for: startDate)
  }

  var normalizedDate: Date {
    Calendar.current.normalizedSleepDate(for: endDate)
  }

  var endOfEndDate: Date {
    guard let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: endDate) else { return endDate }

    return Calendar.current.startOfDay(for: nextDay)
  }

  var timeInterval: TimeInterval {
    endDate.timeIntervalSince(startDate)
  }

  var timeSpanDescription: String {
    DateFormatter.justRelativeDateMedium.string(from: endDate)
  }

  var name: String {
    DateFormatter.justDayOfWeek.string(from: endDate)
  }

  var overallDurationComponents: DateComponents {
    DateComponents(minute: Int(overallMinutes))
  }

  var coreSleepComponents: DateComponents? {
    guard hasDetailedSleepCategories else { return nil }

    return DateComponents(minute: Int(coreSleepMinutes))
  }

  var deepSleepComponents: DateComponents? {
    guard hasDetailedSleepCategories else { return nil }

    return DateComponents(minute: Int(deepSleepMinutes))
  }

  var remSleepComponents: DateComponents? {
    guard hasDetailedSleepCategories else { return nil }

    return DateComponents(minute: Int(remSleepMinutes))
  }

  var awakeSleepComponents: DateComponents? {
    guard hasDetailedSleepCategories else { return nil }

    return DateComponents(minute: Int(awakeSleepMinutes))
  }

  var overallMinutesIncludingAwake: Double {
    timeInterval / 60
  }

  var overallHoursIncludingAwake: Double {
    overallMinutesIncludingAwake / 60
  }

  var overallMinutes: Double {
    overallMinutesIncludingAwake - awakeSleepMinutes
  }

  var overallHours: Double {
    // Should we include awake time in the total?
    overallHoursIncludingAwake - (awakeSleepHours ?? 0)
  }

  var coreSleepHours: Double? {
    guard hasDetailedSleepCategories else { return nil }

    return coreSleepMinutes / 60
  }

  var remSleepHours: Double? {
    guard hasDetailedSleepCategories else { return nil }

    return remSleepMinutes / 60
  }

  var deepSleepHours: Double? {
    guard hasDetailedSleepCategories else { return nil }

    return deepSleepMinutes / 60
  }

  var awakeSleepHours: Double? {
    guard hasDetailedSleepCategories else { return nil }

    return awakeSleepMinutes / 60
  }

  var coreSleepPercent: Double {
    coreSleepMinutes / overallMinutesIncludingAwake
  }

  var remSleepPercent: Double {
    remSleepMinutes / overallMinutesIncludingAwake
  }

  var deepSleepPercent: Double {
    deepSleepMinutes / overallMinutesIncludingAwake
  }

  var awakeSleepPercent: Double {
    awakeSleepMinutes / overallMinutesIncludingAwake
  }

  var overallScore: Int {
    Int(overallScoreDouble.rounded(.towardZero))
  }

  var overallScoreDouble: Double {
    [
      sleepLengthScore,
      deepSleepScore,
      coreSleepScore,
      remSleepScore,
      awakeSleepScore,
      heartRateScore
    ].unwrap()
      .average(keyPath: \.self)
  }

  var sleepLengthScore: Double {
    overallMinutes.scaledPercent(lower: .zeroSleepLengthMinutes, upper: .fullSleepLengthMinutes) * .maxScore
  }

  var awakeSleepScore: Double? {
    guard hasDetailedSleepCategories else { return nil }

//    let percent = awakeSleepMinutes / overallMinutes
//    return percent.scaledPercent(lower: .awakeSleepMaxPercent, upper: .awakeSleepMinPercent) * .maxScore

    return awakeSleepMinutes.scaledPercent(lower: .awakeSleepMaxMinutes, upper: .awakeSleepMinMinutes) * .maxScore
  }

  var deepSleepScore: Double? {
    guard hasDetailedSleepCategories else { return nil }

//    let percent = deepSleepMinutes / overallMinutes
//    return percent.scaledPercent(lower: .deepSleepPercentMin, upper: .deepSleepPercentMax) * .maxScore

    return deepSleepMinutes.scaledPercent(lower: .deepSleepMinMinutes, upper: .deepSleepMaxMinutes) * .maxScore
  }

  var coreSleepScore: Double? {
    guard hasDetailedSleepCategories else { return nil }

//    let percent = coreSleepMinutes / overallMinutes
//    return percent.scaledPercent(lower: .coreSleepPercentMin, upper: .coreSleepPercentMax) * .maxScore

    return coreSleepMinutes.scaledPercent(lower: .coreSleepMinMinutes, upper: .coreSleepMaxMinutes) * .maxScore
  }

  var remSleepScore: Double? {
    guard hasDetailedSleepCategories else { return nil }

//    let percent = remSleepMinutes / overallMinutes
//    return percent.scaledPercent(lower: .remSleepPercentMin, upper: .remSleepPercentMax) * .maxScore

    return remSleepMinutes.scaledPercent(lower: .remSleepMinMinutes, upper: .remSleepMaxMinutes) * .maxScore
  }

  var averageSoundLevel: Double {
    environmentalSoundLevels.average(keyPath: \.decibelAWeightedSoundPressureLevelAverage)
  }

  var soundLevelScore: Double {
    averageSoundLevel.scaledPercent(lower: .maxSoundLevel, upper: .minSoundLevel) * .maxScore
  }

  var averageHeartRate: Double? {
    guard heartRate.isNotEmpty else { return nil }

    return heartRate.average(keyPath: \.averageHeartRate)
  }

  var heartRateScore: Double? {
    if let averageRestingHeartRate, let averageHeartRate {
      return averageHeartRate.scaledPercent(
        lower: averageRestingHeartRate,
        upper: averageRestingHeartRate * .maxRestingHeartRatePercent
      ) * .maxScore
    }
    return nil
  }
}

public extension SleepAnalysis {

  var sleepOneLiner: String {
    var results = [String]()

    results.append("Your sleep score last night was \(overallScore).")

    let awakeSleepDescription: String
    if let durationString = DateFormatter.timeIntervalHourMinuteFull.string(from: DateComponents(minute: Int(awakeSleepMinutes))) {
      awakeSleepDescription = "You were awake for \(durationString)."
    } else {
      awakeSleepDescription = "You were awake often throughout the night."
    }

    let pairings = [
      (deepSleepScore, "You didn't get enough Deep sleep."),
      (coreSleepScore, "You didn't get enough Core sleep."),
      (remSleepScore, "You didn't get enough REM sleep."),
      (awakeSleepScore, awakeSleepDescription)
    ].filter({ ($0.0 ?? 10) <= 6 })

    if let minPairingText = pairings.min(by: { (lhs, rhs) in
      (lhs.0 ?? .infinity) < (rhs.0 ?? .infinity)
    })?.1 {
      results.append(minPairingText)
    }

    return results.joined(separator: " ")
  }

  var sleepSummaryDescription: String {
    var results = [String]()

    if let durationString = DateFormatter.timeIntervalHourMinuteFull.string(from: DateComponents(minute: Int(overallMinutes))) {
      results.append("You slept for \(durationString).")
    }

    let awakeSleepDescription: String
    if let durationString = DateFormatter.timeIntervalHourMinuteFull.string(from: DateComponents(minute: Int(awakeSleepMinutes))) {
      awakeSleepDescription = "You were awake for \(durationString)."
    } else {
      awakeSleepDescription = "You were awake often throughout the night."
    }

    let pairings = [
      (deepSleepScore, "You didn't get enough Deep sleep."),
      (coreSleepScore, "You didn't get enough Core sleep."),
      (remSleepScore, "You didn't get enough REM sleep."),
      (awakeSleepScore, awakeSleepDescription)
    ]

    if let minPairingText = pairings.min(by: { (lhs, rhs) in
      (lhs.0 ?? .infinity) < (rhs.0 ?? .infinity)
    })?.1 {
      results.append(minPairingText)
    }

    if let heartRateScore, heartRateScore < 7 {
      if let averageRestingHeartRate, let averageHeartRate {
        results.append("Your heart rate was elevated to \(averageHeartRate.format()) bpm, when it should be \((averageRestingHeartRate * .maxRestingHeartRatePercent).format()) bpm or below.")
      } else if let averageHeartRate {
        results.append("Your heart rate was elevated to \(averageHeartRate.format()) bpm.")
      } else {
        results.append("Your heart rate was elevated.")
      }
    }

    if overallScoreDouble < 40 {
      results.append("Your sleep score indicates you should take it slow and make time for recovery.")
    } else if overallScoreDouble < 60 {
      results.append("Your sleep score indicates you should take it easy today.")
    } else {
      results.append("Your sleep score indicates you're ready to tackle the day!")
    }

    return results.joined(separator: " ")
  }
}

// MARK: - Previews

public extension SleepAnalysis {

  static var previewData: [SleepAnalysis] {
    [
      SleepAnalysis(
        startDate: Date().addingTimeInterval(-28800),
        endDate: Date.now,
        hasDetailedSleepCategories: true,
        deepSleepMinutes: 51,
        coreSleepMinutes: 290,
        remSleepMinutes: 98,
        awakeSleepMinutes: 25,
        averageRestingHeartRate: 65,
        environmentalSoundLevels: SleepAnalysis.SoundLevelDataPoint.previewData,
        heartRate: SleepAnalysis.HeartRateDataPoint.previewData,
        respiratoryRate: SleepAnalysis.RespiratoryRateDataPoint.previewData,
        wristTemperature: SleepAnalysis.WristTemperatureDataPoint.previewData
      ),
      SleepAnalysis(
        startDate: Date().addingTimeInterval(-(108000)),
        endDate: Date.now.addingTimeInterval(-86400),
        hasDetailedSleepCategories: true,
        deepSleepMinutes: 36,
        coreSleepMinutes: 250,
        remSleepMinutes: 67,
        awakeSleepMinutes: 40,
        averageRestingHeartRate: 65,
        environmentalSoundLevels: SleepAnalysis.SoundLevelDataPoint.previewData,
        heartRate: SleepAnalysis.HeartRateDataPoint.previewData,
        respiratoryRate: SleepAnalysis.RespiratoryRateDataPoint.previewData,
        wristTemperature: SleepAnalysis.WristTemperatureDataPoint.previewData
      ),
      SleepAnalysis(
        startDate: Date().addingTimeInterval(-(194400)),
        endDate: Date.now.addingTimeInterval(-172800),
        hasDetailedSleepCategories: true,
        deepSleepMinutes: 24,
        coreSleepMinutes: 300,
        remSleepMinutes: 48,
        awakeSleepMinutes: 52,
        averageRestingHeartRate: 65,
        environmentalSoundLevels: SleepAnalysis.SoundLevelDataPoint.previewData,
        heartRate: SleepAnalysis.HeartRateDataPoint.previewData,
        respiratoryRate: SleepAnalysis.RespiratoryRateDataPoint.previewData,
        wristTemperature: SleepAnalysis.WristTemperatureDataPoint.previewData
      ),
      SleepAnalysis(
        startDate: Date().addingTimeInterval(-(280800)),
        endDate: Date.now.addingTimeInterval(-253200),
        hasDetailedSleepCategories: true,
        deepSleepMinutes: 70,
        coreSleepMinutes: 260,
        remSleepMinutes: 150,
        awakeSleepMinutes: 12,
        averageRestingHeartRate: 65,
        environmentalSoundLevels: SleepAnalysis.SoundLevelDataPoint.previewData,
        heartRate: SleepAnalysis.HeartRateDataPoint.previewData,
        respiratoryRate: SleepAnalysis.RespiratoryRateDataPoint.previewData,
        wristTemperature: SleepAnalysis.WristTemperatureDataPoint.previewData
      )
    ]
  }
}

public extension SleepAnalysis.SoundLevelDataPoint {

  static let previewData: [SleepAnalysis.SoundLevelDataPoint] = [
    SleepAnalysis.SoundLevelDataPoint(
      decibelAWeightedSoundPressureLevelAverage: 44,
      startDate: .now,
      timeRangeSeconds: 3600
    ),
    SleepAnalysis.SoundLevelDataPoint(
      decibelAWeightedSoundPressureLevelAverage: 45,
      startDate: Date(timeIntervalSinceNow: -3600),
      timeRangeSeconds: 3600
    ),
    SleepAnalysis.SoundLevelDataPoint(
      decibelAWeightedSoundPressureLevelAverage: 51,
      startDate: Date(timeIntervalSinceNow: -7200),
      timeRangeSeconds: 3600
    ),
    SleepAnalysis.SoundLevelDataPoint(
      decibelAWeightedSoundPressureLevelAverage: 48,
      startDate: Date(timeIntervalSinceNow: -10800),
      timeRangeSeconds: 3600
    ),
    SleepAnalysis.SoundLevelDataPoint(
      decibelAWeightedSoundPressureLevelAverage: 45,
      startDate: Date(timeIntervalSinceNow: -14400),
      timeRangeSeconds: 3600
    ),
    SleepAnalysis.SoundLevelDataPoint(
      decibelAWeightedSoundPressureLevelAverage: 48,
      startDate: Date(timeIntervalSinceNow: -18000),
      timeRangeSeconds: 3600
    ),
    SleepAnalysis.SoundLevelDataPoint(
      decibelAWeightedSoundPressureLevelAverage: 42,
      startDate: Date(timeIntervalSinceNow: -21600),
      timeRangeSeconds: 3600
    ),
    SleepAnalysis.SoundLevelDataPoint(
      decibelAWeightedSoundPressureLevelAverage: 51,
      startDate: Date(timeIntervalSinceNow: -25200),
      timeRangeSeconds: 3600
    ),
    SleepAnalysis.SoundLevelDataPoint(
      decibelAWeightedSoundPressureLevelAverage: 43,
      startDate: Date(timeIntervalSinceNow: -28800),
      timeRangeSeconds: 3600
    ),
    SleepAnalysis.SoundLevelDataPoint(
      decibelAWeightedSoundPressureLevelAverage: 48,
      startDate: Date(timeIntervalSinceNow: -32400),
      timeRangeSeconds: 3600
    ),
    SleepAnalysis.SoundLevelDataPoint(
      decibelAWeightedSoundPressureLevelAverage: 42,
      startDate: Date(timeIntervalSinceNow: -36000),
      timeRangeSeconds: 3600
    ),
    SleepAnalysis.SoundLevelDataPoint(
      decibelAWeightedSoundPressureLevelAverage: 39,
      startDate: Date(timeIntervalSinceNow: -39600),
      timeRangeSeconds: 3600
    )
  ]
}

public extension SleepAnalysis.HeartRateDataPoint {

  static let previewData: [SleepAnalysis.HeartRateDataPoint] = [
    SleepAnalysis.HeartRateDataPoint(
      averageHeartRate: 56,
      startDate: .now,
      timeRangeSeconds: 900
    ),
    SleepAnalysis.HeartRateDataPoint(
      averageHeartRate: 58,
      startDate: Date(timeIntervalSinceNow: -900),
      timeRangeSeconds: 900
    ),
    SleepAnalysis.HeartRateDataPoint(
      averageHeartRate: 48,
      startDate: Date(timeIntervalSinceNow: -1800),
      timeRangeSeconds: 900
    ),
    SleepAnalysis.HeartRateDataPoint(
      averageHeartRate: 57,
      startDate: Date(timeIntervalSinceNow: -2700),
      timeRangeSeconds: 900
    ),
    SleepAnalysis.HeartRateDataPoint(
      averageHeartRate: 48,
      startDate: Date(timeIntervalSinceNow: -3600),
      timeRangeSeconds: 900
    ),
    SleepAnalysis.HeartRateDataPoint(
      averageHeartRate: 43,
      startDate: Date(timeIntervalSinceNow: -4500),
      timeRangeSeconds: 900
    ),
    SleepAnalysis.HeartRateDataPoint(
      averageHeartRate: 48,
      startDate: Date(timeIntervalSinceNow: -5400),
      timeRangeSeconds: 900
    ),
  ]
}

public extension SleepAnalysis.RespiratoryRateDataPoint {

  static let previewData: [SleepAnalysis.RespiratoryRateDataPoint] = [
    SleepAnalysis.RespiratoryRateDataPoint(
      averageRespiratoryRate: 12,
      startDate: .now,
      timeRangeSeconds: 900
    ),
    SleepAnalysis.RespiratoryRateDataPoint(
      averageRespiratoryRate: 15,
      startDate: Date(timeIntervalSinceNow: -900),
      timeRangeSeconds: 900
    ),
    SleepAnalysis.RespiratoryRateDataPoint(
      averageRespiratoryRate: 14,
      startDate: Date(timeIntervalSinceNow: -1800),
      timeRangeSeconds: 900
    ),
    SleepAnalysis.RespiratoryRateDataPoint(
      averageRespiratoryRate: 11,
      startDate: Date(timeIntervalSinceNow: -2700),
      timeRangeSeconds: 900
    ),
    SleepAnalysis.RespiratoryRateDataPoint(
      averageRespiratoryRate: 16,
      startDate: Date(timeIntervalSinceNow: -3600),
      timeRangeSeconds: 900
    ),
    SleepAnalysis.RespiratoryRateDataPoint(
      averageRespiratoryRate: 14,
      startDate: Date(timeIntervalSinceNow: -4500),
      timeRangeSeconds: 900
    ),
    SleepAnalysis.RespiratoryRateDataPoint(
      averageRespiratoryRate: 12,
      startDate: Date(timeIntervalSinceNow: -5400),
      timeRangeSeconds: 900
    ),
  ]
}

public extension SleepAnalysis.WristTemperatureDataPoint {

  static let previewData = SleepAnalysis.WristTemperatureDataPoint(
    averageWristTemperature: 96,
    startDate: .now,
    timeRangeSeconds: 900
  )
}
