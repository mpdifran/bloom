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

struct BodyCompositionDetailsView: View {

  @State private var bodyMassSamples = [DateQuantitySample]()
  @State private var bodyFatPercentageSamples = [DateQuantitySample]()

  private let viewModel = VitalsViewModel.shared

  @State private var presentedSheet: AnyView?
  @State private var selectedRangeIndex = 0

  private let ranges: [BodyCompositionMonthlySummary.PercentageRange] = [
    .essentialFat,
    .athlete,
    .fit,
    .healthy,
    .high
  ]

  let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

  var body: some View {
    Group {
      if viewModel.bodyCompositionSummary?.details.hasNoData == false {
        contentView
      } else {
        emptyView
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        VitalSummaryDetailTitleView(
          title: "Body Composition",
          subtitle: "Last 30 Days"
        )
      }
    }
    .navigationTitle("Body Composition")
    .navigationBarTitleDisplayMode(.inline)
    .sheet($presentedSheet)
    .animation(.default, value: range)
    .task {
      let samples = await HealthStoreFetcher.shared.fetchCollatedAverage(
        quantityType: .bodyFatPercentage,
        unit: .percent(),
        dateRange: .trailingMonthsFromNow(1)
      )

      await MainActor.run {
        self.bodyFatPercentageSamples = samples
      }
    }
    .task {
      let samples = (try? await HealthManager.shared.healthStore.fetchAverageStatistics(
        quantityTypeID: .bodyMass,
        unit: .pound(),
        dateRange: .trailingMonthsFromNow(1)
      )) ?? []

      await MainActor.run {
        self.bodyMassSamples = samples
      }
    }
    .onAppear {
      feedbackGenerator.prepare()
      if
        let range = viewModel.bodyCompositionSummary?.details.range,
        let index = ranges.firstIndex(where: { $0 == range })
      {
        self.selectedRangeIndex = index
      }
      TelemetryDeck.viewScreen("Body Composition Vital Details")
    }
  }
}

private extension BodyCompositionDetailsView {

  var contentView: some View {
    BloomScrollView {
      bodyMassChart
      VStack {
        bodyFatPercentageChart
        bodyFatPercentageRangePicker
      }
      .cardContainer()
      detailsSection
    }
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

          Chart {
            ForEach(bodyMassSamples) { sample in
              LineMark(
                x: .value("Date", sample.date, unit: .day),
                y: .value("Body Weight", sample.quantity.localizedValue(for: .pound()))
              )
              .foregroundStyle(.tint)

              PointMark(
                x: .value("Date", sample.date, unit: .day),
                y: .value("Body Weight", sample.quantity.localizedValue(for: .pound()))
              )
              .foregroundStyle(.tint)
              .symbolSize(40)
            }
          }
          .tint(.mutedIndigo)
          .chartYScale(domain: bodyMassChartMin...bodyMassChartMax, range: .plotDimension)
          .frame(height: 200)
          .chartXAxis {
            AxisMarks(values: .stride(by: .weekOfYear)) { _ in
              AxisGridLine()
              AxisTick()
              AxisValueLabel()
            }
          }
          .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic) { value in
              AxisGridLine()
              AxisTick()
              if let doubleValue = value.as(Double.self) {
                AxisValueLabel("\(doubleValue.format()) \(HKUnit.pound().localizedUnit())")
              } else {
                AxisValueLabel()
              }
            }
          }
        }
        .cardContainer()

        if let bodyMassTrendDescription = viewModel.bodyCompositionSummary?.bodyMassTrendDescription {
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

  var bodyFatPercentageChart: some View {
    VStack(alignment: .leading) {
      VitalDetailChartTitleView(title: "Body Fat Percentage", value: "\(average.format())%")

      Chart {
        ForEach(bodyFatPercentageSamples) { sample in
          if
            let goals = viewModel.bodyCompositionSummary?.details.goalBodyFatPercentage,
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

          LineMark(
            x: .value("Date", sample.date, unit: .day),
            y: .value("Body Fat Percentage", sample.quantity.doubleValue(for: .percent()))
          )
          .foregroundStyle(viewModel.bodyCompositionSummary?.details.range?.color ?? .vitalGood)

          PointMark(
            x: .value("Date", sample.date, unit: .day),
            y: .value("Body Fat Percentage", sample.quantity.doubleValue(for: .percent()))
          )
          .foregroundStyle(viewModel.bodyCompositionSummary?.details.range?.color ?? .vitalGood)
          .symbolSize(40)
        }
      }
      .frame(height: 200)
      .chartXAxis {
        AxisMarks(values: .stride(by: .weekOfYear)) { _ in
          AxisGridLine()
          AxisTick()
          AxisValueLabel()
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
        }

        Link("Learn More", destination: URL(string: "https://www.healthline.com/health/exercise-fitness/ideal-body-fat-percentage")!)
          .foregroundStyle(range.color)
      }
    }
  }
}

#Preview {
  NavigationStack {
    BodyCompositionDetailsView()
  }
}
