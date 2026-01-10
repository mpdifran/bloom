//
//  SleepMetricsDetailsView.swift
//  Bloom
//
//  Created by Assistant on 2026-01-09.
//

import SwiftUI
import Charts
import TelemetryDeck
import SFSafeSymbols
import CoreHealth
import BloomFoundation

struct SleepMetricsDetailsView: View {
  @State private var selectedPeriod: StatTimePeriod = .sevenDays
  @State private var sleepHRDataPoints: [SleepHRDataPoint] = []
  @State private var rhrDataPoints: [DateQuantitySample] = []
  @State private var temperatureDataPoints: [DateQuantitySample] = []
  @State private var respiratoryDataPoints: [DateQuantitySample] = []

  var body: some View {
    Group {
      if hasData {
        contentView
      } else {
        emptyView
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        VitalSummaryDetailTitleView(
          title: "Sleep Metrics",
          subtitle: selectedPeriod.displayName
        )
      }
    }
    .navigationTitle("Sleep Metrics")
    .navigationBarTitleDisplayMode(.inline)
    .animation(.default, value: sleepHRDataPoints.map(\.id))
    .task(id: selectedPeriod) {
      await loadData()
    }
    .onAppear {
      TelemetryDeck.viewScreen("Sleep Metrics Details")
    }
  }
}

// MARK: - Data Loading

private extension SleepMetricsDetailsView {

  var hasData: Bool {
    sleepHRDataPoints.isNotEmpty || rhrDataPoints.isNotEmpty ||
    temperatureDataPoints.isNotEmpty || respiratoryDataPoints.isNotEmpty
  }

  func loadData() async {
    let dateRange = selectedPeriod.dateRange
    let interval = selectedPeriod.aggregatesByWeek ? DateComponents(weekOfYear: 1) : DateComponents(day: 1)

    async let sleepAnalyses = HealthStoreFetcher.shared.fetchSleepAnalysis(dateRange: dateRange)
    async let rhrSamples = HealthStoreFetcher.shared.fetchCollatedAverage(
      quantityType: .restingHeartRate,
      unit: .bpm(),
      interval: interval,
      dateRange: dateRange
    )
    async let respSamples = HealthStoreFetcher.shared.fetchCollatedAverage(
      quantityType: .respiratoryRate,
      unit: .breathsPerMinute(),
      interval: interval,
      dateRange: dateRange
    )
    async let tempSamples = HealthStoreFetcher.shared.fetchCollatedAverage(
      quantityType: .appleSleepingWristTemperature,
      unit: .degreeFahrenheit(),
      interval: interval,
      dateRange: dateRange
    )

    let (analyses, rhr, resp, temp) = await (sleepAnalyses, rhrSamples, respSamples, tempSamples)

    // Calculate average sleep HR per night (needs manual aggregation)
    var sleepHR = analyses.compactMap { analysis -> SleepHRDataPoint? in
      let heartRates = analysis.heartRate
      guard heartRates.isNotEmpty else { return nil }
      let avgHR = heartRates.map(\.averageHeartRate).reduce(0, +) / Double(heartRates.count)
      return SleepHRDataPoint(date: analysis.endDate, heartRate: avgHR)
    }.sorted { $0.date < $1.date }

    // Aggregate sleep HR by week for longer time periods
    if selectedPeriod.aggregatesByWeek {
      sleepHR = aggregateSleepHRByWeek(sleepHR)
    }

    await MainActor.run {
      self.sleepHRDataPoints = sleepHR
      self.rhrDataPoints = rhr
      self.temperatureDataPoints = temp
      self.respiratoryDataPoints = resp
    }
  }

  func aggregateSleepHRByWeek(_ dataPoints: [SleepHRDataPoint]) -> [SleepHRDataPoint] {
    let calendar = Calendar.current
    var weeklyData = [Date: [Double]]()

    for dataPoint in dataPoints {
      let weekStart = calendar.dateInterval(of: .weekOfYear, for: dataPoint.date)?.start ?? dataPoint.date
      weeklyData[weekStart, default: []].append(dataPoint.heartRate)
    }

    return weeklyData.compactMap { weekStart, values -> SleepHRDataPoint? in
      guard values.isNotEmpty else { return nil }
      let avg = values.reduce(0, +) / Double(values.count)
      return SleepHRDataPoint(date: weekStart, heartRate: avg)
    }.sorted { $0.date < $1.date }
  }
}

// MARK: - Content Views

private extension SleepMetricsDetailsView {

  var contentView: some View {
    BloomScrollView(spacing: 20) {
      StatTimePeriodPicker(selectedPeriod: $selectedPeriod)

      if sleepHRDataPoints.isNotEmpty || rhrDataPoints.isNotEmpty {
        heartRateChartSection
      }

      if temperatureDataPoints.isNotEmpty {
        temperatureChartSection
      }

      if respiratoryDataPoints.isNotEmpty {
        respiratoryRateChartSection
      }
    }
  }

  var emptyView: some View {
    ContentUnavailableView(
      "No Sleep Data",
      systemImage: "moon.zzz.fill",
      description: Text("Enable Sleep Focus and wear your Apple Watch to bed to track your sleep metrics.")
    )
  }
}

// MARK: - Heart Rate Chart

private extension SleepMetricsDetailsView {

  var averageSleepHR: Int? {
    guard sleepHRDataPoints.isNotEmpty else { return nil }
    let total = sleepHRDataPoints.map(\.heartRate).reduce(0, +)
    return Int(total / Double(sleepHRDataPoints.count))
  }

  var heartRateChartSection: some View {
    VStack(alignment: .leading) {
      VStack {
        VitalDetailChartTitleView(
          title: "Sleep Heart Rate",
          value: averageSleepHR.map { "\($0) bpm avg" } ?? ""
        )

        Chart {
          // Sleep HR line
          ForEach(sleepHRDataPoints) { dataPoint in
            LineMark(
              x: .value("Date", dataPoint.date, unit: selectedPeriod.aggregatesByWeek ? .weekOfYear : .day),
              y: .value("HR", dataPoint.heartRate),
              series: .value("Series", "Sleep HR")
            )
            .foregroundStyle(Color.mutedRed)
            .lineStyle(StrokeStyle(lineWidth: 3))
            .interpolationMethod(.catmullRom)
          }

          ForEach(sleepHRDataPoints) { dataPoint in
            PointMark(
              x: .value("Date", dataPoint.date, unit: selectedPeriod.aggregatesByWeek ? .weekOfYear : .day),
              y: .value("HR", dataPoint.heartRate)
            )
            .foregroundStyle(Color(.systemBackground))
            .symbolSize(60)
          }

          ForEach(sleepHRDataPoints) { dataPoint in
            PointMark(
              x: .value("Date", dataPoint.date, unit: selectedPeriod.aggregatesByWeek ? .weekOfYear : .day),
              y: .value("HR", dataPoint.heartRate)
            )
            .foregroundStyle(Color.mutedRed)
            .symbolSize(30)
          }

          // RHR line
          ForEach(rhrDataPoints) { sample in
            LineMark(
              x: .value("Date", sample.date, unit: selectedPeriod.aggregatesByWeek ? .weekOfYear : .day),
              y: .value("HR", sample.quantity.doubleValue(for: .bpm())),
              series: .value("Series", "Resting HR")
            )
            .foregroundStyle(Color.mutedRed.opacity(0.5))
            .lineStyle(StrokeStyle(lineWidth: 3))
            .interpolationMethod(.catmullRom)
          }

          ForEach(rhrDataPoints) { sample in
            PointMark(
              x: .value("Date", sample.date, unit: selectedPeriod.aggregatesByWeek ? .weekOfYear : .day),
              y: .value("HR", sample.quantity.doubleValue(for: .bpm()))
            )
            .foregroundStyle(Color(.systemBackground))
            .symbolSize(60)
          }

          ForEach(rhrDataPoints) { sample in
            PointMark(
              x: .value("Date", sample.date, unit: selectedPeriod.aggregatesByWeek ? .weekOfYear : .day),
              y: .value("HR", sample.quantity.doubleValue(for: .bpm()))
            )
            .foregroundStyle(Color.mutedRed.opacity(0.5))
            .symbolSize(30)
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
              .foregroundStyle(.secondary.opacity(0.3))
            if let hr = value.as(Double.self) {
              AxisValueLabel {
                Text("\(Int(hr))")
                  .font(.caption2)
              }
            }
          }
        }
        .chartYScale(domain: hrChartYDomain)
        .chartXScale(domain: hrChartXDomain)
        .chartLegend(.hidden)
        .frame(height: 200)

        hrChartLegend
          .horizontalAlignment(.leading)
      }
      .cardContainer()

      DetailInfoCardView {
        Text("Your heart rate during sleep is typically lower than your resting heart rate during the day. A lower sleep heart rate generally indicates better cardiovascular fitness and recovery.")
      }
    }
  }

  var hrChartLegend: some View {
    HStack(spacing: 16) {
      HStack(spacing: 4) {
        Circle()
          .fill(Color.mutedRed)
          .frame(width: 8, height: 8)
        Text("Sleep HR")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      HStack(spacing: 4) {
        Circle()
          .fill(Color.mutedRed.opacity(0.5))
          .frame(width: 8, height: 8)
        Text("Resting HR")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }

  var hrChartXDomain: ClosedRange<Date> {
    let allDates = sleepHRDataPoints.map(\.date) + rhrDataPoints.map(\.date)
    guard let minDate = allDates.min(),
          let maxDate = allDates.max() else {
      return Date()...Date()
    }
    return minDate...maxDate
  }

  var hrChartYDomain: ClosedRange<Double> {
    let sleepHRValues = sleepHRDataPoints.map(\.heartRate)
    let rhrValues = rhrDataPoints.map { $0.quantity.doubleValue(for: .bpm()) }
    let allValues = sleepHRValues + rhrValues

    guard let minHR = allValues.min(),
          let maxHR = allValues.max() else {
      return 40...100
    }

    let padding = max((maxHR - minHR) * 0.2, 10)
    return (minHR - padding)...(maxHR + padding)
  }
}

// MARK: - Temperature Chart

private extension SleepMetricsDetailsView {

  var averageTemperature: Double? {
    guard temperatureDataPoints.isNotEmpty else { return nil }
    let total = temperatureDataPoints.map(\.temperatureFahrenheit).reduce(0, +)
    return total / Double(temperatureDataPoints.count)
  }

  var formattedAverageTemperature: String? {
    guard let avg = averageTemperature else { return nil }
    let measurement = Measurement(value: avg, unit: UnitTemperature.fahrenheit)
    let localized = measurement.localizedValue
    let unit = UnitTemperature(forLocale: .current).symbol
    return "\(localized.format(using: .oneDecimalPlace))\(unit) avg"
  }

  var temperatureChartSection: some View {
    VStack(alignment: .leading) {
      VStack {
        VitalDetailChartTitleView(
          title: "Wrist Temperature",
          value: formattedAverageTemperature ?? ""
        )
        .padding(.horizontal)
        .padding(.top)

        Chart(temperatureDataPoints) { dataPoint in
          AreaMark(
            x: .value("Date", dataPoint.date),
            y: .value("Temp", dataPoint.localizedTemperature)
          )
          .foregroundStyle(
            LinearGradient(
              colors: [Color.mutedPurple.opacity(0.4), Color.mutedPurple.opacity(0.05)],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .interpolationMethod(.catmullRom)

          LineMark(
            x: .value("Date", dataPoint.date),
            y: .value("Temp", dataPoint.localizedTemperature)
          )
          .foregroundStyle(Color.mutedPurple)
          .lineStyle(StrokeStyle(lineWidth: 3))
          .interpolationMethod(.catmullRom)
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
              .foregroundStyle(.secondary.opacity(0.3))
            if let temp = value.as(Double.self) {
              AxisValueLabel {
                Text(formatTemperature(temp))
                  .font(.caption2)
              }
            }
          }
        }
        .chartYScale(domain: tempChartYDomain)
        .chartXScale(domain: tempChartXDomain)
        .frame(height: 200)
      }
      .cardContainer(includePadding: false)

      DetailInfoCardView {
        Text("Wrist temperature is measured during sleep and can vary based on your environment, menstrual cycle, illness, and other factors. Tracking changes over time may help identify patterns in your health.")
      }
    }
  }

  var tempChartXDomain: ClosedRange<Date> {
    guard let minDate = temperatureDataPoints.map(\.date).min(),
          let maxDate = temperatureDataPoints.map(\.date).max() else {
      return Date()...Date()
    }
    return minDate...maxDate
  }

  var tempChartYDomain: ClosedRange<Double> {
    let localizedTemps = temperatureDataPoints.map(\.localizedTemperature)
    guard let minTemp = localizedTemps.min(),
          let maxTemp = localizedTemps.max() else {
      return 96...100
    }

    let padding = max((maxTemp - minTemp) * 0.2, 0.5)
    return (minTemp - padding)...(maxTemp + padding)
  }

  func formatTemperature(_ value: Double) -> String {
    let unit = UnitTemperature(forLocale: .current).symbol
    return "\(value.format(using: .oneDecimalPlace))\(unit)"
  }
}

// MARK: - Respiratory Rate Chart

private extension SleepMetricsDetailsView {

  var averageRespRate: Double? {
    guard respiratoryDataPoints.isNotEmpty else { return nil }
    let total = respiratoryDataPoints.map(\.rate).reduce(0, +)
    return total / Double(respiratoryDataPoints.count)
  }

  var formattedAverageRespRate: String? {
    guard let avg = averageRespRate else { return nil }
    return "\(Int(avg.rounded())) breaths/min avg"
  }

  var respiratoryRateChartSection: some View {
    VStack(alignment: .leading) {
      VStack {
        VitalDetailChartTitleView(
          title: "Respiratory Rate",
          value: formattedAverageRespRate ?? ""
        )
        .padding(.horizontal)
        .padding(.top)

        Chart(respiratoryDataPoints) { dataPoint in
          AreaMark(
            x: .value("Date", dataPoint.date),
            y: .value("Rate", dataPoint.rate)
          )
          .foregroundStyle(
            LinearGradient(
              colors: [Color.mutedLightBlue.opacity(0.4), Color.mutedLightBlue.opacity(0.05)],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .interpolationMethod(.catmullRom)

          LineMark(
            x: .value("Date", dataPoint.date),
            y: .value("Rate", dataPoint.rate)
          )
          .foregroundStyle(Color.mutedLightBlue)
          .lineStyle(StrokeStyle(lineWidth: 3))
          .interpolationMethod(.catmullRom)
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
              .foregroundStyle(.secondary.opacity(0.3))
            if let rate = value.as(Double.self) {
              AxisValueLabel {
                Text("\(Int(rate))")
                  .font(.caption2)
              }
            }
          }
        }
        .chartYScale(domain: respChartYDomain)
        .chartXScale(domain: respChartXDomain)
        .frame(height: 200)
      }
      .cardContainer(includePadding: false)

      DetailInfoCardView {
        Text("Respiratory rate during sleep typically ranges from 12-20 breaths per minute for adults. Changes in your respiratory rate may indicate illness, stress, or changes in fitness level.")
      }
    }
  }

  var respChartXDomain: ClosedRange<Date> {
    guard let minDate = respiratoryDataPoints.map(\.date).min(),
          let maxDate = respiratoryDataPoints.map(\.date).max() else {
      return Date()...Date()
    }
    return minDate...maxDate
  }

  var respChartYDomain: ClosedRange<Double> {
    let rates = respiratoryDataPoints.map(\.rate)
    guard let minRate = rates.min(),
          let maxRate = rates.max() else {
      return 10...20
    }

    let padding = max((maxRate - minRate) * 0.2, 2)
    return max(0, minRate - padding)...(maxRate + padding)
  }
}

// MARK: - Data Models

private struct SleepHRDataPoint: Identifiable {
  let date: Date
  let heartRate: Double

  var id: Date { date }
}

// MARK: - DateQuantitySample Extensions

private extension DateQuantitySample {

  var temperatureFahrenheit: Double {
    quantity.doubleValue(for: .degreeFahrenheit())
  }

  var localizedTemperature: Double {
    let fahrenheit = quantity.doubleValue(for: .degreeFahrenheit())
    let measurement = Measurement(value: fahrenheit, unit: UnitTemperature.fahrenheit)
    return measurement.localizedValue
  }

  var rate: Double {
    quantity.doubleValue(for: .breathsPerMinute())
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      SleepMetricsDetailsView()
    }
  }
}
