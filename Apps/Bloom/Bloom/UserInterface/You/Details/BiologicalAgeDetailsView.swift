//
//  BiologicalAgeDetailsView.swift
//  Bloom
//
//  Created by Assistant on 2025-09-15.
//

import SwiftUI
import SFSafeSymbols
import TelemetryDeck
import CoreHealth
import Charts
import DataContainer

struct BiologicalAgeDetailsView: View {

  @State private var biologicalAgeViewModel = BiologicalAgeViewModel.shared
  @State private var biologicalAgeRecords: [BiologicalAgeRecordDTO] = []

  var body: some View {
    Group {
      if let result = biologicalAgeViewModel.biologicalAgeResult {
        contentView(result: result)
      } else {
        emptyView
      }
    }
    .groupedBackground()
    .navigationTitle("Biological Age")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      TelemetryDeck.viewScreen("Biological Age Details")
    }
    .task {
      let modelActor = BiologicalAgeRecordModelActor.standard()
      biologicalAgeRecords = (try? await modelActor.fetchAllRecords()) ?? []
    }
  }
}

private extension BiologicalAgeDetailsView {

  func contentView(result: BiologicalAgeResult) -> some View {
    BloomScrollView {
      // Biological Age Meter
      BiologicalAgeMeter(biologicalAge: result.biologicalAge)
        .frame(square: 250)
        .horizontallyCentered()
        .padding(.bottom)

      // Age Summary
      ageSummaryCard(result: result)

      // Confidence Section
      confidenceCard(result: result)

      // Positive Factors (metrics making you younger)
      if let contributions = result.metricContributions {
        let positiveFactors = contributions
          .filter { $0.weightedDelta < -0.1 }
          .sorted { $0.weightedDelta < $1.weightedDelta }  // Most negative (biggest impact) first

        if positiveFactors.isNotEmpty {
          SectionTitleView("Positive Factors")
            .padding(.horizontal)

          ForEach(positiveFactors) { contribution in
            MetricContributionCell(contribution: contribution, isPositive: true)
          }
        }

        // Negative Factors (metrics making you older)
        let negativeFactors = contributions
          .filter { $0.weightedDelta > 0.1 }
          .sorted { $0.weightedDelta > $1.weightedDelta }  // Most positive (biggest impact) first

        if negativeFactors.isNotEmpty {
          SectionTitleView("Areas for Improvement")
            .padding(.horizontal)

          ForEach(negativeFactors) { contribution in
            MetricContributionCell(contribution: contribution, isPositive: false)
          }
        }

        // Minimal Effect Factors (abs(weightedDelta) <= 0.1)
        let minimalEffectFactors = contributions
          .filter { abs($0.weightedDelta) <= 0.1 }
          .sorted { abs($0.weightedDelta) > abs($1.weightedDelta) }

        if minimalEffectFactors.isNotEmpty {
          SectionTitleView("No Effect")
            .padding(.horizontal)

          ForEach(minimalEffectFactors) { contribution in
            MetricContributionCell(contribution: contribution, isPositive: nil)
          }
        }
      }

      MedicalDisclaimerFooterView()
    }
  }

  func ageSummaryCard(result: BiologicalAgeResult) -> some View {
    VStack(spacing: 12) {
      // History Chart (only show if 2+ data points)
      if biologicalAgeRecords.count >= 2 {
        historyChart(actualAge: result.actualAge)
      }

      HStack {
        VStack(alignment: .leading) {
          HStack {
            Circle()
              .fill(.text)
              .frame(width: 8, height: 8)
            Text("Actual Age")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          Text("\(Int(result.actualAge))")
            .font(.largeTitle)
            .bold()
            .fontDesign(.rounded)
        }

        Spacer()

        VStack(alignment: .trailing) {
          HStack {
            Circle()
              .fill(.mutedGreen)
              .frame(width: 8, height: 8)
            Text("Biological Age")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          Text(result.biologicalAge.format(using: .oneDecimalPlace))
            .font(.largeTitle)
            .bold()
            .fontDesign(.rounded)
        }
      }
    }
    .cardContainer()
  }

  func confidenceCard(result: BiologicalAgeResult) -> some View {
    HStack {
      Image(systemSymbol: .checkmarkSealFill)
        .font(.title2)

      VStack(alignment: .leading, spacing: 2) {
        Text(result.confidence.displayName)
          .font(.title3)
          .fontDesign(.rounded)

        let metricsCount = result.metricContributions?.count ?? 0
        Text("\(metricsCount) of 19 metrics considered")
          .font(.subheadline)
          .bold()
          .foregroundStyle(.secondary)
      }

      Spacer(minLength: 0)

      Text("\(result.availableWeightPercentage.format(using: .noDecimalPlaces))%")
        .font(.title)
        .fontWeight(.heavy)
        .fontDesign(.rounded)
    }
    .foregroundStyle(.white)
    .cardContainer(fill: result.confidence.color)
  }

  func historyChart(actualAge: Double) -> some View {
    VStack(alignment: .leading) {
      Chart {
        ForEach(biologicalAgeRecords) { record in
          // Actual age line
          LineMark(
            x: .value("Date", record.date, unit: .day),
            y: .value("Age", record.actualAge),
            series: .value("Type", "Actual")
          )
          .interpolationMethod(.catmullRom)
          .foregroundStyle(.text)
          .lineStyle(StrokeStyle(lineWidth: 2))

          // Bio age line
          LineMark(
            x: .value("Date", record.date, unit: .day),
            y: .value("Age", record.biologicalAge),
            series: .value("Type", "Bio")
          )
          .interpolationMethod(.catmullRom)
          .foregroundStyle(.mutedGreen)
          .lineStyle(StrokeStyle(lineWidth: 2))
        }

        // Single end-point for biological age (border effect like steps graph)
        if let lastRecord = biologicalAgeRecords.last {
          // Outer border
          PointMark(
            x: .value("Date", lastRecord.date, unit: .day),
            y: .value("Age", lastRecord.biologicalAge)
          )
          .foregroundStyle(Color(.systemBackground))
          .symbolSize(100)

          // Inner fill
          PointMark(
            x: .value("Date", lastRecord.date, unit: .day),
            y: .value("Age", lastRecord.biologicalAge)
          )
          .foregroundStyle(.mutedGreen)
          .symbolSize(40)
        }
      }
      .chartYScale(domain: chartYMin...chartYMax)
      .frame(height: 120)
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
            AxisValueLabel("\(Int(doubleValue))")
          } else {
            AxisValueLabel()
          }
        }
      }
    }
  }

  private var chartYMin: Double {
    let minBioAge = biologicalAgeRecords.map(\.biologicalAge).min() ?? 0
    let minActualAge = biologicalAgeRecords.map(\.actualAge).min() ?? 0
    let minValue = min(minBioAge, minActualAge)
    return max(0, minValue - 5)
  }

  private var chartYMax: Double {
    let maxBioAge = biologicalAgeRecords.map(\.biologicalAge).max() ?? 100
    let maxActualAge = biologicalAgeRecords.map(\.actualAge).max() ?? 100
    let maxValue = max(maxBioAge, maxActualAge)
    return maxValue + 5
  }

  var emptyView: some View {
    BloomScrollView {
      VStack(spacing: 10) {
        BiologicalAgeMeter(biologicalAge: nil)
          .frame(width: 130)
          .saturation(0)

        Text("No Biological Age Data")
          .font(.title2)
          .fontWeight(.semibold)
          .foregroundColor(.primary)

        Text("Your biological age will appear here once calculated. Check back after using the app for a few days.")
          .font(.body)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .cardContainer()
    }
  }
}

struct MetricContributionCell: View {

  let contribution: MetricContribution
  let isPositive: Bool?

  private var symbol: SFSymbol {
    if let isPositive {
      return isPositive ? .arrowDownCircleFill : .arrowUpCircleFill
    }
    return .minusCircleFill
  }

  private var tintColor: Color {
    if let isPositive {
      return isPositive ? .mutedGreen : .mutedPink
    }
    return .mutedBlue
  }

  private var contributionText: String {
    let delta = contribution.weightedDelta
    if delta >= 0 {
      return "+\(delta.format(using: .oneDecimalPlace)) years"
    } else {
      return "\(delta.format(using: .oneDecimalPlace)) years"
    }
  }

  var body: some View {
    HStack {
      Image(systemSymbol: symbol)
        .font(.title2)
        .foregroundStyle(.white, tintColor)

      VStack(alignment: .leading, spacing: 2) {
        Text(contribution.metric.rawValue)
          .bold()
          .fontDesign(.rounded)

        Text(contribution.metric.category.rawValue)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer(minLength: 0)

      if isPositive != nil {
        Text(contributionText)
          .font(.headline)
          .fontWeight(.heavy)
          .fontDesign(.rounded)
          .foregroundStyle(tintColor)
      }
    }
    .fixedSize(horizontal: false, vertical: true)
    .cardContainer()
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      BiologicalAgeDetailsView()
    }
  }
}
