//
//  MobilityDetailsView.swift
//  Bloom
//
//  Created by Claude on 2026-01-08.
//

import SwiftUI
import Charts
import TelemetryDeck
import CoreHealth
import HealthKit

struct MobilityDetailsView: View {

  @State private var selectedPeriod: StatTimePeriod = .sevenDays
  @State private var stepsChartData: StepsComparisonChartData?
  @State private var walkingSpeedData: [SpeedDataPoint]?
  @State private var stairClimbSpeedData: [SpeedDataPoint]?
  @State private var selectedWalkingSpeedAgeIndex = 0
  @State private var selectedStairClimbSpeedAgeIndex = 0

  private let healthGoalProvider = HealthGoalProvider.shared

  var body: some View {
    BloomScrollView(spacing: 20) {
      StatTimePeriodPicker(selectedPeriod: $selectedPeriod, includeOneDay: true)

      if hasData {
        contentView
      } else {
        emptyView
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        VitalSummaryDetailTitleView(
          title: "Mobility",
          subtitle: selectedPeriod.displayName
        )
      }
    }
    .navigationTitle("Mobility")
    .navigationBarTitleDisplayMode(.inline)
    .animation(.default, value: stepsChartData?.currentPeriodDataPoints.map(\.id))
    .animation(.default, value: walkingSpeedData?.map(\.id))
    .animation(.default, value: stairClimbSpeedData?.map(\.id))
    .animation(.default, value: selectedWalkingSpeedAgeIndex)
    .animation(.default, value: selectedStairClimbSpeedAgeIndex)
    .task(id: selectedPeriod) {
      await loadData()
    }
    .onAppear {
      TelemetryDeck.viewScreen("Mobility Details")
    }
  }
}

private extension MobilityDetailsView {

  var hasData: Bool {
    stepsChartData != nil || walkingSpeedData != nil || stairClimbSpeedData != nil
  }

  func loadData() async {
    async let steps = YouStatsCalculator.shared.calculateStepsComparisonChartData(for: selectedPeriod)
    async let walkingSpeed = YouStatsCalculator.shared.calculateWalkingSpeedForPeriod(selectedPeriod)
    async let stairSpeed = YouStatsCalculator.shared.calculateStairClimbSpeedForPeriod(selectedPeriod)

    stepsChartData = await steps
    walkingSpeedData = await walkingSpeed
    stairClimbSpeedData = await stairSpeed
  }

  @ViewBuilder
  var contentView: some View {
    stepsChartSection
    walkingSpeedChartSection
    stairClimbSpeedChartSection
  }

  var emptyView: some View {
    ContentUnavailableView(
      "No Data Available",
      systemImage: "figure.walk",
      description: Text("Track your mobility by carrying your iPhone throughout the day or wearing your Apple Watch.")
    )
  }

  // MARK: - Steps Chart

  @ViewBuilder
  var stepsChartSection: some View {
    if let stepsChartData, stepsChartData.currentPeriodDataPoints.isNotEmpty {
      VStack(alignment: .leading) {
        VStack {
          VitalDetailChartTitleView(
            title: "Steps",
            valueLabel: String(localized: "TOTAL", comment: "Chart total label"),
            value: stepsChartData.totalStepsCurrent.formatted()
          )

          stepsChart
            .frame(height: 250)

          if let percentChange = stepsChartData.percentageChange {
            HStack {
              Spacer()
              Text(formattedPercentChange(percentChange))
                .font(.caption)
                .bold()
                .fontDesign(.rounded)
                .foregroundStyle(.secondary)
            }
          }
        }
        .cardContainer()

        DetailInfoCardView {
          Text("Steps are compared to the previous period of the same length. The faded line represents the previous period.")
        }
      }
    }
  }

  var stepsChart: some View {
    Chart {
      // Previous period line (faded)
      ForEach(stepsChartData?.previousPeriodDataPoints ?? []) { dataPoint in
        LineMark(
          x: .value("Time", dataPoint.index),
          y: .value("Steps", dataPoint.cumulativeSteps),
          series: .value("Period", dataPoint.series)
        )
        .foregroundStyle(Color.mutedYellow.opacity(0.3))
        .lineStyle(StrokeStyle(lineWidth: 3))
        .interpolationMethod(.catmullRom)
      }

      // Current period line (solid)
      ForEach(stepsChartData?.currentPeriodDataPoints ?? []) { dataPoint in
        LineMark(
          x: .value("Time", dataPoint.index),
          y: .value("Steps", dataPoint.cumulativeSteps),
          series: .value("Period", dataPoint.series)
        )
        .foregroundStyle(Color.mutedYellow)
        .lineStyle(StrokeStyle(lineWidth: 3))
        .interpolationMethod(.catmullRom)
      }

      // Current point mark with border and dashed line to y-axis
      if let currentPoint = stepsChartData?.currentPeriodDataPoints.last {
        RuleMark(
          xStart: .value("Start", currentPoint.index),
          xEnd: .value("End", (stepsChartData?.expectedDataPointCount ?? 7) - 1),
          y: .value("Steps", currentPoint.cumulativeSteps)
        )
        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
        .foregroundStyle(Color.secondary.opacity(0.5))

        PointMark(
          x: .value("Time", currentPoint.index),
          y: .value("Steps", currentPoint.cumulativeSteps)
        )
        .foregroundStyle(Color(.systemBackground))
        .symbolSize(100)

        PointMark(
          x: .value("Time", currentPoint.index),
          y: .value("Steps", currentPoint.cumulativeSteps)
        )
        .foregroundStyle(Color.mutedYellow)
        .symbolSize(40)
      }
    }
    .chartXScale(domain: 0...(stepsChartData?.expectedDataPointCount ?? 7) - 1)
    .chartXAxis(.hidden)
    .chartYAxis {
      AxisMarks(position: .trailing, values: stepsYAxisValues) { value in
        AxisValueLabel {
          if let steps = value.as(Int.self) {
            Text(steps.compactFormatted)
          }
        }
      }
    }
    .chartLegend(.hidden)
  }

  func formattedPercentChange(_ change: Double) -> String {
    let sign = change >= 0 ? "+" : ""
    return "\(sign)\(Int(change))% \(selectedPeriod.comparisonPeriodLabel)"
  }

  var stepsYAxisValues: [Int] {
    guard let data = stepsChartData,
          let currentSteps = data.currentPeriodDataPoints.last?.cumulativeSteps,
          let previousSteps = data.previousPeriodDataPoints.last?.cumulativeSteps else {
      return []
    }

    // Check if values are too close (within 15% of the larger value)
    let maxValue = max(currentSteps, previousSteps)
    let difference = abs(currentSteps - previousSteps)
    let tooClose = Double(difference) / Double(maxValue) < 0.15

    if tooClose {
      return [currentSteps]
    } else {
      return [currentSteps, previousSteps]
    }
  }

  // MARK: - Walking Speed Chart

  @ViewBuilder
  var walkingSpeedChartSection: some View {
    if let walkingSpeedData, walkingSpeedData.isNotEmpty {
      VStack(alignment: .leading) {
        VStack {
          VitalDetailChartTitleView(
            title: "Walking Speed",
            value: formattedSpeed(averageWalkingSpeed)
          )

          walkingSpeedChart
            .frame(height: 250)

          walkingSpeedAgePicker
        }
        .cardContainer()

        DetailInfoCardView {
          Text("Walking speed is a key indicator of mobility and overall health. Reference lines show typical speeds for different ages.")
        }
        HealthCitationLinkView(
          url: .walkingSpeed,
          title: "Based on Walkability Index for Elderly Health research."
        )
        .padding(.horizontal)
      }
      .animation(.default, value: selectedWalkingSpeedAgeIndex)
    }
  }

  var walkingSpeedAgePicker: some View {
    let isFirst = selectedWalkingSpeedAgeIndex == 0
    let isLast = selectedWalkingSpeedAgeIndex == walkingSpeedAgeRanges.count - 1
    let range = selectedWalkingSpeedRange

    return Button {
      selectedWalkingSpeedAgeIndex = (selectedWalkingSpeedAgeIndex + 1) % walkingSpeedAgeRanges.count
    } label: {
      HStack {
        Text("Age Range")

        Spacer()

        Text(ageRangeLabel(lowerAge: range.lowerAge, upperAge: range.upperAge, isFirst: isFirst, isLast: isLast))
      }
    }
    .buttonStyle(.zone)
    .tint(colorForAge(range.upperAge))
    .sensoryFeedback(.selection, trigger: selectedWalkingSpeedAgeIndex)
  }

  var selectedWalkingSpeedRange: (lowerAge: Int, upperAge: Int, minSpeed: Double, maxSpeed: Double) {
    walkingSpeedAgeRanges[selectedWalkingSpeedAgeIndex]
  }

  var walkingSpeedChart: some View {
    let yDomain = walkingSpeedYDomain
    let selectedRange = selectedWalkingSpeedRange
    let isFirstRange = selectedWalkingSpeedAgeIndex == 0
    let isLastRange = selectedWalkingSpeedAgeIndex == walkingSpeedAgeRanges.count - 1

    return Chart {
      // Selected age range (shaded band)
      RectangleMark(
        yStart: .value("Min", max(selectedRange.minSpeed, yDomain.lowerBound)),
        yEnd: .value("Max", min(selectedRange.maxSpeed, yDomain.upperBound))
      )
      .foregroundStyle(walkingSpeedRangeFill(for: selectedRange, isFirstRange: isFirstRange, isLastRange: isLastRange))

      // Lower bound line - only show if NOT the last (oldest) range
      if !isLastRange {
        RuleMark(y: .value("Min", selectedRange.minSpeed))
          .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
          .foregroundStyle(colorForAge(selectedRange.upperAge))
      }

      // Upper bound line - only show if NOT the first (youngest) range
      if !isFirstRange {
        RuleMark(y: .value("Max", selectedRange.maxSpeed))
          .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
          .foregroundStyle(colorForAge(selectedRange.upperAge))
      }

      // User's data line
      ForEach(walkingSpeedData ?? []) { dataPoint in
        LineMark(
          x: .value("Date", dataPoint.date),
          y: .value("Speed", dataPoint.value)
        )
        .foregroundStyle(Color.mutedYellow)
        .lineStyle(StrokeStyle(lineWidth: 3))
        .interpolationMethod(.catmullRom)
      }

      // Point marks
      ForEach(walkingSpeedData ?? []) { dataPoint in
        PointMark(
          x: .value("Date", dataPoint.date),
          y: .value("Speed", dataPoint.value)
        )
        .foregroundStyle(Color(.systemBackground))
        .symbolSize(60)
      }

      ForEach(walkingSpeedData ?? []) { dataPoint in
        PointMark(
          x: .value("Date", dataPoint.date),
          y: .value("Speed", dataPoint.value)
        )
        .foregroundStyle(Color.mutedYellow)
        .symbolSize(30)
      }
    }
    .chartYScale(domain: yDomain)
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
          if let speed = value.as(Double.self) {
            Text("\(speed, specifier: "%.1f")")
          }
        }
      }
    }
  }

  var averageWalkingSpeed: Double {
    guard let data = walkingSpeedData, data.isNotEmpty else { return 0 }
    return data.map(\.value).reduce(0, +) / Double(data.count)
  }

  var walkingSpeedYDomain: ClosedRange<Double> {
    let selectedRange = selectedWalkingSpeedRange

    guard let data = walkingSpeedData,
          let dataMinSpeed = data.map(\.value).min(),
          let dataMaxSpeed = data.map(\.value).max() else {
      // No user data - show domain based on selected age range
      return (selectedRange.minSpeed - 0.1)...(selectedRange.maxSpeed + 0.1)
    }

    // Combine user data bounds with selected age range bounds
    let minSpeed = min(dataMinSpeed, selectedRange.minSpeed)
    let maxSpeed = max(dataMaxSpeed, selectedRange.maxSpeed)

    let padding = max((maxSpeed - minSpeed) * 0.1, 0.1)
    return (minSpeed - padding)...(maxSpeed + padding)
  }

  var walkingSpeedAgeRanges: [(lowerAge: Int, upperAge: Int, minSpeed: Double, maxSpeed: Double)] {
    let unit = HKUnit.meter().unitDivided(by: .second())
    let quantities = healthGoalProvider.walkingSpeedAgeQuantities()
    var ranges: [(lowerAge: Int, upperAge: Int, minSpeed: Double, maxSpeed: Double)] = []

    for i in 0..<(quantities.count - 1) {
      let current = quantities[i]
      let next = quantities[i + 1]
      ranges.append((
        lowerAge: Int(current.age),
        upperAge: Int(next.age),
        minSpeed: next.quantity.doubleValue(for: unit),
        maxSpeed: current.quantity.doubleValue(for: unit)
      ))
    }

    return ranges
  }

  var walkingSpeedReferenceLines: [(age: Int, speed: Double)] {
    let unit = HKUnit.meter().unitDivided(by: .second())
    return healthGoalProvider.walkingSpeedAgeQuantities()
      .dropFirst()
      .map { (age: Int($0.age), speed: $0.quantity.doubleValue(for: unit)) }
  }

  // MARK: - Stair Climb Speed Chart

  @ViewBuilder
  var stairClimbSpeedChartSection: some View {
    if let stairClimbSpeedData, stairClimbSpeedData.isNotEmpty {
      VStack(alignment: .leading) {
        VStack {
          VitalDetailChartTitleView(
            title: "Stair Climb Speed",
            value: formattedSpeed(averageStairClimbSpeed)
          )

          stairClimbSpeedChart
            .frame(height: 250)

          stairClimbSpeedAgePicker
        }
        .cardContainer()

        DetailInfoCardView {
          Text("Stair climb speed measures how quickly you ascend stairs and is an important indicator of lower body strength and cardiovascular fitness.")
        }
        HealthCitationLinkView(
          url: .stairClimbSpeed,
          title: "Based on Functional Predictors of Stair-Climbing Speed research."
        )
        .padding(.horizontal)
      }
      .animation(.default, value: selectedStairClimbSpeedAgeIndex)
    }
  }

  var stairClimbSpeedAgePicker: some View {
    let isFirst = selectedStairClimbSpeedAgeIndex == 0
    let isLast = selectedStairClimbSpeedAgeIndex == stairClimbSpeedAgeRanges.count - 1
    let range = selectedStairClimbSpeedRange

    return Button {
      selectedStairClimbSpeedAgeIndex = (selectedStairClimbSpeedAgeIndex + 1) % stairClimbSpeedAgeRanges.count
    } label: {
      HStack {
        Text("Age Range")

        Spacer()

        Text(ageRangeLabel(lowerAge: range.lowerAge, upperAge: range.upperAge, isFirst: isFirst, isLast: isLast))
      }
    }
    .buttonStyle(.zone)
    .tint(colorForAge(range.upperAge))
    .sensoryFeedback(.selection, trigger: selectedStairClimbSpeedAgeIndex)
  }

  var selectedStairClimbSpeedRange: (lowerAge: Int, upperAge: Int, minSpeed: Double, maxSpeed: Double) {
    stairClimbSpeedAgeRanges[selectedStairClimbSpeedAgeIndex]
  }

  var stairClimbSpeedChart: some View {
    let yDomain = stairClimbSpeedYDomain
    let selectedRange = selectedStairClimbSpeedRange
    let isFirstRange = selectedStairClimbSpeedAgeIndex == 0
    let isLastRange = selectedStairClimbSpeedAgeIndex == stairClimbSpeedAgeRanges.count - 1

    return Chart {
      // Selected age range (shaded band)
      RectangleMark(
        yStart: .value("Min", max(selectedRange.minSpeed, yDomain.lowerBound)),
        yEnd: .value("Max", min(selectedRange.maxSpeed, yDomain.upperBound))
      )
      .foregroundStyle(stairClimbSpeedRangeFill(for: selectedRange, isFirstRange: isFirstRange, isLastRange: isLastRange))

      // Lower bound line - only show if NOT the last (oldest) range
      if !isLastRange {
        RuleMark(y: .value("Min", selectedRange.minSpeed))
          .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
          .foregroundStyle(colorForAge(selectedRange.upperAge))
      }

      // Upper bound line - only show if NOT the first (youngest) range
      if !isFirstRange {
        RuleMark(y: .value("Max", selectedRange.maxSpeed))
          .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
          .foregroundStyle(colorForAge(selectedRange.upperAge))
      }

      // User's data line
      ForEach(stairClimbSpeedData ?? []) { dataPoint in
        LineMark(
          x: .value("Date", dataPoint.date),
          y: .value("Speed", dataPoint.value)
        )
        .foregroundStyle(Color.mutedOrange)
        .lineStyle(StrokeStyle(lineWidth: 3))
        .interpolationMethod(.catmullRom)
      }

      // Point marks
      ForEach(stairClimbSpeedData ?? []) { dataPoint in
        PointMark(
          x: .value("Date", dataPoint.date),
          y: .value("Speed", dataPoint.value)
        )
        .foregroundStyle(Color(.systemBackground))
        .symbolSize(60)
      }

      ForEach(stairClimbSpeedData ?? []) { dataPoint in
        PointMark(
          x: .value("Date", dataPoint.date),
          y: .value("Speed", dataPoint.value)
        )
        .foregroundStyle(Color.mutedOrange)
        .symbolSize(30)
      }
    }
    .chartYScale(domain: yDomain)
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
          if let speed = value.as(Double.self) {
            Text("\(speed, specifier: "%.1f")")
          }
        }
      }
    }
  }

  var averageStairClimbSpeed: Double {
    guard let data = stairClimbSpeedData, data.isNotEmpty else { return 0 }
    return data.map(\.value).reduce(0, +) / Double(data.count)
  }

  var stairClimbSpeedYDomain: ClosedRange<Double> {
    let selectedRange = selectedStairClimbSpeedRange

    guard let data = stairClimbSpeedData,
          let dataMinSpeed = data.map(\.value).min(),
          let dataMaxSpeed = data.map(\.value).max() else {
      // No user data - show domain based on selected age range
      return (selectedRange.minSpeed - 0.1)...(selectedRange.maxSpeed + 0.1)
    }

    // Combine user data bounds with selected age range bounds
    let minSpeed = min(dataMinSpeed, selectedRange.minSpeed)
    let maxSpeed = max(dataMaxSpeed, selectedRange.maxSpeed)

    let padding = max((maxSpeed - minSpeed) * 0.1, 0.1)
    return (minSpeed - padding)...(maxSpeed + padding)
  }

  var stairClimbSpeedAgeRanges: [(lowerAge: Int, upperAge: Int, minSpeed: Double, maxSpeed: Double)] {
    let unit = HKUnit.meter().unitDivided(by: .second())
    let quantities = healthGoalProvider.stairClimbSpeedAgeQuantities()
    var ranges: [(lowerAge: Int, upperAge: Int, minSpeed: Double, maxSpeed: Double)] = []

    for i in 0..<(quantities.count - 1) {
      let current = quantities[i]
      let next = quantities[i + 1]
      ranges.append((
        lowerAge: Int(current.age),
        upperAge: Int(next.age),
        minSpeed: next.quantity.doubleValue(for: unit),
        maxSpeed: current.quantity.doubleValue(for: unit)
      ))
    }

    return ranges
  }

  var stairClimbSpeedReferenceLines: [(age: Int, speed: Double)] {
    let unit = HKUnit.meter().unitDivided(by: .second())
    return healthGoalProvider.stairClimbSpeedAgeQuantities()
      .dropFirst()
      .map { (age: Int($0.age), speed: $0.quantity.doubleValue(for: unit)) }
  }

  // MARK: - Helpers

  func formattedSpeed(_ speed: Double) -> String {
    "\(speed.formatted(.number.precision(.fractionLength(2)))) m/s"
  }

  func ageRangeLabel(lowerAge: Int, upperAge: Int, isFirst: Bool, isLast: Bool) -> String {
    if isFirst {
      return String(localized: "< Age \(upperAge)", comment: "Age range label for the youngest bracket. The placeholder is an age in years.")
    } else if isLast {
      return String(localized: "> Age \(lowerAge)", comment: "Age range label for the oldest bracket. The placeholder is an age in years.")
    } else {
      return String(localized: "Ages \(lowerAge)-\(upperAge)", comment: "Age range label. The placeholders are the youngest and oldest age in the bracket.")
    }
  }

  func walkingSpeedRangeFill(
    for range: (lowerAge: Int, upperAge: Int, minSpeed: Double, maxSpeed: Double),
    isFirstRange: Bool,
    isLastRange: Bool
  ) -> some ShapeStyle {
    let color = colorForAge(range.upperAge)

    if isFirstRange {
      // Youngest range - gradient fades up (no upper bound)
      return AnyShapeStyle(
        LinearGradient(
          colors: [color.opacity(0.3), color.opacity(0.05)],
          startPoint: .bottom,
          endPoint: .top
        )
      )
    } else if isLastRange {
      // Oldest range - gradient fades down (no lower bound)
      return AnyShapeStyle(
        LinearGradient(
          colors: [color.opacity(0.3), color.opacity(0.05)],
          startPoint: .top,
          endPoint: .bottom
        )
      )
    } else {
      // Middle range - solid fill
      return AnyShapeStyle(color.opacity(0.3))
    }
  }

  func stairClimbSpeedRangeFill(
    for range: (lowerAge: Int, upperAge: Int, minSpeed: Double, maxSpeed: Double),
    isFirstRange: Bool,
    isLastRange: Bool
  ) -> some ShapeStyle {
    let color = colorForAge(range.upperAge)

    if isFirstRange {
      // Youngest range - gradient fades up (no upper bound)
      return AnyShapeStyle(
        LinearGradient(
          colors: [color.opacity(0.3), color.opacity(0.05)],
          startPoint: .bottom,
          endPoint: .top
        )
      )
    } else if isLastRange {
      // Oldest range - gradient fades down (no lower bound)
      return AnyShapeStyle(
        LinearGradient(
          colors: [color.opacity(0.3), color.opacity(0.05)],
          startPoint: .top,
          endPoint: .bottom
        )
      )
    } else {
      // Middle range - solid fill
      return AnyShapeStyle(color.opacity(0.3))
    }
  }

  func colorForAge(_ age: Int) -> Color {
    switch age {
    case ...35:
      return .mutedGreen
    case 36...50:
      return .mutedYellow
    case 51...60:
      return .mutedOrange
    default:
      return .mutedRed
    }
  }
}

private extension Int {
  var compactFormatted: String {
    if self >= 1_000_000 {
      let millions = Double(self) / 1_000_000
      return "\(millions.format(using: .oneDecimalPlace))M"
    } else if self >= 1_000 {
      let thousands = Double(self) / 1_000
      return "\(thousands.format(using: .oneDecimalPlace))K"
    } else {
      return "\(self)"
    }
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      MobilityDetailsView()
    }
  }
}
