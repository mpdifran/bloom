//
//  YouStatsCalculator.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-29.
//

import Foundation
import CoreHealth
import BloomFoundation
import HealthKit

final actor YouStatsCalculator {
  static let shared = YouStatsCalculator()

  @AsyncStreamable var bedtimeChartData: BedtimeChartData?
  @AsyncStreamable var averageSleepDuration: TimeInterval?
  @AsyncStreamable var averageSleepScore: Double?
  @AsyncStreamable var sleepStageDataPoints: [SleepStageDataPoint]?
  @AsyncStreamable var averageSleepHeartRate: Double?
  @AsyncStreamable var sleepHeartRateChartData: [SleepHeartRateDataPoint]?
  @AsyncStreamable var sleepRespiratoryRateTrend: RespiratoryRateTrend?
  @AsyncStreamable var sleepRespiratoryRateChartData: [RespiratoryRateDataPoint]?
  @AsyncStreamable var wristTempData: WristTempData?
  @AsyncStreamable var weeklyStepsChartData: WeeklyStepsChartData?
  @AsyncStreamable var heartRateReserveChartData: HeartRateReserveChartData?
  @AsyncStreamable var vo2MaxTrendData: VO2MaxTrendData?
  @AsyncStreamable var heartRateRecoveryData: HeartRateRecoveryData?
  @AsyncStreamable var bodyWeightChartData: BodyWeightChartData?
  @AsyncStreamable var hrvChartData: HRVChartData?
  @AsyncStreamable var bloodPressureData: BloodPressureCardData?
  @AsyncStreamable var fiberChartData: FiberChartData?
  @AsyncStreamable var sugarChartData: SugarChartData?
  @AsyncStreamable var zoneMinutesData: ZoneMinutesData?
  @AsyncStreamable var zoneDistributionData: ZoneDistributionData?
  @AsyncStreamable var recentWorkoutsData: RecentWorkoutsData?
  @AsyncStreamable var activeEnergyChartData: ActiveEnergyChartData?
  @AsyncStreamable var sleepDurationChartData: SleepDurationChartData?

  private let healthStoreFetcher = HealthStoreFetcher.shared

  private init() { }

  func refreshStats() async {
    let sleepAnalyses = await healthStoreFetcher.fetchSleepAnalysis(
      dateRange: .trailingDaysFromNow(7)
    )
    bedtimeChartData = calculateBedtimeChartData(from: sleepAnalyses)
    averageSleepDuration = calculateAverageSleepDuration(from: sleepAnalyses)
    sleepDurationChartData = calculateSleepDurationChartData(from: sleepAnalyses)
    averageSleepScore = calculateAverageSleepScore(from: sleepAnalyses)
    sleepStageDataPoints = calculateSleepStageDataPoints(from: sleepAnalyses)
    averageSleepHeartRate = calculateAverageSleepHeartRate(from: sleepAnalyses)
    sleepHeartRateChartData = calculateSleepHeartRateChartData(from: sleepAnalyses)

    let respiratoryData = calculateRespiratoryRateData(from: sleepAnalyses)
    sleepRespiratoryRateChartData = respiratoryData
    sleepRespiratoryRateTrend = calculateRespiratoryRateTrend(from: respiratoryData)

    wristTempData = calculateWristTempData(from: sleepAnalyses)

    weeklyStepsChartData = await calculateWeeklyStepsChartData()
    heartRateReserveChartData = await calculateHeartRateReserveChartData()
    vo2MaxTrendData = await calculateVO2MaxTrendData()
    heartRateRecoveryData = await calculateHeartRateRecoveryData()
    bodyWeightChartData = await calculateBodyWeightChartData()
    hrvChartData = await calculateHRVChartData()
    bloodPressureData = await calculateBloodPressureCardData()
    fiberChartData = await calculateFiberChartData()
    sugarChartData = await calculateSugarChartData()
    zoneMinutesData = await calculateZoneMinutesData()
    zoneDistributionData = await calculateZoneDistributionData()
    recentWorkoutsData = await calculateRecentWorkoutsData()
    activeEnergyChartData = await calculateActiveEnergyChartData()
  }

  func refreshSteps() async {
    weeklyStepsChartData = await calculateWeeklyStepsChartData()
  }
}

private extension YouStatsCalculator {

  func calculateAverageSleepDuration(from sleepAnalyses: [SleepAnalysis]) -> TimeInterval? {
    guard sleepAnalyses.isNotEmpty else { return nil }
    let totalMinutes = sleepAnalyses.map(\.overallMinutes).reduce(0, +)
    let averageMinutes = totalMinutes / Double(sleepAnalyses.count)
    return averageMinutes * 60 // Convert to seconds (TimeInterval)
  }

  func calculateAverageSleepScore(from sleepAnalyses: [SleepAnalysis]) -> Double? {
    guard sleepAnalyses.isNotEmpty else { return nil }
    let totalScore = sleepAnalyses.map(\.overallScoreDouble).reduce(0, +)
    return totalScore / Double(sleepAnalyses.count)
  }

  func calculateSleepStageDataPoints(from sleepAnalyses: [SleepAnalysis]) -> [SleepStageDataPoint]? {
    guard sleepAnalyses.isNotEmpty else { return nil }

    let calendar = Calendar.current
    let now = Date()

    // Create data points for each of the last 7 days that have sleep data
    let dataPoints = (0..<7).reversed().flatMap { daysAgo -> [SleepStageDataPoint] in
      guard let targetDate = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { return [] }

      // Find sleep analysis for this day (matching by end date)
      guard let analysis = sleepAnalyses.first(where: {
        calendar.isDate($0.endDate, inSameDayAs: targetDate)
      }) else { return [] }

      let dateForChart = calendar.startOfDay(for: targetDate)
      return [
        SleepStageDataPoint(date: dateForChart, stage: .deep, minutes: analysis.deepSleepMinutes),
        SleepStageDataPoint(date: dateForChart, stage: .core, minutes: analysis.coreSleepMinutes),
        SleepStageDataPoint(date: dateForChart, stage: .rem, minutes: analysis.remSleepMinutes),
        SleepStageDataPoint(date: dateForChart, stage: .awake, minutes: analysis.awakeSleepMinutes)
      ]
    }

    return dataPoints.isEmpty ? nil : dataPoints
  }

  func calculateBedtimeChartData(from sleepAnalyses: [SleepAnalysis]) -> BedtimeChartData? {
    let calendar = Calendar.current
    let now = Date()

    let dataPoints: [BedtimeDataPoint] = (0..<7).reversed().compactMap { daysAgo -> BedtimeDataPoint? in
      guard let targetDate = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { return nil }

      let analysis = sleepAnalyses.first { analysis in
        calendar.isDate(analysis.endDate, inSameDayAs: targetDate)
      }

      guard let analysis else { return nil }

      let minutesFromMidnight = getMinutesFromMidnight(analysis.startDate)
      // Negate so earlier bedtimes appear at top of chart
      return BedtimeDataPoint(
        date: calendar.startOfDay(for: targetDate),
        minutesFromMidnight: -minutesFromMidnight
      )
    }

    guard dataPoints.count >= 2 else { return nil }

    let trend = calculateBedtimeTrend(from: dataPoints)

    return BedtimeChartData(dataPoints: dataPoints, trend: trend)
  }

  func calculateBedtimeTrend(from dataPoints: [BedtimeDataPoint]) -> BedtimeTrend {
    guard dataPoints.count >= 3 else { return .consistent }

    let minutes = dataPoints.map(\.minutesFromMidnight)
    let average = minutes.reduce(0, +) / Double(minutes.count)

    let standardDeviation = sqrt(
      minutes.map { pow($0 - average, 2) }.reduce(0, +) / Double(minutes.count)
    )

    // Check for trending by comparing first half to second half
    let midpoint = minutes.count / 2
    let firstHalfAvg = minutes.prefix(midpoint).reduce(0, +) / Double(midpoint)
    let secondHalfAvg = minutes.suffix(midpoint).reduce(0, +) / Double(midpoint)
    let trendDifference = secondHalfAvg - firstHalfAvg

    // If standard deviation is low and no significant trend, it's consistent
    if standardDeviation < 30 && abs(trendDifference) < 20 {
      return .consistent
    }

    // If there's a significant trend (>20 min difference between halves)
    // Note: values are negated, so more negative = later bedtime
    if trendDifference > 20 {
      return .trendingEarlier  // Second half less negative = earlier bedtime
    } else if trendDifference < -20 {
      return .trendingLater    // Second half more negative = later bedtime
    }

    // High variance but no clear trend means inconsistent
    return .inconsistent
  }

  /// Converts a date to minutes from midnight, handling bedtimes that cross midnight
  /// Times before noon are treated as "after midnight" (add 24 hours worth of minutes)
  func getMinutesFromMidnight(_ date: Date) -> Double {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.hour, .minute], from: date)
    let hours = Double(components.hour ?? 0)
    let minutes = Double(components.minute ?? 0)

    var totalMinutes = hours * 60 + minutes

    // If time is before noon, treat it as after midnight (e.g., 1 AM = 25 * 60 = 1500 minutes)
    if totalMinutes < 12 * 60 {
      totalMinutes += 24 * 60
    }

    return totalMinutes
  }

  func calculateAverageSleepHeartRate(from sleepAnalyses: [SleepAnalysis]) -> Double? {
    let heartRates = sleepAnalyses.compactMap(\.averageHeartRate)
    guard heartRates.isNotEmpty else { return nil }
    return heartRates.reduce(0, +) / Double(heartRates.count)
  }

  func calculateSleepHeartRateChartData(from sleepAnalyses: [SleepAnalysis]) -> [SleepHeartRateDataPoint]? {
    let calendar = Calendar.current
    let now = Date()

    let dataPoints = (0..<7).reversed().compactMap { daysAgo -> SleepHeartRateDataPoint? in
      guard let targetDate = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { return nil }

      guard let analysis = sleepAnalyses.first(where: {
        calendar.isDate($0.endDate, inSameDayAs: targetDate)
      }),
      let heartRate = analysis.averageHeartRate else { return nil }

      return SleepHeartRateDataPoint(
        date: calendar.startOfDay(for: targetDate),
        heartRate: heartRate
      )
    }

    return dataPoints.isEmpty ? nil : dataPoints
  }

  func calculateRespiratoryRateData(from sleepAnalyses: [SleepAnalysis]) -> [RespiratoryRateDataPoint]? {
    let calendar = Calendar.current
    let now = Date()

    let dataPoints = (0..<7).reversed().compactMap { daysAgo -> RespiratoryRateDataPoint? in
      guard let targetDate = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { return nil }
      guard let analysis = sleepAnalyses.first(where: {
        calendar.isDate($0.endDate, inSameDayAs: targetDate)
      }) else { return nil }

      let rates = analysis.respiratoryRate.map(\.averageRespiratoryRate)
      guard rates.isNotEmpty else { return nil }
      let avgRate = rates.reduce(0, +) / Double(rates.count)

      return RespiratoryRateDataPoint(
        date: calendar.startOfDay(for: targetDate),
        rate: avgRate
      )
    }

    return dataPoints.isEmpty ? nil : dataPoints
  }

  func calculateRespiratoryRateTrend(from dataPoints: [RespiratoryRateDataPoint]?) -> RespiratoryRateTrend? {
    guard let dataPoints, dataPoints.count >= 2 else { return nil }

    let sorted = dataPoints.sorted { $0.date > $1.date }
    let current = sorted[0].rate
    let previousRates = sorted.dropFirst().map(\.rate)
    let previousAvg = previousRates.reduce(0, +) / Double(previousRates.count)

    guard previousAvg != 0 else { return .consistent }
    let percentChange = ((current - previousAvg) / previousAvg) * 100

    if abs(percentChange) < 5 {
      return .consistent
    } else if percentChange > 0 {
      return .increasing
    } else {
      return .decreasing
    }
  }

  func calculateWristTempData(from sleepAnalyses: [SleepAnalysis]) -> WristTempData? {
    let temps = sleepAnalyses.compactMap { $0.wristTemperature?.averageWristTemperature }
    guard temps.count >= 2 else { return nil }

    let weeklyAvg = temps.reduce(0, +) / Double(temps.count)

    let sorted = sleepAnalyses
      .filter { $0.wristTemperature != nil }
      .sorted { $0.endDate > $1.endDate }

    guard let mostRecent = sorted.first?.wristTemperature?.averageWristTemperature else { return nil }

    return WristTempData(weeklyAverage: weeklyAvg, latestTemp: mostRecent)
  }

  func calculateWeeklyStepsChartData() async -> WeeklyStepsChartData? {
    var calendar = Calendar.current
    calendar.firstWeekday = 1  // Sunday

    let now = Date()
    let todayWeekday = calendar.component(.weekday, from: now)  // 1 = Sunday

    // Find the start of this week (Sunday)
    guard let thisWeekStart = calendar.date(
      byAdding: .day,
      value: -(todayWeekday - 1),
      to: calendar.startOfDay(for: now)
    ) else { return nil }

    // Find the start of last week (Sunday)
    guard let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: thisWeekStart) else { return nil }

    // Fetch steps for this week (from Sunday to today) in 4-hour windows
    let thisWeekRange = DateRange(thisWeekStart, now)
    let thisWeekSteps = await healthStoreFetcher.fetchCollatedQuantity(
      for: .stepCount,
      unit: .count(),
      interval: DateComponents(hour: 4),
      dateRange: thisWeekRange
    )

    // Fetch steps for last week (full week) in 4-hour windows
    guard let lastWeekEnd = calendar.date(byAdding: .day, value: 7, to: lastWeekStart) else { return nil }
    let lastWeekRange = DateRange(lastWeekStart, lastWeekEnd)
    let lastWeekSteps = await healthStoreFetcher.fetchCollatedQuantity(
      for: .stepCount,
      unit: .count(),
      interval: DateComponents(hour: 4),
      dateRange: lastWeekRange
    )

    // Build cumulative data points for this week
    var thisWeekDataPoints = [StepsDataPoint]()
    var cumulativeSteps = 0
    for (index, sample) in thisWeekSteps.enumerated() {
      let steps = Int(sample.quantity.doubleValue(for: .count()))
      cumulativeSteps += steps

      thisWeekDataPoints.append(StepsDataPoint(
        date: sample.date,
        cumulativeSteps: cumulativeSteps,
        index: index,
        series: "This Week"
      ))
    }

    // Build cumulative data points for last week
    var lastWeekDataPoints = [StepsDataPoint]()
    var lastWeekCumulativeSteps = 0
    for (index, sample) in lastWeekSteps.enumerated() {
      let steps = Int(sample.quantity.doubleValue(for: .count()))
      lastWeekCumulativeSteps += steps

      lastWeekDataPoints.append(StepsDataPoint(
        date: sample.date,
        cumulativeSteps: lastWeekCumulativeSteps,
        index: index,
        series: "Last Week"
      ))
    }

    guard thisWeekDataPoints.isNotEmpty else { return nil }

    // Calculate percentage change (compare to same point in week)
    let totalStepsThisWeek = cumulativeSteps
    let currentIndex = thisWeekDataPoints.count - 1

    // Get last week's cumulative total at the same point in the week
    let totalStepsLastWeekSamePoint = lastWeekDataPoints
      .first { $0.index == currentIndex }?
      .cumulativeSteps ?? 0

    let percentageChange: Double?
    if totalStepsLastWeekSamePoint > 0 {
      percentageChange = (Double(totalStepsThisWeek) - Double(totalStepsLastWeekSamePoint)) / Double(totalStepsLastWeekSamePoint) * 100
    } else {
      percentageChange = nil
    }

    return WeeklyStepsChartData(
      thisWeekDataPoints: thisWeekDataPoints,
      lastWeekDataPoints: lastWeekDataPoints,
      totalStepsThisWeek: totalStepsThisWeek,
      percentageChangeFromLastWeek: percentageChange
    )
  }

  func calculateHeartRateReserveChartData() async -> HeartRateReserveChartData? {
    let calendar = Calendar.current
    let now = Date()

    // Need 14 days of data to calculate rolling 7-day values for each of the last 7 days
    guard let startDate = calendar.date(byAdding: .day, value: -13, to: calendar.startOfDay(for: now)) else {
      return nil
    }

    let dateRange = DateRange(startDate, now)

    // Fetch daily max heart rates using discreteMax
    let maxHRSamples = await healthStoreFetcher.fetchCollatedQuantity(
      for: .heartRate,
      unit: .bpm(),
      interval: DateComponents(day: 1),
      options: .discreteMax,
      dateRange: dateRange
    )

    // Fetch daily average resting heart rates
    let restingHRSamples = await healthStoreFetcher.fetchCollatedQuantity(
      for: .restingHeartRate,
      unit: .bpm(),
      interval: DateComponents(day: 1),
      options: .discreteAverage,
      dateRange: dateRange
    )

    guard maxHRSamples.isNotEmpty, restingHRSamples.isNotEmpty else { return nil }

    // Build data points with rolling 7-day calculations
    var dataPoints = [HeartRateReserveDataPoint]()

    // For each of the last 7 days (dayIndex 0 = 6 days ago, dayIndex 6 = today)
    for dayIndex in 0..<7 {
      // Calculate the target day (6 days ago to today)
      guard let targetDay = calendar.date(byAdding: .day, value: dayIndex - 6, to: calendar.startOfDay(for: now)) else {
        continue
      }

      // Calculate rolling 7-day window ending on targetDay
      guard let windowStart = calendar.date(byAdding: .day, value: -6, to: targetDay) else { continue }

      // Get max HR samples in the 7-day window
      let windowMaxHRSamples = maxHRSamples.filter { sample in
        sample.date >= windowStart && sample.date <= targetDay
      }

      // Get resting HR samples in the 7-day window
      let windowRestingHRSamples = restingHRSamples.filter { sample in
        sample.date >= windowStart && sample.date <= targetDay
      }

      // Calculate rolling 7-day max (highest max HR in the window)
      guard let rollingMaxHR = windowMaxHRSamples
        .map({ $0.quantity.doubleValue(for: .bpm()) })
        .max() else { continue }

      // Calculate rolling 7-day average resting HR
      let restingHRValues = windowRestingHRSamples.map { $0.quantity.doubleValue(for: .bpm()) }
      guard restingHRValues.isNotEmpty else { continue }
      let rollingAvgRestingHR = restingHRValues.reduce(0, +) / Double(restingHRValues.count)

      dataPoints.append(HeartRateReserveDataPoint(
        date: calendar.startOfDay(for: targetDay),
        maxHeartRate: rollingMaxHR,
        restingHeartRate: rollingAvgRestingHR,
        dayIndex: dayIndex
      ))
    }

    guard dataPoints.isNotEmpty else { return nil }

    // Get current HRR from the latest data point
    let currentHRR = Int(dataPoints.last?.heartRateReserve ?? 0)

    return HeartRateReserveChartData(
      dataPoints: dataPoints,
      currentHRR: currentHRR
    )
  }

  func calculateVO2MaxTrendData() async -> VO2MaxTrendData? {
    let dateRange = DateRange.trailingMonthsFromNow(3)

    // Fetch all VO2 Max samples from the last 3 months
    let sampleType = HKQuantityType(.vo2Max)
    guard let samples = try? await healthStoreFetcher.fetchSamples(
      for: sampleType,
      dateRange: dateRange
    ) as? [HKQuantitySample],
    samples.isNotEmpty else { return nil }

    // Sort by date descending and take up to 3 most recent
    let sortedSamples = samples.sorted { $0.endDate > $1.endDate }
    let recentSamples = Array(sortedSamples.prefix(3))

    // Latest value
    guard let latestSample = recentSamples.first else { return nil }
    let latestValue = latestSample.quantity.doubleValue(for: .vo2Max())

    // Determine trend (compare first and last of the selected samples)
    let trend: VO2MaxTrendDirection
    if recentSamples.count >= 2 {
      let oldestValue = recentSamples.last!.quantity.doubleValue(for: .vo2Max())
      let difference = latestValue - oldestValue

      if difference > 0.5 {
        trend = .improving
      } else if difference < -0.5 {
        trend = .declining
      } else {
        trend = .constant
      }
    } else {
      trend = .constant  // Only one data point
    }

    return VO2MaxTrendData(latestValue: latestValue, trend: trend)
  }

  func calculateHeartRateRecoveryData() async -> HeartRateRecoveryData? {
    var calendar = Calendar.current
    calendar.firstWeekday = 1  // Sunday

    let now = Date()
    let todayWeekday = calendar.component(.weekday, from: now)

    // Find start of this week (Sunday)
    guard let thisWeekStart = calendar.date(
      byAdding: .day,
      value: -(todayWeekday - 1),
      to: calendar.startOfDay(for: now)
    ) else { return nil }

    // Find start of last week
    guard let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: thisWeekStart) else { return nil }

    // Fetch this week's average
    let thisWeekRange = DateRange(thisWeekStart, now)
    let thisWeekAvg = await healthStoreFetcher.fetchDailyAverage(
      for: .heartRateRecoveryOneMinute,
      unit: .bpm(),
      dateRange: thisWeekRange
    )

    // Fetch last week's average
    let lastWeekRange = DateRange(lastWeekStart, thisWeekStart)
    let lastWeekAvg = await healthStoreFetcher.fetchDailyAverage(
      for: .heartRateRecoveryOneMinute,
      unit: .bpm(),
      dateRange: lastWeekRange
    )

    guard thisWeekAvg != nil || lastWeekAvg != nil else { return nil }

    return HeartRateRecoveryData(
      thisWeekAverage: thisWeekAvg?.doubleValue(for: .bpm()),
      lastWeekAverage: lastWeekAvg?.doubleValue(for: .bpm())
    )
  }

  func calculateBodyWeightChartData() async -> BodyWeightChartData? {
    let dateRange = DateRange.trailingDaysFromNow(30)

    // Fetch body mass samples
    let sampleType = HKQuantityType(.bodyMass)
    guard let samples = try? await healthStoreFetcher.fetchSamples(
      for: sampleType,
      dateRange: dateRange
    ) as? [HKQuantitySample],
    samples.isNotEmpty else { return nil }

    // Get user's preferred weight unit
    let weightUnit = await HealthUnitPreferences.shared.weightUnit

    // Sort by date ascending for chart
    let sortedSamples = samples.sorted { $0.endDate < $1.endDate }

    // Build data points
    let dataPoints = sortedSamples.map { sample in
      BodyWeightDataPoint(
        date: sample.endDate,
        weight: sample.quantity.doubleValue(for: weightUnit)
      )
    }

    // Get latest value and date
    let latestSample = sortedSamples.last
    let latestWeight = latestSample?.quantity
    let latestDate = latestSample?.endDate

    return BodyWeightChartData(
      dataPoints: dataPoints,
      latestWeight: latestWeight,
      latestDate: latestDate
    )
  }

  func calculateHRVChartData() async -> HRVChartData? {
    let calendar = Calendar.current
    let now = Date()

    // Fetch 30 days of HRV samples
    let dateRange = DateRange.trailingDaysFromNow(30)
    let sampleType = HKQuantityType(.heartRateVariabilitySDNN)

    guard let samples = try? await healthStoreFetcher.fetchSamples(
      for: sampleType,
      dateRange: dateRange
    ) as? [HKQuantitySample],
    samples.isNotEmpty else { return nil }

    // Split into 7-day and 30-day sets
    guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return nil }
    let sevenDaySamples = samples.filter { $0.endDate >= sevenDaysAgo }
    let thirtyDaySamples = samples

    // Calculate averages
    let sevenDayValues = sevenDaySamples.map { $0.quantity.doubleValue(for: .secondUnit(with: .milli)) }
    let thirtyDayValues = thirtyDaySamples.map { $0.quantity.doubleValue(for: .secondUnit(with: .milli)) }

    guard sevenDayValues.isNotEmpty, thirtyDayValues.isNotEmpty else { return nil }

    let sevenDayAverage = sevenDayValues.reduce(0, +) / Double(sevenDayValues.count)
    let thirtyDayAverage = thirtyDayValues.reduce(0, +) / Double(thirtyDayValues.count)

    // Group 7-day samples by 3-hour windows and average
    // Windows: 0-3, 3-6, 6-9, 9-12, 12-15, 15-18, 18-21, 21-24
    // Midpoints: 1.5, 4.5, 7.5, 10.5, 13.5, 16.5, 19.5, 22.5
    let windows = [0, 3, 6, 9, 12, 15, 18, 21]
    let dataPoints: [HRVTimeOfDayDataPoint] = windows.compactMap { windowStart in
      let windowSamples = sevenDaySamples.filter { sample in
        let hour = calendar.component(.hour, from: sample.endDate)
        return hour >= windowStart && hour < windowStart + 3
      }

      guard windowSamples.isNotEmpty else { return nil }

      let values = windowSamples.map { $0.quantity.doubleValue(for: .secondUnit(with: .milli)) }
      let avg = values.reduce(0, +) / Double(values.count)

      // Use midpoint of window for chart position
      return HRVTimeOfDayDataPoint(hourWindow: Double(windowStart) + 1.5, averageHRV: avg)
    }

    guard dataPoints.isNotEmpty else { return nil }

    return HRVChartData(
      sevenDayAverage: sevenDayAverage,
      thirtyDayAverage: thirtyDayAverage,
      timeOfDayDataPoints: dataPoints
    )
  }

  func calculateBloodPressureCardData() async -> BloodPressureCardData? {
    guard let latestSystolicSample = await healthStoreFetcher.fetchLatestSample(for: .bloodPressureSystolic),
          let latestDiastolicSample = await healthStoreFetcher.fetchLatestSample(for: .bloodPressureDiastolic)
    else { return nil }

    let latestSystolic = latestSystolicSample.quantity.doubleValue(for: .millimeterOfMercury())
    let latestDiastolic = latestDiastolicSample.quantity.doubleValue(for: .millimeterOfMercury())

    let category = HealthGoalProvider.shared.bloodPressureCategory(
      systolic: latestSystolic,
      diastolic: latestDiastolic
    )

    return BloodPressureCardData(
      latestSystolic: latestSystolic,
      latestDiastolic: latestDiastolic,
      latestDate: latestSystolicSample.endDate,
      category: category
    )
  }

  func calculateFiberChartData() async -> FiberChartData? {
    let dateRange = DateRange.trailingDaysFromNow(7)

    let fiberSamples = await healthStoreFetcher.fetchCollatedQuantity(
      for: .dietaryFiber,
      unit: .gram(),
      interval: DateComponents(day: 1),
      dateRange: dateRange
    )

    guard fiberSamples.isNotEmpty else { return nil }

    let dailyValues = fiberSamples.map { $0.quantity.doubleValue(for: .gram()) }
    let total = dailyValues.reduce(0, +)
    let average = total / Double(dailyValues.count)
    let goal = HealthGoalProvider.shared.recommendedMinDailyIntakeForFiber().doubleValue(for: .gram())

    return FiberChartData(
      dailyValues: dailyValues,
      averageGrams: average,
      goal: goal
    )
  }

  func calculateSugarChartData() async -> SugarChartData? {
    let dateRange = DateRange.trailingDaysFromNow(7)

    let sugarSamples = await healthStoreFetcher.fetchCollatedQuantity(
      for: .dietarySugar,
      unit: .gram(),
      interval: DateComponents(day: 1),
      dateRange: dateRange
    )

    guard sugarSamples.isNotEmpty else { return nil }

    let dailyValues = sugarSamples.map { $0.quantity.doubleValue(for: .gram()) }
    let total = dailyValues.reduce(0, +)
    let average = total / Double(dailyValues.count)
    let goal = HealthGoalProvider.shared.recommendedMaxDailyIntakeForSugar().doubleValue(for: .gram())

    return SugarChartData(
      dailyValues: dailyValues,
      averageGrams: average,
      goal: goal
    )
  }

  func calculateZoneMinutesData() async -> ZoneMinutesData? {
    guard let heartRateZones = await healthStoreFetcher.heartRateZones() else { return nil }

    let details = await healthStoreFetcher.fetchExerciseEffectivenessDetails(
      heartRateZones: heartRateZones,
      dateRange: .trailingDaysFromNow(7)
    )

    guard !details.workoutReports.isEmpty else { return nil }

    let calendar = Calendar.current
    let now = Date()

    // Group workout zone minutes by day
    var dailyZoneMinutes = [Date: Double]()
    for report in details.workoutReports {
      let dayStart = calendar.startOfDay(for: report.workout.endDate)
      let zoneMinutes = report.heartZoneDistribution.scaledDurationSum.doubleValue(for: .minute())
      dailyZoneMinutes[dayStart, default: 0] += zoneMinutes
    }

    // Build array for last 7 days (in order)
    let dailyValues: [Double] = (0..<7).reversed().compactMap { daysAgo in
      guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: now)) else { return 0 }
      return dailyZoneMinutes[date] ?? 0
    }

    let total = dailyValues.reduce(0, +)

    return ZoneMinutesData(dailyValues: dailyValues, weeklyTotal: total)
  }

  func calculateZoneDistributionData() async -> ZoneDistributionData? {
    guard let heartRateZones = await healthStoreFetcher.heartRateZones() else { return nil }

    let details = await healthStoreFetcher.fetchExerciseEffectivenessDetails(
      heartRateZones: heartRateZones,
      dateRange: .trailingDaysFromNow(7)
    )

    guard !details.workoutReports.isEmpty else { return nil }

    let dist = details.overallHeartZoneDistribution
    return ZoneDistributionData(
      zone1Percent: dist.zone1Percent,
      zone2Percent: dist.zone2Percent,
      zone3Percent: dist.zone3Percent,
      zone4Percent: dist.zone4Percent,
      zone5Percent: dist.zone5Percent,
      workoutCount: details.workoutReports.count
    )
  }

  func calculateRecentWorkoutsData() async -> RecentWorkoutsData? {
    guard let heartRateZones = await healthStoreFetcher.heartRateZones() else { return nil }

    let details = await healthStoreFetcher.fetchExerciseEffectivenessDetails(
      heartRateZones: heartRateZones,
      dateRange: .trailingDaysFromNow(7)
    )

    guard !details.workoutReports.isEmpty else { return nil }

    // workoutReports are sorted by date (most recent first from HealthKit)
    return RecentWorkoutsData(workouts: details.workoutReports)
  }

  func calculateActiveEnergyChartData() async -> ActiveEnergyChartData? {
    let calendar = Calendar.current
    let now = Date()

    guard let startDate = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) else {
      return nil
    }

    let dateRange = DateRange(startDate, now)

    let energySamples = await healthStoreFetcher.fetchCollatedQuantity(
      for: .activeEnergyBurned,
      unit: .kilocalorie(),
      interval: DateComponents(day: 1),
      dateRange: dateRange
    )

    guard energySamples.isNotEmpty else { return nil }

    // Build array for last 7 days (in order)
    let dailyValues: [Double] = (0..<7).map { dayOffset in
      guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { return 0 }
      if let sample = energySamples.first(where: { calendar.isDate($0.date, inSameDayAs: dayDate) }) {
        return sample.quantity.doubleValue(for: .kilocalorie())
      }
      return 0
    }

    let nonZeroValues = dailyValues.filter { $0 > 0 }
    let average = nonZeroValues.isEmpty ? 0 : nonZeroValues.reduce(0, +) / Double(nonZeroValues.count)

    return ActiveEnergyChartData(dailyValues: dailyValues, average: average)
  }

  func calculateSleepDurationChartData(from sleepAnalyses: [SleepAnalysis]) -> SleepDurationChartData? {
    guard sleepAnalyses.isNotEmpty else { return nil }

    let calendar = Calendar.current
    let now = Date()

    // Build array for last 7 days (in order)
    let dailyValues: [TimeInterval] = (0..<7).reversed().map { daysAgo in
      guard let targetDate = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { return 0 }

      if let analysis = sleepAnalyses.first(where: { calendar.isDate($0.endDate, inSameDayAs: targetDate) }) {
        return analysis.overallMinutes * 60  // Convert to seconds
      }
      return 0
    }

    let nonZeroValues = dailyValues.filter { $0 > 0 }
    let average = nonZeroValues.isEmpty ? 0 : nonZeroValues.reduce(0, +) / Double(nonZeroValues.count)

    return SleepDurationChartData(dailyValues: dailyValues, average: average)
  }
}

struct WristTempData: Sendable {
  let weeklyAverage: Double  // in Fahrenheit
  let latestTemp: Double     // in Fahrenheit
}

struct SleepHeartRateDataPoint: Identifiable, Sendable {
  var id: Date { date }
  let date: Date
  let heartRate: Double
}

struct RespiratoryRateDataPoint: Identifiable, Sendable {
  var id: Date { date }
  let date: Date
  let rate: Double
}

enum RespiratoryRateTrend: Sendable {
  case consistent
  case increasing
  case decreasing

  var displayText: String {
    switch self {
    case .consistent: "Consistent"
    case .increasing: "Increasing"
    case .decreasing: "Decreasing"
    }
  }
}

struct WeeklyStepsChartData: Sendable {
  let thisWeekDataPoints: [StepsDataPoint]
  let lastWeekDataPoints: [StepsDataPoint]
  let totalStepsThisWeek: Int
  let percentageChangeFromLastWeek: Double?
}

struct StepsDataPoint: Identifiable, Sendable {
  var id: String { "\(series)-\(index)" }
  let date: Date
  let cumulativeSteps: Int
  let index: Int  // Position in the series (0-based)
  let series: String  // "This Week" or "Last Week"
}

struct HeartRateReserveChartData: Sendable {
  let dataPoints: [HeartRateReserveDataPoint]
  let currentHRR: Int  // Latest day's HRR value
}

struct HeartRateReserveDataPoint: Identifiable, Sendable {
  var id: Date { date }
  let date: Date
  let maxHeartRate: Double       // Rolling 7-day max
  let restingHeartRate: Double   // Rolling 7-day avg resting
  let dayIndex: Int              // 0-6 for the 7 days

  var heartRateReserve: Double { maxHeartRate - restingHeartRate }
}

struct VO2MaxTrendData: Sendable {
  let latestValue: Double
  let trend: VO2MaxTrendDirection
}

enum VO2MaxTrendDirection: Sendable {
  case improving
  case constant
  case declining

  var displayText: String {
    switch self {
    case .improving: "Improving"
    case .constant: "Constant"
    case .declining: "Declining"
    }
  }
}

struct HeartRateRecoveryData: Sendable {
  let thisWeekAverage: Double?
  let lastWeekAverage: Double?
}

struct BodyWeightChartData: Sendable {
  let dataPoints: [BodyWeightDataPoint]
  let latestWeight: HKQuantity?
  let latestDate: Date?
}

struct BodyWeightDataPoint: Identifiable, Sendable {
  var id: Date { date }
  let date: Date
  let weight: Double
}

struct HRVTimeOfDayDataPoint: Identifiable, Sendable {
  var id: Double { hourWindow }
  let hourWindow: Double  // Midpoint of 3-hour window: 1.5, 4.5, 7.5, 10.5, 13.5, 16.5, 19.5, 22.5
  let averageHRV: Double
}

struct HRVChartData: Sendable {
  enum Trend: Sendable {
    case higher
    case lower
    case consistent
  }

  let sevenDayAverage: Double
  let thirtyDayAverage: Double
  let timeOfDayDataPoints: [HRVTimeOfDayDataPoint]

  var trend: Trend {
    let diff = sevenDayAverage - thirtyDayAverage
    let percentThreshold = thirtyDayAverage * 0.05  // 5%
    let absoluteThreshold: Double = 3  // 3ms
    // Must meet BOTH thresholds to show trending
    if diff >= percentThreshold && diff >= absoluteThreshold { return .higher }
    if diff <= -percentThreshold && diff <= -absoluteThreshold { return .lower }
    return .consistent
  }

  var trendText: String {
    switch trend {
    case .higher: "Increasing"
    case .lower: "Decreasing"
    case .consistent: "Consistent"
    }
  }
}

struct BloodPressureCardData: Sendable {
  let latestSystolic: Double
  let latestDiastolic: Double
  let latestDate: Date
  let category: BloodPressureCategory
}

struct FiberChartData: Sendable {
  let dailyValues: [Double]
  let averageGrams: Double
  let goal: Double

  var isSufficient: Bool { averageGrams >= goal }
}

struct SugarChartData: Sendable {
  let dailyValues: [Double]
  let averageGrams: Double
  let goal: Double

  var isExceeded: Bool { averageGrams > goal }
}

struct ZoneMinutesData: Sendable {
  let dailyValues: [Double]
  let weeklyTotal: Double
  let goal: Double = 150

  var meetsGoal: Bool { weeklyTotal >= goal }
}

struct ZoneDistributionData: Sendable {
  let zone1Percent: Double
  let zone2Percent: Double
  let zone3Percent: Double
  let zone4Percent: Double
  let zone5Percent: Double
  let workoutCount: Int
}

struct RecentWorkoutsData: Sendable {
  let workouts: [WorkoutHeartRateReport]
  var hasMore: Bool { workouts.count > 3 }
  var displayWorkouts: [WorkoutHeartRateReport] { Array(workouts.prefix(3)) }
}

struct ActiveEnergyChartData: Sendable {
  let dailyValues: [Double]  // 7 days of active energy in kcal
  let average: Double
}

struct SleepDurationChartData: Sendable {
  let dailyValues: [TimeInterval]  // 7 days of sleep duration in seconds
  let average: TimeInterval
}
