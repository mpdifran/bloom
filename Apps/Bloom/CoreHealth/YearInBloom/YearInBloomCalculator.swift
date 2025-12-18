//
//  YearInBloomCalculator.swift
//  CoreHealth
//
//  Created by Claude on 2025-12-12.
//

import Foundation
import HealthKit
import BloomFoundation

public final actor YearInBloomCalculator {
  public static let shared = YearInBloomCalculator()

  @AsyncStreamable public var workoutStats: YearInBloomWorkoutStats?
  @AsyncStreamable public var sleepStats: YearInBloomSleepStats?
  @AsyncStreamable public var menstrualStats: YearInBloomMenstrualStats?
  @AsyncStreamable public var heartHealthStats: YearInBloomHeartHealthStats?
  @AsyncStreamable public var bodyWeightStats: YearInBloomBodyWeightStats?
  @AsyncStreamable public var isCalculating: Bool = false

  private init() { }
}

// MARK: - Public API

public extension YearInBloomCalculator {

  /// Compile stats for the given year
  func compile(for year: Int) async {
    isCalculating = true
    defer { isCalculating = false }

    guard let stats = await calculateStats(for: year) else {
      workoutStats = nil
      return
    }

    workoutStats = stats
  }

  /// Compile sleep stats for the given year
  func compileSleep(for year: Int) async {
    guard let stats = await calculateSleepStats(for: year) else {
      sleepStats = nil
      return
    }

    sleepStats = stats
  }

  /// Compile menstrual cycle stats for the given year
  func compileMenstrual(for year: Int) async {
    // Don't compile for males
    guard HealthDefaults.shared.getSexKind() != .male else {
      menstrualStats = nil
      return
    }

    guard let stats = await calculateMenstrualStats(for: year) else {
      menstrualStats = nil
      return
    }

    menstrualStats = stats
  }

  /// Compile heart health stats for the given year
  func compileHeartHealth(for year: Int) async {
    guard let stats = await calculateHeartHealthStats(for: year) else {
      heartHealthStats = nil
      return
    }

    heartHealthStats = stats
  }

  /// Compile body weight stats for the given year
  func compileBodyWeight(for year: Int) async {
    guard let stats = await calculateBodyWeightStats(for: year) else {
      bodyWeightStats = nil
      return
    }

    bodyWeightStats = stats
  }
}

// MARK: - Core Calculation Logic

private extension YearInBloomCalculator {

  func calculateStats(for year: Int) async -> YearInBloomWorkoutStats? {
    let currentYear = Calendar.current.component(.year, from: .now)
    let yearsFromNow = currentYear - year
    let dateRange = DateRange.specificYear(yearsFromNow)

    // Fetch all workouts for the year
    let workouts = await HealthStoreFetcher.shared.fetchWorkouts(dateRange: dateRange)

    guard workouts.isNotEmpty else { return nil }

    // Fetch zone minutes data for the year
    let heartRateReports = await HealthStoreFetcher.shared.fetchWorkoutHeartRateReports(dateRange: dateRange)

    // Fetch total steps for the year
    let totalSteps: Int?
    if let stepsQuantity = await HealthStoreFetcher.shared.fetchTotalQuantity(for: .stepCount, dateRange: dateRange) {
      totalSteps = Int(stepsQuantity.doubleValue(for: .count()))
    } else {
      totalSteps = nil
    }

    // Group workouts and heart rate reports by month
    let calendar = Calendar.current
    let workoutsByMonth = Dictionary(grouping: workouts) { workout in
      calendar.component(.month, from: workout.startDate)
    }
    let reportsByMonth = Dictionary(grouping: heartRateReports) { report in
      calendar.component(.month, from: report.workout.startDate)
    }

    // Calculate monthly stats for all 12 months
    var monthlyStats = [MonthlyWorkoutStats]()
    var yearZoneMinutes = ZoneMinutesBreakdown.zero

    for month in 1...12 {
      let monthWorkouts = workoutsByMonth[month] ?? []
      let monthReports = reportsByMonth[month] ?? []

      // Calculate zone minutes for this month
      let zoneMinutes: ZoneMinutesBreakdown?
      if monthReports.isNotEmpty {
        let distribution = monthReports.generateOverallDistribution()
        let breakdown = ZoneMinutesBreakdown(
          zone1Minutes: distribution.zone1.doubleValue(for: .minute()),
          zone2Minutes: distribution.zone2.doubleValue(for: .minute()),
          zone3Minutes: distribution.zone3.doubleValue(for: .minute()),
          zone4Minutes: distribution.zone4.doubleValue(for: .minute()),
          zone5Minutes: distribution.zone5.doubleValue(for: .minute())
        )
        zoneMinutes = breakdown
        yearZoneMinutes = yearZoneMinutes + breakdown
      } else {
        zoneMinutes = nil
      }

      let stat = calculateMonthlyStats(
        month: month,
        workouts: monthWorkouts,
        allWorkouts: workouts,
        heartRateReports: monthReports,
        zoneMinutes: zoneMinutes
      )
      monthlyStats.append(stat)
    }

    // Calculate year totals
    let yearTotals = calculateYearTotals(workouts: workouts, totalZoneMinutes: yearZoneMinutes, totalSteps: totalSteps)

    // Calculate top workout types across the year
    let topWorkoutTypes = calculateTopWorkoutTypes(workouts: workouts, heartRateReports: heartRateReports)

    // Calculate longest streak
    let longestStreak = calculateLongestStreak(workouts: workouts)

    // Find best month by duration
    let bestMonth = monthlyStats.max { $0.totalDurationMinutes < $1.totalDurationMinutes }

    // Fetch VO2 max data for the year
    let vo2MaxSamples = await HealthStoreFetcher.shared.fetchCollatedAverage(
      quantityType: .vo2Max,
      unit: .vo2Max(),
      dateRange: dateRange
    )
    let monthlyVO2Max = calculateMonthlyVO2Max(samples: vo2MaxSamples, year: year)

    return YearInBloomWorkoutStats(
      year: year,
      monthlyStats: monthlyStats,
      yearTotals: yearTotals,
      topWorkoutTypes: topWorkoutTypes,
      longestStreak: longestStreak,
      bestMonth: bestMonth,
      monthlyVO2Max: monthlyVO2Max,
      generatedDate: .now
    )
  }

  func calculateMonthlyStats(
    month: Int,
    workouts: [HKWorkout],
    allWorkouts: [HKWorkout],
    heartRateReports: [WorkoutHeartRateReport],
    zoneMinutes: ZoneMinutesBreakdown?
  ) -> MonthlyWorkoutStats {
    let totalDuration = workouts.reduce(0.0) { $0 + $1.duration / 60 }
    let totalCalories = workouts.reduce(0.0) { total, workout in
      let calories = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .largeCalorie()) ?? 0
      return total + calories
    }

    let typeBreakdown = calculateTopWorkoutTypes(workouts: workouts, heartRateReports: heartRateReports)

    return MonthlyWorkoutStats(
      month: month,
      workoutCount: workouts.count,
      totalDurationMinutes: totalDuration,
      totalCaloriesBurned: totalCalories,
      workoutTypeBreakdown: typeBreakdown,
      zoneMinutes: zoneMinutes
    )
  }

  func calculateYearTotals(workouts: [HKWorkout], totalZoneMinutes: ZoneMinutesBreakdown, totalSteps: Int?) -> YearTotals {
    let totalDuration = workouts.reduce(0.0) { $0 + $1.duration / 60 }
    let totalCalories = workouts.reduce(0.0) { total, workout in
      let calories = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .largeCalorie()) ?? 0
      return total + calories
    }
    let uniqueTypes = Set(workouts.map(\.workoutActivityType)).count

    return YearTotals(
      totalWorkouts: workouts.count,
      totalDurationMinutes: totalDuration,
      totalCaloriesBurned: totalCalories,
      uniqueWorkoutTypes: uniqueTypes,
      totalZoneMinutes: totalZoneMinutes,
      totalSteps: totalSteps
    )
  }

  func calculateTopWorkoutTypes(
    workouts: [HKWorkout],
    heartRateReports: [WorkoutHeartRateReport]
  ) -> [WorkoutTypeStats] {
    let grouped = Dictionary(grouping: workouts) { $0.workoutActivityType }
    let totalDuration = workouts.reduce(0.0) { $0 + $1.duration / 60 }

    // Group heart rate reports by workout type
    let reportsByType = Dictionary(grouping: heartRateReports) { $0.workout.workoutActivityType }

    let stats = grouped.map { (type, typeWorkouts) -> WorkoutTypeStats in
      let typeDuration = typeWorkouts.reduce(0.0) { $0 + $1.duration / 60 }
      let typeCalories = typeWorkouts.reduce(0.0) { total, workout in
        let calories = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .largeCalorie()) ?? 0
        return total + calories
      }

      // Calculate total distance for this workout type
      let typeDistance = typeWorkouts.reduce(0.0) { total, workout in
        total + (workout.totalDistanceWalkingRunningCycling?.doubleValue(for: .meter()) ?? 0)
      }

      // Calculate zone minutes for this workout type
      let typeReports = reportsByType[type] ?? []
      let zoneMinutes: ZoneMinutesBreakdown?
      if typeReports.isNotEmpty {
        let distribution = typeReports.generateOverallDistribution()
        zoneMinutes = ZoneMinutesBreakdown(
          zone1Minutes: distribution.zone1.doubleValue(for: .minute()),
          zone2Minutes: distribution.zone2.doubleValue(for: .minute()),
          zone3Minutes: distribution.zone3.doubleValue(for: .minute()),
          zone4Minutes: distribution.zone4.doubleValue(for: .minute()),
          zone5Minutes: distribution.zone5.doubleValue(for: .minute())
        )
      } else {
        zoneMinutes = nil
      }

      return WorkoutTypeStats(
        activityTypeRawValue: type.rawValue,
        activityName: type.name,
        count: typeWorkouts.count,
        totalDurationMinutes: typeDuration,
        totalCaloriesBurned: typeCalories,
        percentage: totalDuration > 0 ? (typeDuration / totalDuration) * 100 : 0,
        zoneMinutes: zoneMinutes,
        totalDistanceMeters: typeDistance > 0 ? typeDistance : nil
      )
    }

    return Array(stats
      .filter { $0.scaledZoneMinutes > 0 }
      .sorted { $0.scaledZoneMinutes > $1.scaledZoneMinutes }
    )
  }

  func calculateLongestStreak(workouts: [HKWorkout]) -> StreakInfo {
    let calendar = Calendar.current

    // Get unique workout days, sorted
    let sortedDates = Set(workouts.map { calendar.startOfDay(for: $0.startDate) }).sorted()

    guard sortedDates.isNotEmpty else {
      return StreakInfo(longestStreakDays: 0, streakStartDate: nil, streakEndDate: nil)
    }

    var longestStreak = 1
    var currentStreak = 1
    var longestStart = sortedDates[0]
    var longestEnd = sortedDates[0]
    var currentStart = sortedDates[0]

    for i in 1..<sortedDates.count {
      let previousDate = sortedDates[i - 1]
      let currentDate = sortedDates[i]

      // Check if dates are consecutive
      if let nextDay = calendar.date(byAdding: .day, value: 1, to: previousDate),
         calendar.isDate(currentDate, inSameDayAs: nextDay) {
        currentStreak += 1
        if currentStreak > longestStreak {
          longestStreak = currentStreak
          longestStart = currentStart
          longestEnd = currentDate
        }
      } else {
        currentStreak = 1
        currentStart = currentDate
      }
    }

    return StreakInfo(
      longestStreakDays: longestStreak,
      streakStartDate: longestStart,
      streakEndDate: longestEnd
    )
  }

  func calculateMonthlyVO2Max(samples: [DateQuantitySample], year: Int) -> [MonthlyVO2MaxData] {
    let calendar = Calendar.current
    let samplesByMonth = Dictionary(grouping: samples) { sample in
      calendar.component(.month, from: sample.date)
    }

    return (1...12).map { (month: Int) -> MonthlyVO2MaxData in
      let date = calendar.date(from: DateComponents(year: year, month: month, day: 15))!
      let monthSamples = samplesByMonth[month] ?? []
      let average: Double?
      if monthSamples.isEmpty {
        average = nil
      } else {
        let sum = monthSamples.map { $0.quantity.doubleValue(for: .vo2Max()) }.reduce(0.0, +)
        average = sum / Double(monthSamples.count)
      }
      return MonthlyVO2MaxData(date: date, averageVO2Max: average)
    }
  }

  func calculateSleepStats(for year: Int) async -> YearInBloomSleepStats? {
    let currentYear = Calendar.current.component(.year, from: .now)
    let yearsFromNow = currentYear - year
    let dateRange = DateRange.specificYear(yearsFromNow)

    // Fetch all sleep data for the year
    let sleepAnalyses = await HealthStoreFetcher.shared.fetchSleepAnalysis(dateRange: dateRange)

    // Filter to only include analyses with detailed sleep categories
    let detailedAnalyses = sleepAnalyses.filter { $0.hasDetailedSleepCategories }

    guard detailedAnalyses.isNotEmpty else { return nil }

    // Group by month
    let calendar = Calendar.current
    let analysesByMonth = Dictionary(grouping: detailedAnalyses) { analysis in
      calendar.component(.month, from: analysis.normalizedDate)
    }

    // Calculate monthly stats for all 12 months
    var monthlySleepStats = [MonthlySleepStats]()

    for month in 1...12 {
      let monthAnalyses = analysesByMonth[month] ?? []

      let stat: MonthlySleepStats
      if monthAnalyses.isEmpty {
        stat = MonthlySleepStats(
          month: month,
          sleepSessionCount: 0,
          averageCoreSleepPercent: 0,
          averageDeepSleepPercent: 0,
          averageRemSleepPercent: 0,
          averageAwakeSleepPercent: 0,
          averageCoreSleepMinutes: 0,
          averageDeepSleepMinutes: 0,
          averageRemSleepMinutes: 0,
          averageAwakeSleepMinutes: 0,
          averageSleepDurationMinutes: 0,
          averageSleepScore: 0,
          averageBedtimeMinutes: 0,
          averageWakeTimeMinutes: 0
        )
      } else {
        // Calculate average bedtime (startDate) and wake time (endDate) as minutes from noon
        let bedtimes = monthAnalyses.map { getMinutesFromNoon(from: $0.startDate) }
        let wakeTimes = monthAnalyses.map { getMinutesFromNoon(from: $0.endDate) }
        let avgBedtime = bedtimes.reduce(0, +) / Double(bedtimes.count)
        let avgWakeTime = wakeTimes.reduce(0, +) / Double(wakeTimes.count)

        stat = MonthlySleepStats(
          month: month,
          sleepSessionCount: monthAnalyses.count,
          averageCoreSleepPercent: monthAnalyses.average(keyPath: \.coreSleepPercent),
          averageDeepSleepPercent: monthAnalyses.average(keyPath: \.deepSleepPercent),
          averageRemSleepPercent: monthAnalyses.average(keyPath: \.remSleepPercent),
          averageAwakeSleepPercent: monthAnalyses.average(keyPath: \.awakeSleepPercent),
          averageCoreSleepMinutes: monthAnalyses.average(keyPath: \.coreSleepMinutes),
          averageDeepSleepMinutes: monthAnalyses.average(keyPath: \.deepSleepMinutes),
          averageRemSleepMinutes: monthAnalyses.average(keyPath: \.remSleepMinutes),
          averageAwakeSleepMinutes: monthAnalyses.average(keyPath: \.awakeSleepMinutes),
          averageSleepDurationMinutes: monthAnalyses.average(keyPath: \.overallMinutes),
          averageSleepScore: monthAnalyses.average(keyPath: \.overallScoreDouble),
          averageBedtimeMinutes: avgBedtime,
          averageWakeTimeMinutes: avgWakeTime
        )
      }
      monthlySleepStats.append(stat)
    }

    // Calculate year totals
    let yearTotals = SleepYearTotals(
      totalSleepSessions: detailedAnalyses.count,
      averageCoreSleepPercent: detailedAnalyses.average(keyPath: \.coreSleepPercent),
      averageDeepSleepPercent: detailedAnalyses.average(keyPath: \.deepSleepPercent),
      averageRemSleepPercent: detailedAnalyses.average(keyPath: \.remSleepPercent),
      averageAwakeSleepPercent: detailedAnalyses.average(keyPath: \.awakeSleepPercent),
      averageSleepDurationMinutes: detailedAnalyses.average(keyPath: \.overallMinutes),
      averageSleepScore: detailedAnalyses.average(keyPath: \.overallScoreDouble)
    )

    // Find lowest individual sleep score (excluding 0)
    let lowestAnalysis = detailedAnalyses
      .filter { $0.overallScore > 0 }
      .min { $0.overallScoreDouble < $1.overallScoreDouble }
    let lowestSleepScore = lowestAnalysis.map { analysis in
      SleepScoreExtreme(
        score: analysis.overallScore,
        month: calendar.component(.month, from: analysis.normalizedDate)
      )
    }

    // Find highest individual sleep score
    let highestAnalysis = detailedAnalyses
      .max { $0.overallScoreDouble < $1.overallScoreDouble }
    let highestSleepScore = highestAnalysis.map { analysis in
      SleepScoreExtreme(
        score: analysis.overallScore,
        month: calendar.component(.month, from: analysis.normalizedDate)
      )
    }

    return YearInBloomSleepStats(
      year: year,
      monthlySleepStats: monthlySleepStats,
      yearTotals: yearTotals,
      lowestSleepScore: lowestSleepScore,
      highestSleepScore: highestSleepScore,
      generatedDate: .now
    )
  }

  /// Convert time to minutes from noon (0 = 12 PM, 720 = 12 AM, 1080 = 6 AM)
  /// This avoids wraparound issues since sleep times naturally span evening to morning
  func getMinutesFromNoon(from date: Date) -> Double {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.hour, .minute], from: date)
    let hours = Double(components.hour ?? 0)
    let minutes = Double(components.minute ?? 0)
    let minutesFromMidnight = hours * 60 + minutes
    var minutesFromNoon = minutesFromMidnight - 720
    if minutesFromNoon < 0 {
      minutesFromNoon += 1440
    }
    return minutesFromNoon
  }

  // MARK: - Menstrual Stats Calculation

  func calculateMenstrualStats(for year: Int) async -> YearInBloomMenstrualStats? {
    let currentYear = Calendar.current.component(.year, from: .now)
    let yearsFromNow = currentYear - year
    let dateRange = DateRange.specificYear(yearsFromNow)

    // Fetch menstrual cycles for the year
    let cycles = await HealthStoreFetcher.shared.fetchMenstrualFlowSamples(dateRange: dateRange)

    guard cycles.isNotEmpty else { return nil }

    let calendar = Calendar.current

    // Calculate cycle durations (days between consecutive cycle starts)
    var cycleDurations: [(duration: Int, startDate: Date)] = []
    let sortedCycles = cycles.sorted { $0.startDate < $1.startDate }

    for i in 0..<(sortedCycles.count - 1) {
      let currentCycle = sortedCycles[i]
      let nextCycle = sortedCycles[i + 1]
      if let days = calendar.dateComponents([.day], from: currentCycle.startDate, to: nextCycle.startDate).day {
        // Only count reasonable cycle lengths (21-45 days)
        if days >= 21 && days <= 45 {
          cycleDurations.append((duration: days, startDate: currentCycle.startDate))
        }
      }
    }

    guard cycleDurations.isNotEmpty else { return nil }

    // Calculate average, shortest, longest
    let averageDuration = Double(cycleDurations.map(\.duration).reduce(0, +)) / Double(cycleDurations.count)
    let shortest = cycleDurations.min { $0.duration < $1.duration }
    let longest = cycleDurations.max { $0.duration < $1.duration }

    // Calculate average period length
    let periodLengths = cycles.compactMap { $0.menstruationDurationDays }
    let averagePeriodLength: Double? = periodLengths.isEmpty ? nil :
      Double(periodLengths.reduce(0, +)) / Double(periodLengths.count)

    // Calculate phase-based metrics
    let phaseMetrics = await calculatePhaseMetrics(cycles: sortedCycles, year: year)

    return YearInBloomMenstrualStats(
      year: year,
      totalCycles: cycles.count,
      averageCycleDuration: averageDuration,
      averagePeriodLength: averagePeriodLength,
      shortestCycle: shortest.map { CycleExtreme(duration: $0.duration, startDate: $0.startDate) },
      longestCycle: longest.map { CycleExtreme(duration: $0.duration, startDate: $0.startDate) },
      follicularActivityIncrease: phaseMetrics.follicularActivityIncrease,
      lutealRestingHRChange: phaseMetrics.lutealRestingHRChange,
      lutealSleepEfficiencyChange: phaseMetrics.lutealSleepEfficiencyChange,
      monthlyPhaseActivityData: phaseMetrics.monthlyPhaseActivity,
      generatedDate: .now
    )
  }

  struct PhaseMetrics {
    let follicularActivityIncrease: Double?
    let lutealRestingHRChange: Double?
    let lutealSleepEfficiencyChange: Double?
    let monthlyPhaseActivity: [MonthlyPhaseActivityData]
  }

  func calculatePhaseMetrics(cycles: [MenstrualCycle], year: Int) async -> PhaseMetrics {
    let calendar = Calendar.current
    let currentYear = Calendar.current.component(.year, from: .now)
    let yearsFromNow = currentYear - year
    let dateRange = DateRange.specificYear(yearsFromNow)

    // Determine follicular and luteal date ranges for each cycle
    var follicularDates: [Date] = []
    var lutealDates: [Date] = []

    for i in 0..<cycles.count {
      let cycle = cycles[i]
      let cycleStartDate = cycle.startDate

      // Determine cycle duration (use next cycle start if available, otherwise assume 28 days)
      let cycleDuration: Int
      if i < cycles.count - 1 {
        let nextCycle = cycles[i + 1]
        cycleDuration = calendar.dateComponents([.day], from: cycleStartDate, to: nextCycle.startDate).day ?? 28
      } else {
        cycleDuration = 28
      }

      // Skip if cycle is unreasonably short or long
      guard cycleDuration >= 21 && cycleDuration <= 45 else { continue }

      let menstruationDuration = cycle.menstruationDurationDays ?? 5
      let ovulationDay = cycleDuration / 2

      // Follicular phase: after menstruation ends until 2 days before ovulation (day ~6 to ~12)
      let follicularStart = menstruationDuration + 1
      let follicularEnd = ovulationDay - 2

      // Luteal phase: after ovulation until end of cycle (day ~15 to ~28)
      let lutealStart = ovulationDay + 2
      let lutealEnd = cycleDuration

      // Add dates to respective arrays
      for day in follicularStart...follicularEnd {
        if let date = calendar.date(byAdding: .day, value: day - 1, to: cycleStartDate) {
          // Only include dates within the target year
          if calendar.component(.year, from: date) == year {
            follicularDates.append(date)
          }
        }
      }

      for day in lutealStart...lutealEnd {
        if let date = calendar.date(byAdding: .day, value: day - 1, to: cycleStartDate) {
          if calendar.component(.year, from: date) == year {
            lutealDates.append(date)
          }
        }
      }
    }

    // Fetch health data for the year
    async let activeEnergy = HealthStoreFetcher.shared.fetchCollatedQuantity(
      for: .activeEnergyBurned,
      unit: .largeCalorie(),
      options: .cumulativeSum,
      dateRange: dateRange
    )
    async let basalEnergy = HealthStoreFetcher.shared.fetchCollatedQuantity(
      for: .basalEnergyBurned,
      unit: .largeCalorie(),
      options: .cumulativeSum,
      dateRange: dateRange
    )
    async let restingHR = HealthStoreFetcher.shared.fetchCollatedAverage(
      quantityType: .restingHeartRate,
      unit: .bpm(),
      dateRange: dateRange
    )
    async let sleepData = HealthStoreFetcher.shared.fetchSleepAnalysis(dateRange: dateRange)

    let (activeSamples, basalSamples, hrSamples, sleepAnalyses) = await (activeEnergy, basalEnergy, restingHR, sleepData)

    // Calculate activity level (active/basal ratio) by phase
    let follicularActivity = calculateAverageActivityLevel(
      activeSamples: activeSamples,
      basalSamples: basalSamples,
      forDates: follicularDates,
      calendar: calendar
    )
    let lutealActivity = calculateAverageActivityLevel(
      activeSamples: activeSamples,
      basalSamples: basalSamples,
      forDates: lutealDates,
      calendar: calendar
    )
    let overallActivity = calculateAverageActivityLevel(
      activeSamples: activeSamples,
      basalSamples: basalSamples,
      forDates: nil,
      calendar: calendar
    )

    // Calculate follicular activity increase vs baseline
    let follicularActivityIncrease: Double?
    if let follicular = follicularActivity, let overall = overallActivity, overall > 0 {
      follicularActivityIncrease = ((follicular - overall) / overall) * 100
    } else {
      follicularActivityIncrease = nil
    }

    // Calculate resting HR by phase
    let follicularHR = calculateAverageValue(samples: hrSamples, forDates: follicularDates, calendar: calendar)
    let lutealHR = calculateAverageValue(samples: hrSamples, forDates: lutealDates, calendar: calendar)

    let lutealRestingHRChange: Double?
    if let follicular = follicularHR, let luteal = lutealHR {
      lutealRestingHRChange = luteal - follicular
    } else {
      lutealRestingHRChange = nil
    }

    // Calculate sleep efficiency by phase
    let follicularSleepEfficiency = calculateAverageSleepEfficiency(
      analyses: sleepAnalyses,
      forDates: follicularDates,
      calendar: calendar
    )
    let lutealSleepEfficiency = calculateAverageSleepEfficiency(
      analyses: sleepAnalyses,
      forDates: lutealDates,
      calendar: calendar
    )

    let lutealSleepEfficiencyChange: Double?
    if let follicular = follicularSleepEfficiency, let luteal = lutealSleepEfficiency {
      lutealSleepEfficiencyChange = luteal - follicular
    } else {
      lutealSleepEfficiencyChange = nil
    }

    // Calculate monthly phase activity
    let monthlyPhaseActivity = calculateMonthlyPhaseActivity(
      activeSamples: activeSamples,
      basalSamples: basalSamples,
      follicularDates: follicularDates,
      year: year,
      calendar: calendar
    )

    return PhaseMetrics(
      follicularActivityIncrease: follicularActivityIncrease,
      lutealRestingHRChange: lutealRestingHRChange,
      lutealSleepEfficiencyChange: lutealSleepEfficiencyChange,
      monthlyPhaseActivity: monthlyPhaseActivity
    )
  }

  func calculateMonthlyPhaseActivity(
    activeSamples: [DateQuantitySample],
    basalSamples: [DateQuantitySample],
    follicularDates: [Date],
    year: Int,
    calendar: Calendar
  ) -> [MonthlyPhaseActivityData] {
    // Group follicular dates by month
    let follicularByMonth = Dictionary(grouping: follicularDates) { date in
      calendar.component(.month, from: date)
    }

    // Group all active/basal samples by day
    let activeByDay = Dictionary(grouping: activeSamples) { calendar.startOfDay(for: $0.date) }
    let basalByDay = Dictionary(grouping: basalSamples) { calendar.startOfDay(for: $0.date) }

    // Get all days with activity data grouped by month
    let allDays = Set(activeByDay.keys)
    let allDaysByMonth = Dictionary(grouping: allDays) { date in
      calendar.component(.month, from: date)
    }

    var monthlyData = [MonthlyPhaseActivityData]()

    for month in 1...12 {
      let date = calendar.date(from: DateComponents(year: year, month: month, day: 15))!

      // Get follicular days for this month
      let follicularDaysThisMonth = Set((follicularByMonth[month] ?? []).map { calendar.startOfDay(for: $0) })

      // Get all days this month
      let allDaysThisMonth = allDaysByMonth[month] ?? []

      // Calculate follicular activity for this month
      var follicularRatios: [Double] = []
      var otherRatios: [Double] = []

      for day in allDaysThisMonth {
        let activeSamplesForDay = activeByDay[day] ?? []
        let basalSamplesForDay = basalByDay[day] ?? []

        let activeTotal = activeSamplesForDay.reduce(0.0) { $0 + $1.quantity.doubleValue(for: .largeCalorie()) }
        let basalTotal = basalSamplesForDay.reduce(0.0) { $0 + $1.quantity.doubleValue(for: .largeCalorie()) }

        guard basalTotal > 0 else { continue }

        let ratio = activeTotal / basalTotal

        if follicularDaysThisMonth.contains(day) {
          follicularRatios.append(ratio)
        } else {
          otherRatios.append(ratio)
        }
      }

      let follicularActivity: Double? = follicularRatios.isNotEmpty
        ? follicularRatios.reduce(0, +) / Double(follicularRatios.count)
        : nil

      let otherActivity: Double? = otherRatios.isNotEmpty
        ? otherRatios.reduce(0, +) / Double(otherRatios.count)
        : nil

      monthlyData.append(MonthlyPhaseActivityData(
        date: date,
        follicularActivityLevel: follicularActivity,
        otherActivityLevel: otherActivity
      ))
    }

    return monthlyData
  }

  func calculateAverageActivityLevel(
    activeSamples: [DateQuantitySample],
    basalSamples: [DateQuantitySample],
    forDates targetDates: [Date]?,
    calendar: Calendar
  ) -> Double? {
    // Group samples by day
    let activeByDay = Dictionary(grouping: activeSamples) { calendar.startOfDay(for: $0.date) }
    let basalByDay = Dictionary(grouping: basalSamples) { calendar.startOfDay(for: $0.date) }

    var ratios: [Double] = []

    let daysToCheck: [Date]
    if let targetDates = targetDates {
      daysToCheck = Array(Set(targetDates.map { calendar.startOfDay(for: $0) }))
    } else {
      daysToCheck = Array(Set(activeByDay.keys))
    }

    for day in daysToCheck {
      let activeSamplesForDay = activeByDay[day] ?? []
      let basalSamplesForDay = basalByDay[day] ?? []

      let activeTotal = activeSamplesForDay.reduce(0.0) { $0 + $1.quantity.doubleValue(for: .largeCalorie()) }
      let basalTotal = basalSamplesForDay.reduce(0.0) { $0 + $1.quantity.doubleValue(for: .largeCalorie()) }

      if basalTotal > 0 {
        ratios.append(activeTotal / basalTotal)
      }
    }

    guard ratios.isNotEmpty else { return nil }
    return ratios.reduce(0, +) / Double(ratios.count)
  }

  func calculateAverageValue(
    samples: [DateQuantitySample],
    forDates targetDates: [Date],
    calendar: Calendar
  ) -> Double? {
    let targetDaySet = Set(targetDates.map { calendar.startOfDay(for: $0) })

    let filteredSamples = samples.filter { sample in
      targetDaySet.contains(calendar.startOfDay(for: sample.date))
    }

    guard filteredSamples.isNotEmpty else { return nil }

    let sum = filteredSamples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: .bpm()) }
    return sum / Double(filteredSamples.count)
  }

  func calculateAverageSleepEfficiency(
    analyses: [SleepAnalysis],
    forDates targetDates: [Date],
    calendar: Calendar
  ) -> Double? {
    let targetDaySet = Set(targetDates.map { calendar.startOfDay(for: $0) })

    let filteredAnalyses = analyses.filter { analysis in
      targetDaySet.contains(calendar.startOfDay(for: analysis.normalizedDate))
    }

    guard filteredAnalyses.isNotEmpty else { return nil }

    // Sleep efficiency = time asleep / time in bed
    var efficiencies: [Double] = []
    for analysis in filteredAnalyses {
      let timeInBed = analysis.endDate.timeIntervalSince(analysis.startDate) / 60 // minutes
      let timeAsleep = analysis.overallMinutes - analysis.awakeSleepMinutes
      if timeInBed > 0 {
        efficiencies.append((timeAsleep / timeInBed) * 100)
      }
    }

    guard efficiencies.isNotEmpty else { return nil }
    return efficiencies.reduce(0, +) / Double(efficiencies.count)
  }

  // MARK: - Heart Health Stats Calculation

  func calculateHeartHealthStats(for year: Int) async -> YearInBloomHeartHealthStats? {
    let currentYear = Calendar.current.component(.year, from: .now)
    let yearsFromNow = currentYear - year
    let dateRange = DateRange.specificYear(yearsFromNow)
    let calendar = Calendar.current

    // Fetch resting heart rate data
    let restingHRSamples = await HealthStoreFetcher.shared.fetchCollatedAverage(
      quantityType: .restingHeartRate,
      unit: .bpm(),
      interval: DateComponents(day: 1),
      dateRange: dateRange
    )

    // Fetch min heart rate data (daily minimums)
    let minHRSamples = await HealthStoreFetcher.shared.fetchCollatedQuantity(
      for: .heartRate,
      unit: .bpm(),
      interval: DateComponents(day: 1),
      options: .discreteMin,
      dateRange: dateRange
    )

    // Fetch workout heart rate reports for max HR
    let workoutReports = await HealthStoreFetcher.shared.fetchWorkoutHeartRateReports(dateRange: dateRange)

    // Fetch HRV data
    let hrvSamples = await HealthStoreFetcher.shared.fetchCollatedAverage(
      quantityType: .heartRateVariabilitySDNN,
      unit: .secondUnit(with: .milli),
      interval: DateComponents(day: 1),
      dateRange: dateRange
    )

    // Group data by month
    let restingHRByMonth = Dictionary(grouping: restingHRSamples) { sample in
      calendar.component(.month, from: sample.date)
    }
    let minHRByMonth = Dictionary(grouping: minHRSamples) { sample in
      calendar.component(.month, from: sample.date)
    }
    let workoutReportsByMonth = Dictionary(grouping: workoutReports) { report in
      calendar.component(.month, from: report.workout.startDate)
    }
    let hrvByMonth = Dictionary(grouping: hrvSamples) { sample in
      calendar.component(.month, from: sample.date)
    }

    // Calculate monthly heart rate data
    var monthlyHeartRateData = [MonthlyHeartRateData]()
    var monthlyHRVData = [MonthlyHRVData]()

    for month in 1...12 {
      let date = calendar.date(from: DateComponents(year: year, month: month, day: 15))!

      // Calculate average resting HR for the month
      let monthRestingHRSamples = restingHRByMonth[month] ?? []
      let averageRestingHR: Double?
      if monthRestingHRSamples.isNotEmpty {
        let sum = monthRestingHRSamples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: .bpm()) }
        averageRestingHR = sum / Double(monthRestingHRSamples.count)
      } else {
        averageRestingHR = nil
      }

      // Calculate average min HR for the month (average of daily minimums)
      let monthMinHRSamples = minHRByMonth[month] ?? []
      let averageMinHR: Double?
      if monthMinHRSamples.isNotEmpty {
        let sum = monthMinHRSamples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: .bpm()) }
        averageMinHR = sum / Double(monthMinHRSamples.count)
      } else {
        averageMinHR = nil
      }

      // Calculate max HR from workout reports for the month
      let monthWorkoutReports = workoutReportsByMonth[month] ?? []
      let maxHRValues = monthWorkoutReports.compactMap(\.maxHeartRate)
      let averageMaxHR: Double? = maxHRValues.isNotEmpty ? maxHRValues.max() : nil

      monthlyHeartRateData.append(MonthlyHeartRateData(
        date: date,
        averageRestingHR: averageRestingHR,
        averageMinHR: averageMinHR,
        averageMaxHR: averageMaxHR
      ))

      // Calculate average HRV for the month
      let monthHRVSamples = hrvByMonth[month] ?? []
      let averageHRV: Double?
      if monthHRVSamples.isNotEmpty {
        let sum = monthHRVSamples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: .secondUnit(with: .milli)) }
        averageHRV = sum / Double(monthHRVSamples.count)
      } else {
        averageHRV = nil
      }

      monthlyHRVData.append(MonthlyHRVData(date: date, averageHRV: averageHRV))
    }

    // Calculate yearly average resting HR
    let allRestingHRValues = restingHRSamples.map { $0.quantity.doubleValue(for: .bpm()) }
    let yearlyAverageRestingHR: Double? = allRestingHRValues.isNotEmpty
      ? allRestingHRValues.reduce(0, +) / Double(allRestingHRValues.count)
      : nil

    // Only return stats if we have some data
    guard restingHRSamples.isNotEmpty || hrvSamples.isNotEmpty else { return nil }

    return YearInBloomHeartHealthStats(
      year: year,
      monthlyHeartRateData: monthlyHeartRateData,
      monthlyHRVData: monthlyHRVData,
      yearlyAverageRestingHR: yearlyAverageRestingHR,
      generatedDate: .now
    )
  }

  func calculateBodyWeightStats(for year: Int) async -> YearInBloomBodyWeightStats? {
    let currentYear = Calendar.current.component(.year, from: .now)
    let yearsFromNow = currentYear - year
    let dateRange = DateRange.specificYear(yearsFromNow)
    let calendar = Calendar.current

    // Fetch body mass samples (in pounds as base unit)
    let weightSamples = await HealthStoreFetcher.shared.fetchCollatedAverage(
      quantityType: .bodyMass,
      unit: .pound(),
      interval: DateComponents(day: 1),
      dateRange: dateRange
    )

    // Fetch body fat samples
    let bodyFatSamples = await HealthStoreFetcher.shared.fetchCollatedAverage(
      quantityType: .bodyFatPercentage,
      unit: .percent(),
      interval: DateComponents(day: 1),
      dateRange: dateRange
    )

    // Group by month
    let weightByMonth = Dictionary(grouping: weightSamples) { sample in
      calendar.component(.month, from: sample.date)
    }
    let bodyFatByMonth = Dictionary(grouping: bodyFatSamples) { sample in
      calendar.component(.month, from: sample.date)
    }

    // Calculate monthly weight data
    var monthlyWeightData = [MonthlyWeightData]()
    var monthlyBodyFatData = [MonthlyBodyFatData]()

    for month in 1...12 {
      let date = calendar.date(from: DateComponents(year: year, month: month, day: 15))!

      // Calculate weight stats for the month
      let monthWeightSamples = weightByMonth[month] ?? []
      let weightValues = monthWeightSamples.map { $0.quantity.doubleValue(for: .pound()) }

      let minWeight: Double? = weightValues.min()
      let maxWeight: Double? = weightValues.max()
      let averageWeight: Double? = weightValues.isNotEmpty
        ? weightValues.reduce(0, +) / Double(weightValues.count)
        : nil

      monthlyWeightData.append(MonthlyWeightData(
        date: date,
        minWeight: minWeight,
        maxWeight: maxWeight,
        averageWeight: averageWeight
      ))

      // Calculate body fat for the month
      let monthBodyFatSamples = bodyFatByMonth[month] ?? []
      let bodyFatValues = monthBodyFatSamples.map { $0.quantity.doubleValue(for: .percent()) }
      let averageBodyFat: Double? = bodyFatValues.isNotEmpty
        ? bodyFatValues.reduce(0, +) / Double(bodyFatValues.count)
        : nil

      monthlyBodyFatData.append(MonthlyBodyFatData(date: date, averageBodyFat: averageBodyFat))
    }

    // Determine year start and end weights
    let monthsWithWeight = monthlyWeightData.filter { $0.averageWeight != nil }
    let yearStartWeight = monthsWithWeight.first?.averageWeight
    let yearEndWeight = monthsWithWeight.last?.averageWeight

    // Only return stats if we have some weight data
    guard weightSamples.isNotEmpty else { return nil }

    return YearInBloomBodyWeightStats(
      year: year,
      monthlyWeightData: monthlyWeightData,
      monthlyBodyFatData: monthlyBodyFatData,
      yearStartWeight: yearStartWeight,
      yearEndWeight: yearEndWeight,
      generatedDate: .now
    )
  }
}

