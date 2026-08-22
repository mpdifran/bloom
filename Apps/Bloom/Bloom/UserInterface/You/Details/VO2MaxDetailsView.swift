//
//  VO2MaxDetailsView.swift
//  Bloom
//
//  Created by Claude on 2026-01-08.
//

import SwiftUI
import Charts
import TelemetryDeck
import HealthKit
import CoreHealth

struct VO2MaxDetailsView: View {

  @State private var selectedPeriod: StatTimePeriod = .oneMonth
  @State private var selectedFitnessLevelIndex: Int = 0
  @State private var vo2MaxSamples = [DateQuantitySample]()
  @State private var cardioFitnessLevel: HeartHealthMonthlySummary.CardioFitnessLevel?
  private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

  private let fitnessLevels: [HeartHealthMonthlySummary.CardioFitnessLevel] = [
    .low,
    .belowAverage,
    .aboveAverage,
    .high
  ]

  var body: some View {
    BloomScrollView(spacing: 20) {
      StatTimePeriodPicker(selectedPeriod: $selectedPeriod)

      if vo2MaxSamples.isNotEmpty {
        contentView
      } else {
        emptyView
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        VitalSummaryDetailTitleView(
          title: "VO₂ Max",
          subtitle: selectedPeriod.displayName
        )
      }
    }
    .navigationTitle("VO₂ Max")
    .navigationBarTitleDisplayMode(.inline)
    .animation(.default, value: selectedFitnessLevelIndex)
    .animation(.default, value: vo2MaxSamples.map(\.id))
    .task(id: selectedPeriod) {
      await loadData()
    }
    .task {
      let heartHealthSummary = await HealthStoreFetcher.shared.fetchHeartHealthSummary()
      let level = await heartHealthSummary.details.cardioFitnessLevel
      await MainActor.run {
        cardioFitnessLevel = level
        if let level, let index = fitnessLevels.firstIndex(of: level) {
          selectedFitnessLevelIndex = index
        }
      }
    }
    .onAppear {
      feedbackGenerator.prepare()
      TelemetryDeck.viewScreen("VO2 Max Details")
    }
  }
}

private extension VO2MaxDetailsView {

  @ViewBuilder
  var contentView: some View {
    vo2MaxChartSection
  }

  var emptyView: some View {
    ContentUnavailableView(
      "No Data Available",
      systemImage: "lungs.fill",
      description: Text("VO₂ Max is estimated during outdoor walks, runs, or hikes with your Apple Watch.")
    )
  }

  func loadData() async {
    let interval = selectedPeriod.aggregatesByWeek ? DateComponents(weekOfYear: 1) : DateComponents(day: 1)

    let samples = await HealthStoreFetcher.shared.fetchCollatedAverage(
      quantityType: .vo2Max,
      unit: .vo2Max(),
      interval: interval,
      dateRange: selectedPeriod.dateRange
    )
    await MainActor.run {
      self.vo2MaxSamples = samples
    }
  }

  // MARK: - VO2 Max Chart

  var vo2MaxChartSection: some View {
    VStack(alignment: .leading) {
      VStack {
        VitalDetailChartTitleView(
          title: "VO₂ Max",
          value: averageVO2MaxDisplayString
        )

        vo2MaxChart
          .frame(height: 250)

        fitnessLevelPicker
      }
      .cardContainer()

      DetailInfoCardView {
        Text(fitnessLevel.summary)
      }
      HealthCitationLinkView(
        url: .friendDatabase,
        title: "Fitness levels derived from the Fitness Registry and Importance of Exercise National Database (FRIEND)."
      )
      .padding(.horizontal)
    }
  }

  var vo2MaxChart: some View {
    Chart {
      // Selected fitness level (shaded band)
      if let ranges = selectedFitnessLevelRanges {
        RectangleMark(
          yStart: .value("Min", max(ranges.lower, chartMin)),
          yEnd: .value("Max", min(ranges.upper, chartMax))
        )
        .foregroundStyle(fitnessLevelFill)

        // Lower bound line - show for all except "low" (has no lower threshold)
        if selectedFitnessLevelIndex > 0 {
          RuleMark(y: .value("Min", ranges.lower))
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
            .foregroundStyle(fitnessLevel.color)
        }

        // Upper bound line - show for all except "high" (has no upper threshold)
        if selectedFitnessLevelIndex < fitnessLevels.count - 1 {
          RuleMark(y: .value("Max", ranges.upper))
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
            .foregroundStyle(fitnessLevel.color)
        }
      }

      // User's data line
      ForEach(vo2MaxSamples) { sample in
        LineMark(
          x: .value("Date", sample.date),
          y: .value("VO₂ Max", sample.quantity.doubleValue(for: .vo2Max()))
        )
        .foregroundStyle(userDataColor)
        .lineStyle(StrokeStyle(lineWidth: 3))
        .interpolationMethod(.catmullRom)
      }

      // Point marks
      ForEach(vo2MaxSamples) { sample in
        PointMark(
          x: .value("Date", sample.date),
          y: .value("VO₂ Max", sample.quantity.doubleValue(for: .vo2Max()))
        )
        .foregroundStyle(Color(.systemBackground))
        .symbolSize(60)
      }

      ForEach(vo2MaxSamples) { sample in
        PointMark(
          x: .value("Date", sample.date),
          y: .value("VO₂ Max", sample.quantity.doubleValue(for: .vo2Max()))
        )
        .foregroundStyle(userDataColor)
        .symbolSize(30)
      }
    }
    .chartYScale(domain: chartMin...chartMax)
    .chartXAxis {
      AxisMarks(values: .automatic) { value in
        AxisGridLine()
        AxisValueLabel(format: selectedPeriod.chartDateFormat)
      }
    }
    .chartYAxis {
      AxisMarks(position: .leading) { value in
        AxisGridLine()
        AxisValueLabel {
          if let vo2 = value.as(Double.self) {
            Text("\(vo2, specifier: "%.0f")")
          }
        }
      }
    }
  }

  var fitnessLevelPicker: some View {
    Button {
      selectedFitnessLevelIndex = (selectedFitnessLevelIndex + 1) % fitnessLevels.count
      feedbackGenerator.impactOccurred()
    } label: {
      HStack {
        Text("Fitness Level")

        Spacer()

        Text(fitnessLevel.name)
      }
    }
    .buttonStyle(.zone)
    .tint(fitnessLevel.color)
  }

  // MARK: - Computed Properties

  var fitnessLevel: HeartHealthMonthlySummary.CardioFitnessLevel {
    fitnessLevels[selectedFitnessLevelIndex]
  }

  var userDataColor: Color {
    cardioFitnessLevel?.color ?? .mutedPink
  }

  var averageVO2MaxDisplayString: String {
    guard vo2MaxSamples.isNotEmpty else { return "" }
    let average = vo2MaxSamples.map { $0.quantity.doubleValue(for: .vo2Max()) }.reduce(0, +) / Double(vo2MaxSamples.count)
    return average.formatted(.number.precision(.fractionLength(1)))
  }

  var selectedFitnessLevelRanges: (lower: Double, upper: Double)? {
    guard let goal = HealthGoalProvider.shared.goalVO2MaxForUser() else { return nil }

    // goal returns (excellent, good, fair) thresholds
    // e.g., for 30-39 male: (52.0, 43.0, 34.0)
    // low: 0 to fair
    // belowAverage: fair to good
    // aboveAverage: good to excellent
    // high: excellent to max

    switch selectedFitnessLevelIndex {
    case 0: // low
      return (0, goal.2)
    case 1: // belowAverage
      return (goal.2, goal.1)
    case 2: // aboveAverage
      return (goal.1, goal.0)
    case 3: // high
      return (goal.0, max((maxVO2Max ?? 0) * 1.1, 60))
    default:
      return nil
    }
  }

  var fitnessLevelFill: some ShapeStyle {
    let color = fitnessLevel.color

    switch selectedFitnessLevelIndex {
    case 0: // low - gradient fades down (no lower bound)
      return AnyShapeStyle(
        LinearGradient(
          colors: [color.opacity(0.3), color.opacity(0.05)],
          startPoint: .top,
          endPoint: .bottom
        )
      )
    case 3: // high - gradient fades up (no upper bound)
      return AnyShapeStyle(
        LinearGradient(
          colors: [color.opacity(0.3), color.opacity(0.05)],
          startPoint: .bottom,
          endPoint: .top
        )
      )
    default: // middle ranges - solid fill
      return AnyShapeStyle(color.opacity(0.3))
    }
  }

  var maxVO2Max: Double? {
    vo2MaxSamples.map { $0.quantity.doubleValue(for: .vo2Max()) }.max()
  }

  var minVO2Max: Double? {
    vo2MaxSamples.map { $0.quantity.doubleValue(for: .vo2Max()) }.min()
  }

  var chartMin: Double {
    let rangeMin = selectedFitnessLevelRanges?.lower

    if let min = [rangeMin, minVO2Max].compactMap({ $0 }).min() {
      return min * 0.9
    }
    return 20
  }

  var chartMax: Double {
    let rangeMax = selectedFitnessLevelRanges?.upper

    if let max = [rangeMax, maxVO2Max].compactMap({ $0 }).max() {
      return max * 1.1
    }
    return 50
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      VO2MaxDetailsView()
    }
  }
}
