//
//  HabitDetailsViewModel.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-06.
//

import SwiftUI
import HealthKit
import DataContainer
import CoreHealth
import BloomFoundation

struct GoalRange: Identifiable, Sendable, Hashable {
  var id: Int { hashValue }

  let startDate: Date
  let endDate: Date
  let minGoal: Double
  let maxGoal: Double
}

extension HabitDetailsView {
  @MainActor @Observable
  final class ViewModel {
    var habit: Habit {
      didSet { Task { await calculateGoalRanges() } }
    }
    var todayValue: HKQuantity
    var currentPeriodValue: HKQuantity
    var dailySamples = [DateQuantitySample]()
    var averageValue: HKQuantity?
    var dayStats = [Calendar.Weekday: Double]()
    var habitGridModel = HabitGridModel()
    var habitGridWeekModel = HabitGridWeekModel()
    var habitGridMonthModel = HabitGridMonthModel()
    var habitGridYearModel = HabitGridYearModel()
    var allSamplesTwelveWeeks = [DateQuantitySample]()
    var weekQuantitySamples = [WeekQuantitySamples]() {
      didSet { 
        Task { 
          if habit.timePeriod == .weekly {
            await loadHabitGridWeekModel()
          } else if habit.timePeriod == .monthly {
            await loadHabitGridMonthModel()
          } else if habit.timePeriod == .daily {
            await loadHabitGridModel()
          }
        }
      }
    }
    var yearlyQuantitySamples: [(year: Int, total: HKQuantity, referenceDate: Date)] = [] {
      didSet { 
        Task { 
          await loadHabitGridYearModel()
        }
      }
    }
    var goalRanges = [GoalRange]()
    var habitHistory = [HabitDTO]()

    init(habit: Habit) {
      self.habit = habit
      self.todayValue = HKQuantity(unit: habit.unit, doubleValue: 0)
      self.currentPeriodValue = HKQuantity(unit: habit.unit, doubleValue: 0)

      observeChanges()
      Task {
        await calculateGoalRanges()
      }
    }

    private let modelActor = HabitModelActor.standard()

    private var hasLoadedTodayAtLeastOnce = false
    private var observationHandler: HKObserverQueryHandle?

    var timePeriod: GoalTimePeriod {
      habit.timePeriod
    }
  }
}

private extension HabitDetailsView.ViewModel {

  func observeChanges() {
    observationHandler = HealthManager.shared.healthStore.observeChanges(
      sampleTypes: habit.targetMetric.sampleTypes,
      startDate: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
    ) { [weak self] in
      guard await self?.hasLoadedTodayAtLeastOnce == true else { return }

      let timePeriod = await self?.timePeriod ?? .daily

      await self?.loadCurrentPeriodValue(timePeriod: timePeriod)
      await self?.loadGoalHistory(timePeriod: timePeriod)
    }
  }
}

extension HabitDetailsView.ViewModel {

  func sampleMeetsGoal(_ sample: DateQuantitySample) -> Bool {
    let oldestHabit = habitHistory.min(by: { $0.startDate < $1.startDate })
    let matchingHabit = habitHistory.first(where: { $0.isDateWithinHabit(date: sample.date) })

    guard let habit = matchingHabit ?? oldestHabit else { return false }

    return habit.quantityMeetsGoal(sample.quantity)
  }

  func habitUnit() -> HKUnit {
    habit.unit
  }

  func targetMetric() -> TargetMetric {
    habit.targetMetric
  }
  
  nonisolated func loadCurrentPeriodValue(timePeriod: GoalTimePeriod) async {
    let targetMetric = await targetMetric()
    
    let dateRange: DateRange
    switch timePeriod {
    case .daily:
      dateRange = .today()
    case .weekly:
      dateRange = .startOfWeekToNow()
    case .monthly:
      dateRange = .startOfMonthToNow()
    case .yearly:
      dateRange = .currentYear()
    @unknown default:
      return
    }
    
    let quantity = await targetMetric.fetchTotalQuantity(for: dateRange)
    
    await MainActor.run {
      self.currentPeriodValue = quantity
      self.hasLoadedTodayAtLeastOnce = true
    }
  }

  nonisolated func loadGoalHistory(timePeriod: GoalTimePeriod) async {
    let targetMetric = await targetMetric()
    let unit = await habitUnit()

    if timePeriod == .yearly {
      // For yearly habits, fetch individual year totals
      var yearlySamples: [(year: Int, total: HKQuantity, referenceDate: Date)] = []
      let currentYear = Calendar.current.component(.year, from: .now)
      
      for yearOffset in 0..<5 {
        let yearRange = DateRange.specificYear(yearOffset)
        let total = await targetMetric.fetchTotalQuantity(for: yearRange)
        let year = currentYear - yearOffset
        yearlySamples.append((year: year, total: total, referenceDate: yearRange.start))
      }

      let constantYearlySamples = yearlySamples
      await MainActor.run {
        self.yearlyQuantitySamples = constantYearlySamples
      }
    }

    let twelveWeeksSamples = await targetMetric.fetchCollatedDailyQuantity(
      unit: unit,
      dateRange: .trailingWeeksFromEndOfToday(12)
    )
    let samples = await targetMetric.fetchCollatedDailyQuantity(
      unit: unit,
      dateRange: .trailingWeeksFromEndOfToday(30)
    )

    let currentWeekOfYear = Calendar.current.weekOfYear(for: .now) ?? 52
    let groupedByWeekSamples = samples.grouped { sample in
      guard let weekOfYear = Calendar.current.weekOfYear(for: sample.date) else { return -1 }

      // The week IDs always need to be 0 on the right and a positive incrementing number to the left for the animation to work correctly.
      if currentWeekOfYear < weekOfYear {
        return currentWeekOfYear - weekOfYear + 52
      }
      return currentWeekOfYear - weekOfYear
    }

    let weekSamples = groupedByWeekSamples.compactMap { (key, samples) -> WeekQuantitySamples? in
      guard
        let sample = samples.first,
        key >= 0,
        let referenceDate = Calendar.current.startOfWeek(for: sample.date)
      else { return nil }

      return WeekQuantitySamples(
        id: key,
        referenceDate: referenceDate,
        samples: samples
      )
    }.sorted(keyPath: \.referenceDate)

    var statsIntermediate = [Calendar.Weekday: [Double]]()
    for sample in twelveWeeksSamples {
      guard let weekday = Calendar.current.weekday(for: sample.date) else { continue }

      statsIntermediate[weekday, default: []].append(sample.quantity.doubleValue(for: unit))
    }
    var stats = [Calendar.Weekday: Double]()
    for weekday in statsIntermediate.keys {
      stats[weekday] = statsIntermediate[weekday]?.average(keyPath: \.self) ?? 0
    }
    let statsConstant = stats

    let averageValue = twelveWeeksSamples.map({ $0.quantity.doubleValue(for: unit) }).average(keyPath: \.self)
    let averageQuantity = HKQuantity(unit: unit, doubleValue: averageValue)

    await MainActor.run {
      self.allSamplesTwelveWeeks = twelveWeeksSamples
      self.weekQuantitySamples = weekSamples
      self.dayStats = statsConstant
      self.dailySamples = samples.suffix(30)
      self.averageValue = averageQuantity
    }
  }

  nonisolated func loadHabitGridModel() async {
    let targetMetric = await targetMetric()

    let habitHistory: [HabitDTO]
    do {
      habitHistory = try await modelActor.fetchHabits(for: targetMetric)
    } catch {
      print(error)
      return
    }

    let oldestHabit = habitHistory.first

    var weeks = await weekQuantitySamples.map { weekSamples in
      let todayIndex = weekSamples.samples.firstIndex(where: { Calendar.current.isDateInToday($0.date) })

      let isCompleteArray = weekSamples.samples.map { sample in
        let referenceHabit: HabitDTO
        if let habit = habitHistory.first(where: { $0.isDateWithinHabit(date: sample.date) }) {
          referenceHabit = habit
        } else if let oldestHabit, sample.date < oldestHabit.startDate {
          referenceHabit = oldestHabit
        } else {
          return false
        }
        return referenceHabit.quantityMeetsGoal(sample.quantity)
      }

      return HabitGridModel.Week(
        id: weekSamples.id,
        isComplete: isCompleteArray,
        todayIndex: todayIndex
      )
    }

    if weeks.count < 30 {
      var earliestId = weeks.first?.id ?? 0

      let remainingAdditions = 30 - weeks.count

      for _ in 0 ..< remainingAdditions {
        earliestId -= 1
        let week = HabitGridModel.Week(id: earliestId, isComplete: Array(repeating: false, count: 7))
        weeks.insert(week, at: 0)
      }
    }

    let model = HabitGridModel(weeks: weeks)

    await MainActor.run {
      self.habitGridModel = model
      self.habitHistory = habitHistory
    }
  }
  
  nonisolated func loadHabitGridWeekModel() async {
    let targetMetric = await targetMetric()
    let unit = await habitUnit()
    
    let habitHistory: [HabitDTO]
    do {
      habitHistory = try await modelActor.fetchHabits(for: targetMetric)
    } catch {
      print(error)
      return
    }
    
    let oldestHabit = habitHistory.first
    let calendar = Calendar.current
    
    var weeks = await weekQuantitySamples.map { weekSamples in
      // Check if this is the current week
      let isCurrentWeek = weekSamples.samples.contains { calendar.isDateInToday($0.date) }
      
      // Calculate total for the week
      let weekTotal = weekSamples.samples.reduce(0) { total, sample in
        total + sample.quantity.doubleValue(for: unit)
      }
      let weekQuantity = HKQuantity(unit: unit, doubleValue: weekTotal)
      
      // Find the matching habit for this week and check if goal was met
      let referenceHabit: HabitDTO?
      if let habit = habitHistory.first(where: { $0.isDateWithinHabit(date: weekSamples.referenceDate) }) {
        referenceHabit = habit
      } else if let oldestHabit, weekSamples.referenceDate < oldestHabit.startDate {
        referenceHabit = oldestHabit
      } else {
        referenceHabit = nil
      }
      
      let isComplete = referenceHabit?.quantityMeetsGoal(weekQuantity) ?? false
      
      // Check if this week contains the 1st of a month
      var monthLabel: String? = nil
      let weekDays = (0..<7).compactMap { dayOffset in
        calendar.date(byAdding: .day, value: dayOffset, to: weekSamples.referenceDate)
      }
      
      for day in weekDays {
        if calendar.component(.day, from: day) == 1 {
          let formatter = DateFormatter()
          formatter.dateFormat = "MMM"
          monthLabel = formatter.string(from: day)
          break
        }
      }
      
      return HabitGridWeekModel.Week(
        id: weekSamples.id,
        isComplete: isComplete,
        isCurrentWeek: isCurrentWeek,
        referenceDate: weekSamples.referenceDate,
        monthLabel: monthLabel
      )
    }
    
    if weeks.count < 20 {
      var earliestId = weeks.first?.id ?? 0
      let remainingAdditions = 20 - weeks.count
      
      for _ in 0 ..< remainingAdditions {
        earliestId -= 1
        let week = HabitGridWeekModel.Week(
          id: earliestId,
          isComplete: nil,
          referenceDate: .distantPast
        )
        weeks.insert(week, at: 0)
      }
    }
    
    let model = HabitGridWeekModel(weeks: weeks)
    
    await MainActor.run {
      self.habitGridWeekModel = model
      self.habitHistory = habitHistory
    }
  }
  
  nonisolated func loadHabitGridMonthModel() async {
    let targetMetric = await targetMetric()
    let unit = await habitUnit()
    
    let habitHistory: [HabitDTO]
    do {
      habitHistory = try await modelActor.fetchHabits(for: targetMetric)
    } catch {
      print(error)
      return
    }
    
    let oldestHabit = habitHistory.first
    let calendar = Calendar.current
    
    // Group daily samples by month
    let allSamples = await weekQuantitySamples.flatMap { $0.samples }
    let monthlyGroupedSamples = Dictionary(grouping: allSamples) { sample in
      calendar.dateInterval(of: .month, for: sample.date)?.start ?? sample.date
    }
    
    // Create month samples with IDs
    let currentMonth = calendar.dateInterval(of: .month, for: .now)?.start ?? .now
    var monthSamples: [(id: Int, referenceDate: Date, samples: [DateQuantitySample])] = []
    
    for (monthStart, samples) in monthlyGroupedSamples.sorted(by: { $0.key < $1.key }) {
      let monthsFromCurrent = calendar.dateComponents([.month], from: monthStart, to: currentMonth).month ?? 0
      let id = monthsFromCurrent
      monthSamples.append((id: id, referenceDate: monthStart, samples: samples))
    }
    
    var months = monthSamples.map { monthSample in
      // Check if this is the current month
      let isCurrentMonth = calendar.isDate(monthSample.referenceDate, equalTo: .now, toGranularity: .month)
      
      // Calculate total for the month
      let monthTotal = monthSample.samples.reduce(0) { total, sample in
        total + sample.quantity.doubleValue(for: unit)
      }
      let monthQuantity = HKQuantity(unit: unit, doubleValue: monthTotal)
      
      // Find the matching habit for this month and check if goal was met
      let referenceHabit: HabitDTO?
      if let habit = habitHistory.first(where: { $0.isDateWithinHabit(date: monthSample.referenceDate) }) {
        referenceHabit = habit
      } else if let oldestHabit, monthSample.referenceDate < oldestHabit.startDate {
        referenceHabit = oldestHabit
      } else {
        referenceHabit = nil
      }
      
      let isComplete = referenceHabit?.quantityMeetsGoal(monthQuantity) ?? false
      
      // Generate month label
      let formatter = DateFormatter()
      formatter.dateFormat = "MMM"
      let monthLabel = formatter.string(from: monthSample.referenceDate)
      
      return HabitGridMonthModel.Month(
        id: monthSample.id,
        isComplete: isComplete,
        isCurrentMonth: isCurrentMonth,
        referenceDate: monthSample.referenceDate,
        monthLabel: monthLabel
      )
    }
    
    // Sort months by ID (newest on right, which means lowest/negative ID)
    months.sort { $0.id > $1.id }
    
    // Add empty months if needed to reach 12 total
    if months.count < 12 {
      var earliestId = months.first?.id ?? 0
      let remainingAdditions = 12 - months.count
      
      for _ in 0 ..< remainingAdditions {
        earliestId -= 1
        let month = HabitGridMonthModel.Month(
          id: earliestId,
          isComplete: nil,
          referenceDate: .distantPast,
          monthLabel: ""
        )
        months.insert(month, at: 0)
      }
    }
    
    let model = HabitGridMonthModel(months: months)
    
    await MainActor.run {
      self.habitGridMonthModel = model
      self.habitHistory = habitHistory
    }
  }
  
  nonisolated func loadHabitGridYearModel() async {
    let targetMetric = await targetMetric()
    
    let habitHistory: [HabitDTO]
    do {
      habitHistory = try await modelActor.fetchHabits(for: targetMetric)
    } catch {
      print(error)
      return
    }
    
    let oldestHabit = habitHistory.first
    let calendar = Calendar.current
    let currentYear = calendar.component(.year, from: .now)
    let yearlySamples = await yearlyQuantitySamples
    
    var years = yearlySamples.map { yearSample in
      // Check if this is the current year
      let isCurrentYear = yearSample.year == currentYear
      
      // Find the matching habit for this year and check if goal was met
      let referenceHabit: HabitDTO?
      
      // First try to find active habits (no end date) that started in or before this year
      let activeHabits = habitHistory.filter { habit in
        let habitStartYear = calendar.component(.year, from: habit.startDate)
        return habit.endDate == nil && habitStartYear <= yearSample.year
      }
      
      if let latestActiveHabit = activeHabits.max(by: { $0.startDate < $1.startDate }) {
        referenceHabit = latestActiveHabit
      } else {
        // No active habits, find habits that started in the matching year
        let yearHabits = habitHistory.filter { habit in
          let habitStartYear = calendar.component(.year, from: habit.startDate)
          return habitStartYear == yearSample.year
        }
        
        if let latestYearHabit = yearHabits.max(by: { $0.startDate < $1.startDate }) {
          referenceHabit = latestYearHabit
        } else if let oldestHabit, yearSample.referenceDate < oldestHabit.startDate {
          referenceHabit = oldestHabit
        } else {
          referenceHabit = nil
        }
      }
      
      let isComplete = referenceHabit?.quantityMeetsGoal(yearSample.total) ?? false
      
      // Generate year label
      let yearLabel = String(yearSample.year)
      
      // Calculate ID based on years from current year (newer years have lower IDs)
      let id = currentYear - yearSample.year
      
      return HabitGridYearModel.Year(
        id: id,
        isComplete: isComplete,
        isCurrentYear: isCurrentYear,
        referenceDate: yearSample.referenceDate,
        yearLabel: yearLabel
      )
    }
    
    // Sort years by ID (newest on right, which means lowest ID)
    years.sort { $0.id > $1.id }
    
    // Add empty years if needed to reach 5 total
    if years.count < 5 {
      var earliestId = years.first?.id ?? 0
      let remainingAdditions = 5 - years.count
      
      for _ in 0 ..< remainingAdditions {
        earliestId -= 1
        let year = HabitGridYearModel.Year(
          id: earliestId,
          isComplete: nil,
          referenceDate: .distantPast,
          yearLabel: ""
        )
        years.insert(year, at: 0)
      }
    }
    
    let model = HabitGridYearModel(years: years)
    
    await MainActor.run {
      self.habitGridYearModel = model
      self.habitHistory = habitHistory
    }
  }
}

private extension HabitDetailsView.ViewModel {

  nonisolated func calculateGoalRanges() async {
    let targetMetric = await targetMetric()

    do {
      let habits = try await modelActor.fetchHabits(for: targetMetric)

      var previousDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
      var ranges = [GoalRange]()

      for habit in habits {
        let minGoal: Double
        let maxGoal: Double
        switch targetMetric.measurementStyle {
        case .minimum:
          minGoal = await habit.quantity.localizedValue(for: habit.unit)
          maxGoal = minGoal * 3
        case .range:
          minGoal = await habit.rangeMinGoal.localizedValue(for: habit.unit)
          maxGoal = await habit.rangeMaxGoal.localizedValue(for: habit.unit)
        @unknown default:
          print("ERROR: Unknown measurementStyle")
          continue
        }

        let endDate = habit.endDate ?? .now
        guard previousDate < endDate else { continue }

        let goalRange = GoalRange(
          startDate: previousDate,
          endDate: endDate,
          minGoal: minGoal,
          maxGoal: maxGoal
        )
        ranges.append(goalRange)
        previousDate = endDate
      }

      let rangesConstant = ranges

      await MainActor.run {
        self.goalRanges = rangesConstant
      }
    } catch {
      print(error)
    }
  }
}
