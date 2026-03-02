//
//  CelebrationCardView.swift
//  Bloom
//
//  Created by Claude on 2026-02-26.
//

import SwiftUI
import Charts
import CoreHealth
import DataContainer
import BloomFoundation
import BloomUI
@preconcurrency import HealthKit

struct CelebrationCardView: View {
  let kind: CelebrationKind
  var chartData: CelebrationChartData?

  var body: some View {
    VStack(spacing: 0) {
      cardContent
        .background {
          Rectangle()
            .fill(.background)
        }

      // Watermark
      HStack(spacing: 4) {
        Image(ThemeController.shared.theme.appIcon)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 20, height: 20)
          .clipShape(RoundedRectangle(cornerRadius: 4))
        Text("Bloom Health")
          .bold()
          .font(.caption)
          .fontDesign(.rounded)
          .foregroundStyle(.white)
      }
      .padding(.vertical, 8)
    }
    .background(.black)
  }
}

// MARK: - Chart Data

enum CelebrationChartData {
  case bioAge([BiologicalAgeRecordDTO])
  case goalStreak(habit: HabitDTO?, gridModel: GoalGridModel?)
  case zoneMinutes([ZoneMinutesDataPoint])
  case sleep([AppleSleepSegment])
}

// MARK: - Card Content

private extension CelebrationCardView {

  var cardContent: some View {
    VStack(spacing: 0) {
      // Bud character — full-width hero, matching modal
      Image(kind.budImage)
        .resizable()
        .scaledToFill()
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .clipped()

      VStack(spacing: 16) {
        HStack(spacing: 6) {
          Image(systemName: "laurel.leading")
          Text(Date().formatted(.dateTime.month(.abbreviated).day().year()))
          Image(systemName: "laurel.trailing")
        }
        .font(.subheadline)
        .fontWeight(.bold)
        .fontDesign(.rounded)
        .foregroundStyle(.secondary)

        // Headline
        Text(kind.title)
          .font(.title)
          .bold()
          .fontDesign(.rounded)
          .multilineTextAlignment(.center)

        Text(kind.shareSubtitle(name: HealthManager.shared.name))
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)

        chartView
          .padding(.top, 8)
      }
      .padding(24)
    }
  }
}

// MARK: - Charts

private extension CelebrationCardView {

  @ViewBuilder
  var chartView: some View {
    switch kind {
    case .biologicalAge(let yearsYounger):
      let ages = bioAgeValues(yearsYounger: yearsYounger)
      BloomUI.BiologicalAgeMeter(
        chronologicalAge: ages.chronological,
        biologicalAge: ages.biological
      )
      .frame(height: 180)
    case .goalStreak(let metricName, let days):
      if case .goalStreak(let habit, let gridModel) = chartData {
        GoalStreakChartCard(metricName: metricName, days: days, habit: habit, gridModel: gridModel)
          .padding(.vertical)
      } else {
        GoalStreakChartCard(metricName: metricName, days: days)
          .padding(.vertical)
      }
    case .zoneMinutes:
      if case .zoneMinutes(let data) = chartData {
        ZoneMinutesChartCard(zoneData: data)
          .frame(height: 180)
      } else {
        ZoneMinutesChartCard()
          .frame(height: 180)
      }
    case .perfectSleep(let sleepAnalysis):
      if case .sleep(let segments) = chartData {
        AppleSleepStageChartView(sleepAnalysis: sleepAnalysis, segments: segments)
          .frame(height: 180)
      } else {
        AppleSleepStageChartView(sleepAnalysis: sleepAnalysis)
          .frame(height: 180)
      }
    }
  }

  func bioAgeValues(yearsYounger: Int) -> (chronological: Double, biological: Double) {
    if case .bioAge(let records) = chartData, let latest = records.last {
      return (latest.actualAge, latest.biologicalAge)
    }
    let chronological = Double(HealthManager.shared.age())
    return (chronological, chronological - Double(yearsYounger))
  }
}

// MARK: - Goal Streak Grid

struct GoalStreakChartCard: View {
  let metricName: String
  let days: Int

  @State private var habit: HabitDTO?
  @State private var gridModel: GoalGridModel?

  private var useWeeklyGrid: Bool { days >= 30 }

  init(metricName: String, days: Int, habit: HabitDTO? = nil, gridModel: GoalGridModel? = nil) {
    self.metricName = metricName
    self.days = days
    self._habit = State(initialValue: habit)
    self._gridModel = State(initialValue: gridModel)
  }

  var body: some View {
    Group {
      if useWeeklyGrid, let gridModel {
        GoalGrid(model: gridModel)
      } else {
        HStack(spacing: 4) {
          ForEach(0..<days, id: \.self) { index in
            GoalGridCell(
              id: "\(index)",
              isComplete: true,
              isToday: false,
              cornerRadius: 12
            )
            .frame(maxHeight: 40)
          }
        }
      }
    }
    .tint(habit?.targetMetric.color ?? .accentColor)
    .task {
      guard self.habit == nil else { return }
      await loadData()
    }
  }

  private func loadData() async {
    let calendar = Calendar.current
    let endDate = calendar.startOfDay(for: Date())
    guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else { return }

    let modelActor = HabitModelActor.standard()
    if let activeHabits = try? await modelActor.fetchActiveHabits() {
      habit = activeHabits.first(where: { $0.targetMetric.name == metricName })
    }

    if useWeeklyGrid {
      gridModel = Self.buildGridModel(days: days)
    }
  }

  static func buildGridModel(days: Int) -> GoalGridModel {
    let calendar = Calendar.current
    let endDate = calendar.startOfDay(for: Date())
    guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
      return GoalGridModel(weeks: [])
    }
    return buildGridModel(startDate: startDate, endDate: endDate, calendar: calendar)
  }

  private static func buildGridModel(
    startDate: Date,
    endDate: Date,
    calendar: Calendar
  ) -> GoalGridModel {
    // Build ordered list of days
    var allDays = [Date]()
    var current = startDate
    while current <= endDate {
      allDays.append(current)
      current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
    }

    // Group days by calendar week
    var weekBuckets = [[Date]]()
    var currentWeek = [Date]()
    var currentWeekOfYear: Int?

    for day in allDays {
      let weekOfYear = calendar.component(.weekOfYear, from: day)
      if weekOfYear != currentWeekOfYear {
        if currentWeek.isNotEmpty {
          weekBuckets.append(currentWeek)
        }
        currentWeek = [day]
        currentWeekOfYear = weekOfYear
      } else {
        currentWeek.append(day)
      }
    }
    if currentWeek.isNotEmpty {
      weekBuckets.append(currentWeek)
    }

    let today = calendar.startOfDay(for: Date())

    let weeks = weekBuckets.enumerated().map { index, weekDays in
      var isComplete = [Bool]()
      var todayIndex: Int?

      for day in weekDays {
        let weekdayIndex = (calendar.component(.weekday, from: day) - calendar.firstWeekday + 7) % 7
        while isComplete.count < weekdayIndex {
          isComplete.append(true)
        }
        isComplete.append(true)
        if day == today {
          todayIndex = weekdayIndex
        }
      }

      return GoalGridModel.Week(id: index, isComplete: isComplete, todayIndex: todayIndex)
    }

    return GoalGridModel(weeks: weeks)
  }
}

// MARK: - Zone Minutes Chart

struct ZoneMinutesChartCard: View {
  @State private var zoneData: [ZoneMinutesDataPoint]

  init(zoneData: [ZoneMinutesDataPoint] = []) {
    self._zoneData = State(initialValue: zoneData)
  }

  var body: some View {
    Chart {
      ForEach(zoneData) { point in
        BarMark(x: .value("Date", point.date, unit: .day), y: .value("Minutes", point.zone1))
          .foregroundStyle(Color.heartRateZone1)
        BarMark(x: .value("Date", point.date, unit: .day), y: .value("Minutes", point.zone2))
          .foregroundStyle(Color.heartRateZone2)
        BarMark(x: .value("Date", point.date, unit: .day), y: .value("Minutes", point.zone3))
          .foregroundStyle(Color.heartRateZone3)
        BarMark(x: .value("Date", point.date, unit: .day), y: .value("Minutes", point.zone4))
          .foregroundStyle(Color.heartRateZone4)
        BarMark(x: .value("Date", point.date, unit: .day), y: .value("Minutes", point.zone5))
          .foregroundStyle(Color.heartRateZone5)
      }
    }
    .chartLegend(.hidden)
    .chartXAxis {
      AxisMarks(values: .automatic) { _ in
        AxisGridLine()
        AxisValueLabel()
      }
    }
    .chartYAxis {
      AxisMarks(position: .leading) { value in
        AxisGridLine()
        AxisValueLabel {
          if let minutes = value.as(Double.self) {
            Text("\(Int(minutes))m")
          }
        }
      }
    }
    .task {
      guard zoneData.isEmpty else { return }
      zoneData = await Self.fetchZoneMinutesData()
    }
  }

  static func fetchZoneMinutesData() async -> [ZoneMinutesDataPoint] {
    let calendar = Calendar.current
    let dateRange = DateRange.trailingDaysFromEndOfYesterday(6)

    let allDays = buildAllDays(calendar: calendar, dateRange: dateRange)

    guard let heartRateZones = await HealthStoreFetcher.shared.heartRateZones() else {
      return allDays.map { ZoneMinutesDataPoint(date: $0, zone1: 0, zone2: 0, zone3: 0, zone4: 0, zone5: 0) }
    }

    let details = await HealthStoreFetcher.shared.fetchExerciseEffectivenessDetails(
      heartRateZones: heartRateZones,
      dateRange: dateRange
    )

    var dailyData = [Date: (z1: Double, z2: Double, z3: Double, z4: Double, z5: Double)]()

    for report in details.workoutReports {
      let day = calendar.startOfDay(for: report.workout.startDate)
      let dist = report.heartZoneDistribution
      let existing = dailyData[day] ?? (0, 0, 0, 0, 0)
      dailyData[day] = (
        existing.z1 + dist.zone1.doubleValue(for: .minute()) * .zone12Multiplier,
        existing.z2 + dist.zone2.doubleValue(for: .minute()) * .zone12Multiplier,
        existing.z3 + dist.zone3.doubleValue(for: .minute()) * .zone34Multiplier,
        existing.z4 + dist.zone4.doubleValue(for: .minute()) * .zone34Multiplier,
        existing.z5 + dist.zone5.doubleValue(for: .minute()) * .zone5Multiplier
      )
    }

    return allDays.map { day in
      let data = dailyData[day] ?? (0, 0, 0, 0, 0)
      return ZoneMinutesDataPoint(
        date: day,
        zone1: data.z1,
        zone2: data.z2,
        zone3: data.z3,
        zone4: data.z4,
        zone5: data.z5
      )
    }
  }

  private static func buildAllDays(calendar: Calendar, dateRange: DateRange) -> [Date] {
    var allDays = [Date]()
    var currentDay = calendar.startOfDay(for: dateRange.start)
    let endDay = calendar.startOfDay(for: dateRange.end)
    while currentDay <= endDay {
      allDays.append(currentDay)
      currentDay = calendar.date(byAdding: .day, value: 1, to: currentDay) ?? currentDay
    }
    return allDays
  }
}

// MARK: - Preview

#Preview("Bio Age") {
  PreviewEnvironment {
    CelebrationCardView(
      kind: .biologicalAge(yearsYounger: 3)
    )
  }
}

#Preview("Goal Streak") {
  PreviewEnvironment {
    CelebrationCardView(
      kind: .goalStreak(metricName: "Steps", days: 7)
    )
  }
}

#Preview("Zone Minutes") {
  PreviewEnvironment {
    CelebrationCardView(
      kind: .zoneMinutes(minutes: 150)
    )
  }
}

#Preview("Perfect Sleep") {
  PreviewEnvironment {
    CelebrationCardView(
      kind: .perfectSleep(SleepAnalysis.previewData[0])
    )
  }
}
