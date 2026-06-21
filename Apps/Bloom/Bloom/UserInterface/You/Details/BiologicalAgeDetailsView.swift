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

  enum HistoryRange: String, CaseIterable, Identifiable {
    case oneMonth = "1M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case twoYears = "2Y"
    case fiveYears = "5Y"

    var id: String { rawValue }

    var months: Int {
      switch self {
      case .oneMonth: return 1
      case .sixMonths: return 6
      case .oneYear: return 12
      case .twoYears: return 24
      case .fiveYears: return 60
      }
    }
  }

  @State private var biologicalAgeViewModel = BiologicalAgeViewModel.shared
  @State private var biologicalAgeRecords: [BiologicalAgeRecordDTO] = []
  @State private var historyRange: HistoryRange = .oneMonth

  private let birthMonth = HealthDefaults.shared.getBirthMonth()
  private let birthYear = HealthDefaults.shared.getBirthYear()

  private var filteredRecords: [BiologicalAgeRecordDTO] {
    guard let cutoff = Calendar.current.date(
      byAdding: .month,
      value: -historyRange.months,
      to: Date()
    ) else { return biologicalAgeRecords }
    return biologicalAgeRecords.filter { $0.date >= cutoff }
  }

  /// Approximate span of stored records in months (now - oldest record).
  private var recordSpanMonths: Double {
    guard let oldest = biologicalAgeRecords.first?.date else { return 0 }
    let seconds = Date().timeIntervalSince(oldest)
    return seconds / (60 * 60 * 24 * 30.44)
  }

  /// Ranges to show in the picker: every range smaller than the span, plus the
  /// first range that fully contains it. Empty when span ≤ 1 month (picker hidden).
  private var availableRanges: [HistoryRange] {
    let span = recordSpanMonths
    guard span > 1 else { return [] }
    var result: [HistoryRange] = []
    for range in HistoryRange.allCases {
      result.append(range)
      if Double(range.months) >= span { break }
    }
    return result
  }

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

      // Confidence Section
      BioAgeConfidenceCard(result: result)

      // Chart
      if filteredRecords.count >= 2 {
        historyChart(actualAge: result.actualAge)
      }

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

        // Missing Metrics (no data available)
        let availableMetrics = Set(contributions.map(\.metric))
        let missingMetrics = BiologicalAgeMetric.allCases.filter { !availableMetrics.contains($0) }

        if missingMetrics.isNotEmpty {
          SectionTitleView("No Data")
            .padding(.horizontal)

          ForEach(missingMetrics, id: \.self) { metric in
            MissingMetricCell(metric: metric)
          }
        }
      }

      MedicalDisclaimerFooterView()
    }
  }

  func historyChart(actualAge: Double) -> some View {
    VStack(alignment: .leading) {
      Text("Bio Age History")
        .font(.headline)
        .bold()
        .fontDesign(.rounded)
      Chart {
        ForEach(filteredRecords) { record in
          // Actual age line
          LineMark(
            x: .value("Date", record.date, unit: .day),
            y: .value("Age", fractionalAge(for: record.date)),
            series: .value("Type", "Actual")
          )
          .interpolationMethod(.catmullRom)
          .foregroundStyle(.text.secondary)
          .lineStyle(StrokeStyle(lineWidth: 6, lineCap: .round))

          // Bio age line
          LineMark(
            x: .value("Date", record.date, unit: .day),
            y: .value("Age", record.biologicalAge),
            series: .value("Type", "Bio")
          )
          .interpolationMethod(.catmullRom)
          .foregroundStyle(.mutedGreen)
          .lineStyle(StrokeStyle(lineWidth: 6, lineCap: .round))
        }

        // Single end-point for biological age (border effect like steps graph)
        if let lastRecord = filteredRecords.last {
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
      .frame(height: 150)
      .chartXAxis {
        let stride = xAxisStride(for: filteredRecords)
        AxisMarks(values: .stride(by: stride.component, count: stride.count)) { _ in
          AxisGridLine()
          AxisTick()
          AxisValueLabel(format: stride.format)
        }
      }
      .chartYAxis {
        AxisMarks(position: .trailing, values: .stride(by: 5)) { value in
          AxisGridLine()
          AxisTick()
          if let doubleValue = value.as(Double.self) {
            AxisValueLabel("\(Int(doubleValue))")
          } else {
            AxisValueLabel()
          }
        }
      }

      HStack(spacing: 16) {
        HStack {
          Circle()
            .fill(.text.secondary)
            .frame(width: 8, height: 8)
          Text("Actual Age")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        HStack {
          Circle()
            .fill(.mutedGreen)
            .frame(width: 8, height: 8)
          Text("Biological Age")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
      }

      if availableRanges.count > 1 {
        Picker("Time Range", selection: $historyRange) {
          ForEach(availableRanges) { range in
            Text(range.rawValue).tag(range)
          }
        }
        .pickerStyle(.segmented)
        .padding(.top, 8)
        .onChange(of: availableRanges) { _, ranges in
          if !ranges.contains(historyRange), let first = ranges.first {
            historyRange = first
          }
        }
      }
    }
    .cardContainer()
  }

  private struct XAxisStride {
    let component: Calendar.Component
    let count: Int
    let format: Date.FormatStyle
  }

  private func xAxisStride(for records: [BiologicalAgeRecordDTO]) -> XAxisStride {
    guard
      let first = records.first?.date,
      let last = records.last?.date
    else {
      return XAxisStride(component: .day, count: 1, format: .dateTime.month(.abbreviated).day())
    }
    let days = max(1, Calendar.current.dateComponents([.day], from: first, to: last).day ?? 1)

    switch days {
    case ...14:
      return XAxisStride(component: .day, count: 2, format: .dateTime.month(.abbreviated).day())
    case 15...60:
      return XAxisStride(component: .weekOfYear, count: 1, format: .dateTime.month(.abbreviated).day())
    case 61...180:
      return XAxisStride(component: .month, count: 1, format: .dateTime.month(.abbreviated))
    case 181...730:
      return XAxisStride(component: .month, count: 3, format: .dateTime.month(.abbreviated).year(.twoDigits))
    default:
      return XAxisStride(component: .year, count: 1, format: .dateTime.year())
    }
  }

  private var chartYMin: Double {
    let minBioAge = filteredRecords.map(\.biologicalAge).min() ?? 0
    let minActualAge = filteredRecords.map { fractionalAge(for: $0.date) }.min() ?? 0
    let minValue = min(minBioAge, minActualAge)
    return max(0, minValue - 5)
  }

  private var chartYMax: Double {
    let maxBioAge = filteredRecords.map(\.biologicalAge).max() ?? 100
    let maxActualAge = filteredRecords.map { fractionalAge(for: $0.date) }.max() ?? 100
    let maxValue = max(maxBioAge, maxActualAge)
    return maxValue + 5
  }

  /// Calculates fractional age for a given date based on birth year and optional birth month
  /// When birth month is known, uses the 15th of the month as the birthday baseline
  /// Otherwise creates a smooth slope throughout the year from Jan 1
  private func fractionalAge(for date: Date) -> Double {
    guard birthYear > 0 else { return 0 }

    let calendar = Calendar.current
    let year = calendar.component(.year, from: date)

    if birthMonth > 0 {
      // When birth month is known, calculate fractional age using mid-month (15th) as birthday
      var birthdayComponents = DateComponents()
      birthdayComponents.year = year
      birthdayComponents.month = birthMonth
      birthdayComponents.day = 15

      guard let birthdayThisYear = calendar.date(from: birthdayComponents) else {
        return Double(year - birthYear)
      }

      let wholeYears = Double(year - birthYear)
      let daysSinceBirthday = calendar.dateComponents([.day], from: birthdayThisYear, to: date).day ?? 0
      let fractionalPart = Double(daysSinceBirthday) / 365.0

      return wholeYears + fractionalPart
    } else {
      // When only birth year is known, use Jan 1 as baseline
      let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
      let daysInYear = calendar.range(of: .day, in: .year, for: date)?.count ?? 365

      let wholeYears = Double(year - birthYear)
      let fractionalPart = Double(dayOfYear - 1) / Double(daysInYear)

      return wholeYears + fractionalPart
    }
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

#Preview {
  PreviewEnvironment {
    NavigationStack {
      BiologicalAgeDetailsView()
    }
  }
}
