//
//  MenstruationDetailView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-12.
//

import SFSafeSymbols
import SwiftUI
import HealthKit
import TelemetryDeck
import CoreHealth
import BloomFoundation
import Charts

struct MenstruationDetailView: View {

  @State private var selectedPeriod: StatTimePeriod = .sixMonths
  @State private var menstrualCycles: [MenstrualCycle] = []
  @State private var activeEnergySamples: [DateQuantitySample] = []
  @State private var basalEnergySamples: [DateQuantitySample] = []
  @State private var selectedPhase: MenstrualCyclePhase?
  @State private var presentedSheet: AnyView?

  private let viewModel = VitalsViewModel.shared

  var hasData: Bool {
    menstrualCycles.isNotEmpty || viewModel.menstrualSummary != nil
  }

  var body: some View {
    BloomScrollView(spacing: 20) {
      calendarSection

      if hasData {
        StatTimePeriodPicker(selectedPeriod: $selectedPeriod)
        cycleLengthChart
        periodDurationChart
        phaseActivitySection
        statisticsSection
        currentStatusSection
        detailsSection
      } else {
        emptyView
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        VitalSummaryDetailTitleView(
          title: "Cycle Tracking",
          subtitle: selectedPeriod.displayName
        )
      }
    }
    .navigationTitle("Cycle Tracking")
    .navigationBarTitleDisplayMode(.inline)
    .navigationDestination(item: $selectedPhase) { phase in
      CyclePhaseLearnMoreView(phase: phase)
    }
    .sheet($presentedSheet)
    .animation(.default, value: selectedPeriod)
    .task(id: selectedPeriod) {
      async let cyclesTask = HealthStoreFetcher.shared.fetchMenstrualFlowSamples(
        dateRange: selectedPeriod.dateRange
      )
      async let activeTask = HealthStoreFetcher.shared.fetchCollatedQuantity(
        for: .activeEnergyBurned,
        unit: .largeCalorie(),
        options: [.cumulativeSum],
        dateRange: selectedPeriod.dateRange
      )
      async let basalTask = HealthStoreFetcher.shared.fetchCollatedQuantity(
        for: .basalEnergyBurned,
        unit: .largeCalorie(),
        options: [.cumulativeSum],
        dateRange: selectedPeriod.dateRange
      )

      let (cycles, active, basal) = await (cyclesTask, activeTask, basalTask)
      await MainActor.run {
        self.menstrualCycles = cycles
        self.activeEnergySamples = active
        self.basalEnergySamples = basal
      }
    }
    .onAppear {
      TelemetryDeck.viewScreen("Cycle Tracking Vital Details")
    }
  }
}

private extension MenstruationDetailView {

  // MARK: - Computed Properties

  /// Cycle durations (days between consecutive cycle starts)
  var cycleDurations: [(date: Date, days: Int)] {
    guard menstrualCycles.count >= 2 else { return [] }

    var durations: [(date: Date, days: Int)] = []
    let sortedCycles = menstrualCycles.sorted { $0.startDate < $1.startDate }

    for i in 0..<(sortedCycles.count - 1) {
      let current = sortedCycles[i]
      let next = sortedCycles[i + 1]
      if let days = Calendar.current.dateComponents([.day], from: current.startDate, to: next.startDate).day {
        durations.append((date: current.startDate, days: days))
      }
    }
    return durations
  }

  /// Period durations (days of menstruation per cycle)
  var periodDurations: [(date: Date, days: Int)] {
    menstrualCycles
      .sorted { $0.startDate < $1.startDate }
      .compactMap { cycle in
        guard let days = cycle.menstruationDurationDays else { return nil }
        return (date: cycle.startDate, days: days)
      }
  }

  var averageCycleLength: Int? {
    guard cycleDurations.isNotEmpty else { return nil }
    let average = cycleDurations.map { Double($0.days) }.average(keyPath: \.self)
    return Int(average)
  }

  var averagePeriodLength: Int? {
    guard periodDurations.isNotEmpty else { return nil }
    let average = periodDurations.map { Double($0.days) }.average(keyPath: \.self)
    return Int(average)
  }

  var shortestCycle: Int? {
    cycleDurations.map(\.days).min()
  }

  var longestCycle: Int? {
    cycleDurations.map(\.days).max()
  }

  /// Calculate phase date ranges from cycles
  var phaseDateRanges: (follicular: [Date], luteal: [Date]) {
    guard menstrualCycles.count >= 2 else { return ([], []) }

    var follicularDates: [Date] = []
    var lutealDates: [Date] = []
    let calendar = Calendar.current
    let sortedCycles = menstrualCycles.sorted { $0.startDate < $1.startDate }

    for i in 0..<(sortedCycles.count - 1) {
      let current = sortedCycles[i]
      let next = sortedCycles[i + 1]

      guard let cycleDuration = calendar.dateComponents([.day], from: current.startDate, to: next.startDate).day,
            cycleDuration >= 21 && cycleDuration <= 45 else { continue }

      let menstruationDays = current.menstruationDurationDays ?? 5
      let ovulationDay = cycleDuration / 2

      // Follicular: after menstruation ends until 2 days before ovulation
      let follicularStart = calendar.date(byAdding: .day, value: menstruationDays, to: current.startDate) ?? current.startDate
      let follicularEnd = calendar.date(byAdding: .day, value: ovulationDay - 2, to: current.startDate) ?? current.startDate

      // Luteal: 2 days after ovulation until next cycle
      let lutealStart = calendar.date(byAdding: .day, value: ovulationDay + 2, to: current.startDate) ?? current.startDate
      let lutealEnd = next.startDate

      // Add all dates in follicular range
      var date = follicularStart
      while date < follicularEnd {
        follicularDates.append(calendar.startOfDay(for: date))
        date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
      }

      // Add all dates in luteal range
      date = lutealStart
      while date < lutealEnd {
        lutealDates.append(calendar.startOfDay(for: date))
        date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
      }
    }

    return (follicularDates, lutealDates)
  }

  /// Activity level for follicular phase
  var follicularActivityLevel: Double? {
    calculateActivityLevel(forDates: phaseDateRanges.follicular)
  }

  /// Activity level for luteal phase
  var lutealActivityLevel: Double? {
    calculateActivityLevel(forDates: phaseDateRanges.luteal)
  }

  func calculateActivityLevel(forDates dates: [Date]) -> Double? {
    guard dates.isNotEmpty else { return nil }

    let calendar = Calendar.current

    // Group samples by day
    let activeByDay = Dictionary(grouping: activeEnergySamples) { sample in
      calendar.startOfDay(for: sample.date)
    }
    let basalByDay = Dictionary(grouping: basalEnergySamples) { sample in
      calendar.startOfDay(for: sample.date)
    }

    // Calculate ratio for each target date
    var ratios: [Double] = []
    for date in dates {
      let dayStart = calendar.startOfDay(for: date)
      let activeTotal = activeByDay[dayStart]?.reduce(0) { $0 + $1.quantity.doubleValue(for: .largeCalorie()) } ?? 0
      let basalTotal = basalByDay[dayStart]?.reduce(0) { $0 + $1.quantity.doubleValue(for: .largeCalorie()) } ?? 0

      if basalTotal > 0 {
        ratios.append(activeTotal / basalTotal)
      }
    }

    guard ratios.isNotEmpty else { return nil }
    return ratios.average(keyPath: \.self)
  }

  // MARK: - Views

  var emptyView: some View {
    ContentUnavailableView {
      Label("No Data Available", systemSymbol: .circleDottedAndCircle)
    } description: {
      Text("Track your period in Apple Health to learn more about your cycle.")
    } actions: {
      Link(destination: .cycleTrackingWithAppleWatch) {
        Text("Learn More")
      }
      .buttonStyle(.primary)
      .tint(.mutedPink)
    }
  }

  @ViewBuilder
  var cycleLengthChart: some View {
    if cycleDurations.count >= 2 {
      VStack(alignment: .leading) {
        VitalDetailChartTitleView(
          title: "Cycle Length",
          value: averageCycleLength.map { "\($0) days" } ?? "—"
        )

        Chart {
          // Typical range band (21-35 days)
          RectangleMark(
            yStart: .value("Min", 21),
            yEnd: .value("Max", 35)
          )
          .foregroundStyle(.mutedPink.opacity(0.1))

          // Cycle lengths as points connected by line
          ForEach(cycleDurations, id: \.date) { item in
            LineMark(
              x: .value("Date", item.date),
              y: .value("Days", item.days)
            )
            .foregroundStyle(.mutedPink)

            PointMark(
              x: .value("Date", item.date),
              y: .value("Days", item.days)
            )
            .foregroundStyle(.mutedPink)
          }
        }
        .chartXAxis {
          AxisMarks(values: .automatic) { _ in
            AxisGridLine()
            AxisValueLabel(format: selectedPeriod.chartDateFormat)
          }
        }
        .chartYAxis {
          AxisMarks(position: .trailing) { value in
            AxisGridLine()
            if let days = value.as(Int.self) {
              AxisValueLabel {
                Text("\(days)d")
                  .font(.caption2)
              }
            }
          }
        }
        .frame(height: 200)
      }
      .cardContainer()
    }
  }

  @ViewBuilder
  var periodDurationChart: some View {
    if periodDurations.isNotEmpty {
      VStack(alignment: .leading) {
        VitalDetailChartTitleView(
          title: "Period Length",
          value: averagePeriodLength.map { "\($0) days" } ?? "—"
        )

        Chart {
          // Typical range band (3-7 days)
          RectangleMark(
            yStart: .value("Min", 3),
            yEnd: .value("Max", 7)
          )
          .foregroundStyle(.mutedPink.opacity(0.1))

          // Period lengths as points connected by line
          ForEach(periodDurations, id: \.date) { item in
            LineMark(
              x: .value("Date", item.date),
              y: .value("Days", item.days)
            )
            .foregroundStyle(.mutedPink)

            PointMark(
              x: .value("Date", item.date),
              y: .value("Days", item.days)
            )
            .foregroundStyle(.mutedPink)
          }
        }
        .chartXAxis {
          AxisMarks(values: .automatic) { _ in
            AxisGridLine()
            AxisValueLabel(format: selectedPeriod.chartDateFormat)
          }
        }
        .chartYAxis {
          AxisMarks(position: .trailing) { value in
            AxisGridLine()
            if let days = value.as(Int.self) {
              AxisValueLabel {
                Text("\(days)d")
                  .font(.caption2)
              }
            }
          }
        }
        .frame(height: 200)
      }
      .cardContainer()
    }
  }

  @ViewBuilder
  var phaseActivitySection: some View {
    if let follicular = follicularActivityLevel, let luteal = lutealActivityLevel {
      VStack(alignment: .leading, spacing: 16) {
        VitalDetailChartTitleView(title: "Activity by Phase", value: "")

        HStack(spacing: 0) {
          Spacer()

          // Follicular bar
          VStack(spacing: 8) {
            Text("Follicular")
              .font(.subheadline)
              .foregroundStyle(.secondary)

            GeometryReader { geometry in
              let maxHeight = geometry.size.height
              let barHeight = min(follicular * maxHeight * 2, maxHeight)

              VStack {
                Spacer()
                RoundedRectangle(cornerRadius: 8)
                  .fill(.mutedPurple)
                  .frame(width: 60, height: barHeight)
              }
            }

            Text("\(Int(follicular * 100))%")
              .font(.headline)
              .foregroundStyle(.mutedPurple)
          }
          .frame(width: 80)

          Spacer()

          // Luteal bar
          VStack(spacing: 8) {
            Text("Luteal")
              .font(.subheadline)
              .foregroundStyle(.secondary)

            GeometryReader { geometry in
              let maxHeight = geometry.size.height
              let barHeight = min(luteal * maxHeight * 2, maxHeight)

              VStack {
                Spacer()
                RoundedRectangle(cornerRadius: 8)
                  .fill(.mutedIndigo)
                  .frame(width: 60, height: barHeight)
              }
            }

            Text("\(Int(luteal * 100))%")
              .font(.headline)
              .foregroundStyle(.mutedIndigo)
          }
          .frame(width: 80)

          Spacer()
        }
        .frame(height: 160)

        // Show difference
        if luteal > 0 {
          let diff = ((follicular - luteal) / luteal) * 100
          Text("Follicular phase is \(Int(abs(diff)))% \(diff > 0 ? "more" : "less") active than luteal")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .cardContainer()
    }
  }

  var statisticsSection: some View {
    VStack {
      LabeledContent("Average Cycle") {
        Text(averageCycleLength.map { "\($0) days" } ?? "—")
          .foregroundStyle(.mutedPink)
          .bold()
      }

      Divider()

      LabeledContent("Average Period") {
        Text(averagePeriodLength.map { "\($0) days" } ?? "—")
          .foregroundStyle(.mutedPink)
          .bold()
      }

      if let shortest = shortestCycle, let longest = longestCycle {
        Divider()

        LabeledContent("Cycle Range") {
          Text("\(shortest)–\(longest) days")
            .foregroundStyle(.mutedPink)
            .bold()
        }
      }

      Divider()

      LabeledContent("Total Cycles") {
        Text("\(menstrualCycles.count)")
          .foregroundStyle(.mutedPink)
          .bold()
      }
    }
    .cardContainer()
  }

  @ViewBuilder
  var calendarSection: some View {
    if let summary = viewModel.menstrualSummary {
      VStack(spacing: 20) {
        MenstruationCalendarView(menstruationSummary: summary) { date in
          presentedSheet = CycleTrackingActionCardView(date: date).asAny
        }

        MenstruationCalendarLegendView()
      }
    }
  }

  @ViewBuilder
  var currentStatusSection: some View {
    if let summary = viewModel.menstrualSummary {
      VStack {
        LabeledContent("Next Period") {
          Group {
            if let predictionDate = summary.nextPredictedPeriodDate {
              VStack(alignment: .trailing) {
                Text("\(predictionDate, formatter: DateFormatter.monthAndDay)")
                Text("\(DateFormatter.relativeTimeIntervalDaysFullFromNow(predictionDate))")
                  .font(.caption)
              }
            } else {
              Text("Unsure")
            }
          }
          .foregroundStyle(.mutedPink)
          .font(.title2)
          .bold()
          .fontDesign(.rounded)
        }

        Divider()

        LabeledContent("Current Phase") {
          Group {
            if let phaseDescription = summary.phaseName {
              Text(phaseDescription)
                .foregroundStyle(summary.color ?? .mutedPink)
            } else {
              Text("Unknown")
            }
          }
          .font(.title2)
          .bold()
          .fontDesign(.rounded)
        }
      }
      .cardContainer()
    }
  }

  @ViewBuilder
  var detailsSection: some View {
    if
      let summary = viewModel.menstrualSummary,
      let phase = summary.currentPhase(),
      let details = phase.details
    {
      DetailInfoCardView {
        Text(details)

        if phase.coolFacts.isNotEmpty {
          Button("Learn More") {
            selectedPhase = phase
          }
          .frame(height: 44)
        }
      }
      .tint(.mutedPink)
    }
  }
}

#Preview {
  NavigationStack {
    MenstruationDetailView()
  }
}
