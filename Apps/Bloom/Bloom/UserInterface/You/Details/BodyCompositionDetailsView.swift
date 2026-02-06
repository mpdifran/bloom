//
//  BodyCompositionDetailsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-04.
//

import SFSafeSymbols
import SwiftUI
import Charts
import HealthKit
import TelemetryDeck
import CoreHealth
import BloomFoundation

struct BodyCompositionDetailsView: View {

  @State private var selectedPeriod: StatTimePeriod = .oneMonth
  @State private var bodyMassSamples = [DateQuantitySample]()
  @State private var bodyFatPercentageSamples = [DateQuantitySample]()

  @State private var bodyCompositionSummary: BodyCompositionMonthlySummary?

  @State private var presentedSheet: AnyView?
  @State private var selectedRangeIndex = 0
  @State private var rawSelectedDate: Date?
  @State private var selectedWeight: DateQuantitySample?

  private let ranges: [BodyCompositionMonthlySummary.PercentageRange] = [
    .essentialFat,
    .athlete,
    .fit,
    .healthy,
    .high
  ]

  let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

  var hasData: Bool {
    bodyMassSamples.isNotEmpty || bodyFatPercentageSamples.isNotEmpty
  }

  var body: some View {
    BloomScrollView {
      StatTimePeriodPicker(selectedPeriod: $selectedPeriod)

      if hasData {
        contentView
      } else {
        emptyView
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        VitalSummaryDetailTitleView(
          title: "Body Composition",
          subtitle: selectedPeriod.displayName
        )
      }
    }
    .navigationTitle("Body Composition")
    .navigationBarTitleDisplayMode(.inline)
    .sheet($presentedSheet)
    .animation(.default, value: range)
    .animation(.default, value: selectedPeriod)
    .task(id: selectedPeriod) {
      let interval = selectedPeriod.aggregatesByWeek ? DateComponents(weekOfYear: 1) : DateComponents(day: 1)

      let samples = await HealthStoreFetcher.shared.fetchCollatedAverage(
        quantityType: .bodyFatPercentage,
        unit: .percent(),
        interval: interval,
        dateRange: selectedPeriod.dateRange
      )

      await MainActor.run {
        self.bodyFatPercentageSamples = samples
      }
    }
    .task(id: selectedPeriod) {
      let interval = selectedPeriod.aggregatesByWeek ? DateComponents(weekOfYear: 1) : DateComponents(day: 1)

      let samples = await HealthStoreFetcher.shared.fetchCollatedAverage(
        quantityType: .bodyMass,
        unit: .pound(),
        interval: interval,
        dateRange: selectedPeriod.dateRange
      )

      await MainActor.run {
        self.bodyMassSamples = samples
      }
    }
    .task {
      let summary = await HealthStoreFetcher.shared.fetchBodyCompositionSummary()
      await MainActor.run {
        self.bodyCompositionSummary = summary
        if let range = summary.details.range, let index = ranges.firstIndex(of: range) {
          selectedRangeIndex = index
        }
      }
    }
    .onAppear {
      feedbackGenerator.prepare()
      TelemetryDeck.viewScreen("Body Composition Vital Details")
    }
  }
}

private extension BodyCompositionDetailsView {

  @ViewBuilder
  var contentView: some View {
    bodyMassChart
    VStack {
      bodyFatPercentageChart
      bodyFatPercentageRangePicker
    }
    .cardContainer()
    detailsSection
  }

  var emptyView: some View {
    ContentUnavailableView {
      Label("No Data Available", systemSymbol: .gaugeWithNeedle)
    } description: {
      Text("Log your weight to learn more about your body composition.")
    } actions: {
      Button("Log Weight") {
        presentedSheet = BodyWeightActionCardView(performDismiss: nil).asAny
      }
      .buttonStyle(.primary)
      .tint(.mutedIndigo)
    }
  }

  var average: Double {
    bodyFatPercentageSamples.map({ $0.quantity.doubleValue(for: .percent()) }).average(keyPath: \.self) * 100
  }

  var averageWeight: HKQuantity {
    let averageValue = bodyMassSamples.map({ $0.quantity.doubleValue(for: .pound()) }).average(keyPath: \.self)
    return HKQuantity(unit: .pound(), doubleValue: averageValue)
  }
}

private extension BodyCompositionDetailsView {

  @ViewBuilder
  var bodyMassChart: some View {
    if bodyMassSamples.isNotEmpty {
      VStack {
        VStack {
          VitalDetailChartTitleView(title: "Body Weight", value: "\(averageWeight.displayString(for: .pound(), formatter: .oneDecimalPlace))")
            .padding(.horizontal)
            .padding(.top)

          Chart(bodyMassSamples) { sample in
            AreaMark(
              x: .value("Date", sample.date),
              y: .value("Body Weight", sample.quantity.localizedValue(for: .pound()))
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
              LinearGradient(
                colors: [Color.mutedIndigo.opacity(0.4), Color.mutedIndigo.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
              )
            )

            LineMark(
              x: .value("Date", sample.date),
              y: .value("Body Weight", sample.quantity.localizedValue(for: .pound()))
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(Color.mutedIndigo)
            .lineStyle(StrokeStyle(lineWidth: 3))
          }
          .chartYScale(domain: bodyMassChartMin...bodyMassChartMax)
          .chartXScale(domain: bodyMassChartXDomain)
          .frame(height: 200)
          .chartXAxis {
            AxisMarks(values: .automatic) { _ in
              AxisGridLine()
              AxisValueLabel(format: selectedPeriod.chartDateFormat)
            }
          }
          .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic) { value in
              AxisGridLine()
                .foregroundStyle(.secondary.opacity(0.3))
              if let doubleValue = value.as(Double.self) {
                AxisValueLabel {
                  Text("\(doubleValue.format()) \(HKUnit.pound().localizedUnit())")
                    .font(.caption2)
                }
              }
            }
          }
          .chartXSelection(value: $rawSelectedDate)
          .sensoryFeedback(.selection, trigger: selectedWeight)
          .chartOverlay { proxy in
            GeometryReader { geometry in
              if let selectedWeight, let xPosition = proxy.position(forX: selectedWeight.date) {
                weightOverlay(for: selectedWeight)
                  .position(x: min(max(xPosition, 60), geometry.size.width - 60), y: 20)
              }
            }
          }
          .onChange(of: rawSelectedDate) { _, newValue in
            if let date = newValue {
              selectedWeight = findNearestWeightSample(to: date)
            } else {
              selectedWeight = nil
            }
          }
        }
        .cardContainer(includePadding: false)

        if let bodyMassTrendDescription = bodyCompositionSummary?.bodyMassTrendDescription {
          DetailInfoCardView {
            Text(bodyMassTrendDescription)
          }
        }
      }
      .padding(.bottom)
    }
  }

  var bodyMassChartMin: Double {
    if
      let min = bodyMassSamples.min(by: {
        $0.quantity.doubleValue(for: .pound()) < $1.quantity.doubleValue(for: .pound())
      })?.quantity.localizedValue(for: .pound())
    {
      return min * 0.9
    }
    return HKQuantity(unit: .pound(), doubleValue: 100).localizedValue(for: .pound())
  }

  var bodyMassChartMax: Double {
    if
      let max = bodyMassSamples.max(by: {
        $0.quantity.doubleValue(for: .pound()) < $1.quantity.doubleValue(for: .pound())
      })?.quantity.localizedValue(for: .pound())
    {
      return max * 1.1
    }
    return HKQuantity(unit: .pound(), doubleValue: 250).localizedValue(for: .pound())
  }

  var bodyMassChartXDomain: ClosedRange<Date> {
    guard let minDate = bodyMassSamples.map(\.date).min(),
          let maxDate = bodyMassSamples.map(\.date).max() else {
      return Date()...Date()
    }
    return minDate...maxDate
  }

  func findNearestWeightSample(to date: Date) -> DateQuantitySample? {
    bodyMassSamples.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
  }

  @ViewBuilder
  func weightOverlay(for sample: DateQuantitySample) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(sample.date.formatted(date: .abbreviated, time: .omitted))
        .font(.caption)
        .bold()
      Text(sample.quantity.displayString(for: .pound(), formatter: .oneDecimalPlace))
        .font(.caption2)
    }
    .padding(8)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
  }

  var bodyFatPercentageChart: some View {
    VStack(alignment: .leading) {
      VitalDetailChartTitleView(title: "Body Fat Percentage", value: "\(average.format())%")

      Chart {
        if
          let goals = bodyCompositionSummary?.details.goalBodyFatPercentage,
          let goal = range.rangeValues(from: goals)
        {

          RectangleMark(
            yStart: .value("Min", goal.lowerBound),
            yEnd: .value("Max", goal.upperBound)
          )
          .foregroundStyle(range.color.opacity(0.1))

          RuleMark(
            y: .value("Min", goal.lowerBound)
          )
          .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
          .foregroundStyle(range.color)

          RuleMark(
            y: .value("Max", goal.upperBound)
          )
          .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
          .foregroundStyle(range.color)
        }

        ForEach(bodyFatPercentageSamples) { sample in
          LineMark(
            x: .value("Date", sample.date, unit: .day),
            y: .value("Body Fat Percentage", sample.quantity.doubleValue(for: .percent()))
          )
          .foregroundStyle(bodyCompositionSummary?.details.range?.color ?? .vitalGood)

          PointMark(
            x: .value("Date", sample.date, unit: .day),
            y: .value("Body Fat Percentage", sample.quantity.doubleValue(for: .percent()))
          )
          .foregroundStyle(bodyCompositionSummary?.details.range?.color ?? .vitalGood)
          .symbolSize(40)
        }
      }
      .frame(height: 200)
      .chartXAxis {
        AxisMarks(values: .automatic) { _ in
          AxisGridLine()
          AxisValueLabel(format: selectedPeriod.chartDateFormat)
        }
      }
      .chartYAxis {
        AxisMarks(position: .trailing, values: .automatic) { _ in
          AxisGridLine()
          AxisTick()
          AxisValueLabel(format: Decimal.FormatStyle.Percent.percent)
        }
      }
    }
  }

  var range: BodyCompositionMonthlySummary.PercentageRange {
    ranges[selectedRangeIndex]
  }

  var bodyFatPercentageRangePicker: some View {
    Button {
      selectedRangeIndex = (selectedRangeIndex + 1) % ranges.count
      feedbackGenerator.impactOccurred()
    } label: {
      HStack {
        Text(range.name)

        Spacer()

        Text(range.rangeDescription(from: HealthGoalProvider.shared.goalBodyFatPercentage()))
      }
    }
    .buttonStyle(.zone)
    .tint(range.color)
  }

  @ViewBuilder
  var detailsSection: some View {
    if range != .unknown {
      DetailInfoCardView {
        switch range {
        case .essentialFat:
          Text("Essential fat is the minimum amount of fat necessary for basic physiological functions. It is crucial for the protection of internal organs, insulation, and reproductive health. It can be difficult on the body to remain in this range.")
        case .athlete:
          Text("This range is typical for athletes who require higher muscle mass and lower fat levels for optimal performance. It reflects a high level of fitness and conditioning.")
        case .fit:
          Text("Individuals in this range have a healthy amount of body fat and are usually quite active. This range is often seen in non-competitive athletes or individuals who maintain a consistent exercise routine.")
        case .healthy:
          Text("This range is considered normal for the general population. People within this range have a balanced level of body fat, contributing to overall health and well-being.")
        case .high:
          Text("Higher body fat percentages can be associated with an increased risk of health issues such as cardiovascular disease, diabetes, and other metabolic conditions. It may indicate a need for lifestyle changes to improve health.")
        case .unknown:
          EmptyView()
        @unknown default:
          EmptyView()
        }

        HealthCitationLinkView(
          url: .aceFitnessCalculators,
          title: "Body-fat classification ranges based on the American Council on Exercise (ACE) guidelines."
        )
      }
    }
  }
}

#Preview {
  NavigationStack {
    BodyCompositionDetailsView()
  }
}
