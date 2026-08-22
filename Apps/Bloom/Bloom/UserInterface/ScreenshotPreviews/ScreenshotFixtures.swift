//
//  ScreenshotFixtures.swift
//  Bloom
//

import Foundation
import UIKit
import BloomFoundation
import BloomUI
import HealthKit
import CoreHealth
import DataContainer

/// Fake, translated content for the App Store screenshot previews.
///
/// Every user-visible string here goes through `String(localized:locale:)` with an explicit locale,
/// rather than the bundle's preferred language. That matters: the screenshot views feed plain
/// `String`s into cells, so without an explicit locale the copy would always render in the language
/// of the machine taking the screenshot, no matter which locale the preview asks for. Pass a locale
/// and the whole screen switches language - one preview per locale, no app build per language.
///
/// The values are invented. Nothing here should read as a real person's health data.
struct ScreenshotFixtures {
  let locale: Locale

  init(locale: Locale = .current) {
    self.locale = locale
  }

  // MARK: - Shared

  /// The name shown in the app UI. Not localized per market: it appears beside a photo of the same
  /// person, so a different name per language would read as a mismatch.
  var firstName: String {
    String(
      localized: "screenshot.name",
      defaultValue: "Mark",
      locale: locale,
      comment: "App Store screenshot: the fictional person's first name shown in the app UI"
    )
  }

  /// The profile photo shown in the toolbar.
  ///
  /// Lives in `Preview Content/Preview Assets.xcassets`, which Xcode strips from release builds -
  /// so a real personal photo never ships in the app. Returns nil in release, and the toolbar
  /// button falls back to its usual placeholder.
  var avatar: UIImage? {
    UIImage(named: "ScreenshotAvatar")
  }

  // MARK: - You

  /// Shown in the meter and the header. Chosen to read as a clear win without looking implausible.
  var biologicalAge: Double { 30.2 }
  var chronologicalAge: Double { 36.7 }

  /// Seven nights of bedtimes: a weekday cluster near 11pm, later on the weekend, one late night.
  ///
  /// Deliberately uneven - an evenly-stepped ramp reads as synthetic in a screenshot, and the trend
  /// label is computed from these points rather than asserted.
  func bedtimeData(endingAt endDate: Date) -> BedtimeChartData {
    let calendar = Calendar(identifier: .gregorian)
    // Minutes from midnight, where 1380 = 11:00pm. Sun..Sat, ending on the capture date.
    let minutes: [Double] = [1_365, 1_392, 1_378, 1_401, 1_386, 1_512, 1_437]

    let points = minutes.enumerated().compactMap { index, value -> BedtimeDataPoint? in
      guard let date = calendar.date(byAdding: .day, value: index - 6, to: endDate) else { return nil }
      return BedtimeDataPoint(date: date, minutesFromMidnight: value)
    }

    return BedtimeChartData(dataPoints: points, trend: .trendingLater)
  }

  /// Seven nights averaging just over seven hours.
  var sleepDurationData: SleepDurationChartData {
    // Totals of the stage minutes above, in seconds.
    let nightly: [TimeInterval] = [25_620, 24_960, 25_620, 20_280, 25_560, 27_960, 25_140]
    return SleepDurationChartData(
      dailyValues: nightly,
      average: nightly.reduce(0, +) / Double(nightly.count)
    )
  }

  /// A week of nights broken into stages, each night different.
  ///
  /// Real sleep is uneven: deep sleep front-loads early in the week, one short night has almost
  /// none, and wake time varies. Identical bars every night look obviously generated.
  func sleepStages(endingAt endDate: Date) -> [SleepStageDataPoint] {
    let calendar = Calendar(identifier: .gregorian)

    // core, deep, rem, awake - minutes per night, oldest to most recent.
    let nights: [(core: Double, deep: Double, rem: Double, awake: Double)] = [
      (241, 78, 96, 12),
      (228, 71, 88, 19),
      (252, 64, 102, 9),
      (198, 42, 71, 27),
      (236, 69, 91, 14),
      (263, 82, 110, 11),
      (232, 68, 94, 15),
    ]

    return nights.enumerated().flatMap { index, night -> [SleepStageDataPoint] in
      guard let date = calendar.date(byAdding: .day, value: index - 6, to: endDate) else { return [] }

      return [
        SleepStageDataPoint(date: date, stage: .core, minutes: night.core),
        SleepStageDataPoint(date: date, stage: .deep, minutes: night.deep),
        SleepStageDataPoint(date: date, stage: .rem, minutes: night.rem),
        SleepStageDataPoint(date: date, stage: .awake, minutes: night.awake),
      ]
    }
  }

  var averageSleepScore: Double { 82 }

  /// Metric contributions behind the biological age.
  ///
  /// Confidence is derived from how much metric weight is covered - over 80% reads "High". Without
  /// these the result carries no weight at all and the badge shows "Low Confidence".
  var metricContributions: [MetricContribution] {
    let metrics: [(BiologicalAgeMetric, Double, Double, Double)] = [
      // metric, raw value, age delta, weight
      (.vo2Max, 47.2, -4.1, 0.20),
      (.restingHeartRate, 54, -2.3, 0.15),
      (.hrvTrend, 68, -1.6, 0.13),
      (.sleepScore, 82, -1.2, 0.12),
      (.activityLevel, 11_400, -0.9, 0.11),
      (.heartRateRecovery, 34, -1.4, 0.10),
      (.walkingSpeed, 1.42, -0.6, 0.08),
      (.zoneMinutes, 168, -0.5, 0.05),
      (.bedtimeConsistency, 22, 0.4, 0.03),
    ]

    return metrics.map { metric, rawValue, ageDelta, weight in
      MetricContribution(
        metric: metric,
        rawValue: rawValue,
        equivalentAge: chronologicalAge + ageDelta,
        ageDelta: ageDelta,
        weight: weight,
        weightedDelta: ageDelta * weight
      )
    }
  }

  // MARK: - Today

  var todaySummary: String {
    String(
      localized: "screenshot.today.summary",
      defaultValue: """
        You likely feel reasonably rested and slightly sharper today after a solid sleep score and a \
        measurable improvement in biological age.
        """,
      locale: locale,
      comment: "App Store screenshot: Bud's summary paragraph on the Today screen"
    )
  }

  var todaysAdvice: String {
    String(
      localized: "screenshot.today.advice",
      defaultValue: """
        Do one steady 30-minute Zone 2 session today, like a moderate bike ride or a brisk walk, to \
        make meaningful progress toward your weekly cardio target.
        """,
      locale: locale,
      comment: "App Store screenshot: the Today's Advice card content"
    )
  }

  /// The date shown above the greeting. Formatted in the target locale, not the machine's.
  func todayDate(_ date: Date) -> String {
    date.formatted(
      .dateTime
        .weekday(.wide)
        .month(.wide)
        .day()
        .year()
        .locale(locale)
    )
  }

  // MARK: - Nutrition

  struct FoodRow: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let calories: Double
  }

  struct Meal: Identifiable {
    let id = UUID()
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let items: [FoodRow]
  }

  var totalCalories: Double { 540 }
  var totalProtein: Double { 8 }
  var totalCarbs: Double { 116 }
  var totalFat: Double { 10 }

  /// Two logged meals. Brand names are real products, as they are in the current store screenshot,
  /// and the section totals are the sums of their rows.
  var meals: [Meal] {
    [
      Meal(
        name: String(
          localized: "screenshot.nutrition.breakfast",
          defaultValue: "Breakfast",
          locale: locale,
          comment: "App Store screenshot: meal section title"
        ),
        calories: 225, protein: 6, carbs: 55, fat: 1,
        items: [
          FoodRow(
            name: String(
              localized: "screenshot.nutrition.cereal",
              defaultValue: "Raisin Bran",
              locale: locale,
              comment: "App Store screenshot: a logged food item"
            ),
            detail: "Kellogg's • 55 g",
            calories: 225
          )
        ]
      ),
      Meal(
        name: String(
          localized: "screenshot.nutrition.lunch",
          defaultValue: "Lunch",
          locale: locale,
          comment: "App Store screenshot: meal section title"
        ),
        calories: 315, protein: 2, carbs: 61, fat: 9,
        items: [
          FoodRow(
            name: String(
              localized: "screenshot.nutrition.chips",
              defaultValue: "Rounds",
              locale: locale,
              comment: "App Store screenshot: a logged food item"
            ),
            detail: "Tostitos • 50 g",
            calories: 175
          )
        ]
      )
    ]
  }

  /// Past days complete, the captured day in progress, future days untouched.
  func dateState(for date: Date, capturedAt: Date) -> FoodLogDateState {
    let calendar = Calendar(identifier: .gregorian)

    if calendar.isDate(date, inSameDayAs: capturedAt) {
      return .inProgress(0.35)
    }

    return date < capturedAt ? .complete : .inProgress(0)
  }

  // MARK: - Workouts

  struct WorkoutPlanCard: Identifiable {
    let id = UUID()
    let title: String
    let duration: String
    /// Drives the overlapping icon cluster, as the real plan cell does.
    let workoutTypes: [HKWorkoutActivityType]
  }

  /// Training load ending "Steady", a few percent above baseline - like the store screenshot.
  ///
  /// Uses the same model the app does, rather than an average of my own: acute load is a 7-day
  /// EWMA, chronic load a 28-day EWMA, both `alpha = 2 / (decay + 1)` - see `calculateEWMA` in
  /// `HealthStoreFetcher`. That's what gives the line its shape. A workout spikes it and the days
  /// after decay smoothly toward zero, so rest days are visible as decay rather than as a drop to
  /// nothing. Averaging instead of decaying is what made earlier versions look wrong.
  ///
  /// Loads are per-day totals: big sessions on training days, zero on rest days. Eight weeks are
  /// generated and the last four drawn, so the EWMAs have already converged when the window starts.
  func trainingLoad(endingAt endDate: Date) -> TrainingLoadSummary {
    let calendar = Calendar(identifier: .gregorian)

    // Mon-Sun. Zeroes are rest days; the large values are long or hard sessions.
    let daily: [Double] = [
      0, 420, 0, 380, 0, 760, 0,            // steady
      0, 520, 0, 460, 0, 880, 240,          // building
      0, 0, 300, 0, 0, 420, 0,              // down week
      0, 560, 0, 500, 260, 920, 0,          // rebuild
      0, 0, 340, 0, 0, 0, 0,                // easy - the deep trough
      0, 640, 300, 580, 0, 1_050, 0,        // building back
      0, 880, 420, 760, 340, 1_350, 0,      // peak block
      0, 680, 0, 600, 280, 820, 0,          // easing off into the capture day
    ]

    let visibleDays = 28

    /// The app's EWMA: `alpha = 2 / (decay + 1)`, seeded with the first day and run over the whole
    /// history, so the decay between sessions is what shapes the curve.
    func ewma(decayDays: Int) -> [Double] {
      let alpha = 2.0 / Double(decayDays + 1)
      var value: Double?

      return daily.map { load in
        let next = value.map { alpha * load + (1 - alpha) * $0 } ?? load
        value = next
        return next
      }
    }

    /// Keeps only the days the chart shows, dated back from the capture date.
    func samples(_ values: [Double]) -> [DateValueSample] {
      let visible = values.suffix(visibleDays)

      return visible.enumerated().compactMap { index, value in
        guard let date = calendar.date(
          byAdding: .day,
          value: index - (visible.count - 1),
          to: endDate
        ) else {
          return nil
        }
        return DateValueSample(date: date, value: value)
      }
    }

    let acute = ewma(decayDays: 7)
    let chronic = ewma(decayDays: 28)
    let current = acute.last ?? 0
    let baseline = chronic.last ?? 1

    return TrainingLoadSummary(
      dateRange: DateRange.trailingDaysFromNow(visibleDays),
      currentSevenDayAverage: current,
      currentTwentyEightDayAverage: baseline,
      percentageDifference: ((current - baseline) / baseline) * 100,
      status: .steady,
      sevenDayTrend: samples(acute),
      twentyEightDayTrend: samples(chronic),
      dailyLoads: samples(daily)
    )
  }

  var workoutPlans: [WorkoutPlanCard] {
    [
      WorkoutPlanCard(
        title: String(
          localized: "screenshot.workouts.stretch",
          defaultValue: "15-Minute Pec and Shoulder Stretch Routine",
          locale: locale,
          comment: "App Store screenshot: a saved workout plan title"
        ),
        duration: String(
          localized: "screenshot.workouts.stretchDuration",
          defaultValue: "12 mins",
          locale: locale,
          comment: "App Store screenshot: workout plan duration"
        ),
        workoutTypes: [.flexibility, .functionalStrengthTraining, .preparationAndRecovery]
      ),
      WorkoutPlanCard(
        title: String(
          localized: "screenshot.workouts.mobility",
          defaultValue: "Mobility Routine",
          locale: locale,
          comment: "App Store screenshot: a saved workout plan title"
        ),
        duration: String(
          localized: "screenshot.workouts.mobilityDuration",
          defaultValue: "20 mins",
          locale: locale,
          comment: "App Store screenshot: workout plan duration"
        ),
        workoutTypes: [.yoga, .coreTraining, .flexibility]
      )
    ]
  }

  // MARK: - Habits

  /// Sixteen weeks of step-goal history.
  ///
  /// Hit rate is deliberately patchy - good streaks, weeks that fall apart - because a grid that is
  /// almost entirely filled reads as fake and undersells what the feature is for.
  var stepGrid: GoalGridModel {
    var generator = SeededGenerator(seed: 19)

    let weeks = (0..<16).map { index -> GoalGridModel.Week in
      // Later weeks trend better, as if the habit is sticking.
      let hitRate = 0.25 + (Double(index) / 16.0) * 0.45

      return GoalGridModel.Week(
        id: index,
        isComplete: (0..<7).map { _ in Double.random(in: 0...1, using: &generator) < hitRate },
        todayIndex: index == 15 ? 6 : nil
      )
    }

    return GoalGridModel(weeks: weeks)
  }

  var stepsToday: Int { 701 }
  var stepGoal: Int { 4_000 }
  var stepAverage: Int { 4_130 }

  /// A step count grouped for the target locale: "4,000" in English, "4.000" in German, "4 000" in
  /// French. Baking the grouped string into the fixture would ship a US separator to every market.
  func steps(_ count: Int) -> String {
    count.formatted(.number.locale(locale))
  }

  /// The worst and best weekday in the step grid.
  ///
  /// Derived from real dates rather than written out: "Saturday" has to read as "Samstag" and
  /// "zaterdag" too, and a literal never would.
  var worstStepDay: String { weekdayName(daysAfterSunday: 6) }
  var bestStepDay: String { weekdayName(daysAfterSunday: 2) }

  private func weekdayName(daysAfterSunday: Int) -> String {
    // February 1st 2026 was a Sunday, so the offset lands on the weekday we want.
    var components = DateComponents()
    components.year = 2026
    components.month = 2
    components.day = 1 + daysAfterSunday

    guard let date = Calendar(identifier: .gregorian).date(from: components) else { return "" }

    return date.formatted(.dateTime.weekday(.wide).locale(locale))
  }

  // MARK: - Chat

  var chatTitle: String {
    String(
      localized: "screenshot.chat.title",
      defaultValue: "VO₂ Max Guidance",
      locale: locale,
      comment: "App Store screenshot: the chat conversation's title"
    )
  }

  var chatUserMessage: String {
    String(
      localized: "screenshot.chat.question",
      defaultValue: "Yeah can you create an indoor cycling workout for this?",
      locale: locale,
      comment: "App Store screenshot: the person's message to Bud"
    )
  }

  var chatBudReply: String {
    String(
      localized: "screenshot.chat.reply",
      defaultValue: """
        Gotcha! Let's lock in a structured Norwegian 4x4 indoor cycling workout you can do on your \
        trainer. I'll build it so you can launch it in Bloom and crush those intervals:
        """,
      locale: locale,
      comment: "App Store screenshot: Bud's reply in the chat"
    )
  }

  var chatWorkoutTitle: String {
    String(
      localized: "screenshot.chat.workoutTitle",
      defaultValue: "Norwegian 4x4 Indoor Cycling",
      locale: locale,
      comment: "App Store screenshot: title of the workout Bud created"
    )
  }

  var chatWorkoutDetail: String {
    String(
      localized: "screenshot.chat.workoutDetail",
      defaultValue: "43 mins • Bike and Stationary Bike required",
      locale: locale,
      comment: "App Store screenshot: duration and equipment for the workout Bud created"
    )
  }

  var chatWorkoutDescription: String {
    String(
      localized: "screenshot.chat.workoutDescription",
      defaultValue: """
        A 45-min indoor bike session with 4x4-minute high-intensity intervals to boost VO₂ max.
        """,
      locale: locale,
      comment: "App Store screenshot: description of the workout Bud created"
    )
  }

  var chatWorkoutSaved: String {
    String(
      localized: "screenshot.chat.workoutSaved",
      defaultValue: "Workout Saved",
      locale: locale,
      comment: "App Store screenshot: state of the button on a saved workout"
    )
  }

  // MARK: - Monitor

  var monitorInsight: String {
    String(
      localized: "screenshot.monitor.insight",
      defaultValue: """
        Your recovery score is good today - your heart rate is in line with your usual resting \
        range, so your body appears to be bouncing back well after recent activity.
        """,
      locale: locale,
      comment: "App Store screenshot: Bud's Insight text on the recovery monitor screen"
    )
  }

  var monitorSuggestion: String {
    String(
      localized: "screenshot.monitor.suggestion",
      defaultValue: """
        Keep supporting recovery with easy movement, good hydration, and a consistent bedtime to \
        maintain this pattern.
        """,
      locale: locale,
      comment: "App Store screenshot: the follow-up suggestion under Bud's Insight"
    )
  }

  /// Thirty days of plausible-looking signal ranges, generated from a fixed seed so every locale
  /// and every re-capture draws exactly the same chart.
  func monitorRanges(endingAt endDate: Date, days: Int = 30) -> [DayZScoreRange] {
    let calendar = Calendar(identifier: .gregorian)
    var generator = SeededGenerator(seed: 42)

    return (0..<days).reversed().compactMap { offset in
      guard let date = calendar.date(byAdding: .day, value: -offset, to: endDate) else { return nil }

      let centre = Double.random(in: -0.9...0.9, using: &generator)
      let spread = Double.random(in: 0.35...1.4, using: &generator)

      return DayZScoreRange(date: date, minZScore: centre - spread, maxZScore: centre + spread)
    }
  }

  var restingHeartRate: MetricRangeData {
    MetricRangeData(
      metricType: MonitorMetricType.restingHeartRate.rawValue,
      displayName: MonitorMetricType.restingHeartRate.displayName,
      currentValue: 57,
      min7Day: 54,
      max7Day: 63,
      baseline28Day: 58,
      zScore: -0.4,
      min7DayZScore: -1.2,
      max7DayZScore: 1.1
    )
  }
}

/// Deterministic RNG, so screenshot charts are identical across locales and re-runs.
private struct SeededGenerator: RandomNumberGenerator {
  private var state: UInt64

  init(seed: UInt64) {
    self.state = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
  }

  mutating func next() -> UInt64 {
    state ^= state << 13
    state ^= state >> 7
    state ^= state << 17
    return state
  }
}
