//
//  BloodPressureDetailsView.swift
//  Bloom
//
//  Created by Claude on 2026-01-09.
//

import SwiftUI
import Charts
import TelemetryDeck
import CoreHealth

struct BloodPressureDetailsView: View {

  @State private var selectedPeriod: StatTimePeriod = .oneMonth
  @State private var bpData: BloodPressureDetailData?
  @State private var previousPeriodData: BloodPressureDetailData?

  var body: some View {
    BloomScrollView(spacing: 20) {
      StatTimePeriodPicker(selectedPeriod: $selectedPeriod)

      if let bpData {
        BloodPressureStatusView(
          systolic: bpData.averageSystolic,
          diastolic: bpData.averageDiastolic,
          lastMonthSystolic: previousPeriodData?.averageSystolic,
          lastMonthDiastolic: previousPeriodData?.averageDiastolic
        )

        timelineChartSection

        averageSummarySection

        DetailInfoCardView {
          Text("Blood pressure is recorded as two numbers: systolic (pressure when heart beats) over diastolic (pressure between beats). Normal blood pressure is below 120/80 mmHg.")
        }
      } else {
        emptyView
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        VitalSummaryDetailTitleView(
          title: "Blood Pressure",
          subtitle: selectedPeriod.displayName
        )
      }
    }
    .navigationTitle("Blood Pressure")
    .navigationBarTitleDisplayMode(.inline)
    .animation(.default, value: bpData?.readings.map(\.id))
    .task(id: selectedPeriod) {
      await loadData()
    }
    .onAppear {
      TelemetryDeck.viewScreen("Blood Pressure Details")
    }
  }
}

private extension BloodPressureDetailsView {

  func loadData() async {
    async let currentData = YouStatsCalculator.shared.calculateBloodPressureForPeriod(selectedPeriod)
    async let previousData = YouStatsCalculator.shared.calculateBloodPressureForPreviousPeriod(selectedPeriod)

    let (current, previous) = await (currentData, previousData)
    bpData = current
    previousPeriodData = previous
  }

  var emptyView: some View {
    ContentUnavailableView(
      "No Data Available",
      systemImage: "heart.text.square",
      description: Text("Blood pressure readings can be added manually in the Health app or synced from a compatible blood pressure monitor.")
    )
  }

  // MARK: - Timeline Chart Section

  @ViewBuilder
  var timelineChartSection: some View {
    if let _ = bpData {
      VStack(alignment: .leading) {
        VStack {
          VitalDetailChartTitleView(
            title: "Timeline",
            value: ""
          )

          bpChart
            .frame(height: 250)

          chartLegend
        }
        .cardContainer()
      }
    }
  }

  @ViewBuilder
  var bpChart: some View {
    if let bpData {
      let categoryColor = bpData.category.color

      Chart {
        // Normal range reference area (90-120 systolic, 60-80 diastolic)
        RectangleMark(
          xStart: nil,
          xEnd: nil,
          yStart: .value("Lower", 60),
          yEnd: .value("Upper", 120)
        )
        .foregroundStyle(Color.mutedGreen.opacity(0.1))

        // Reference lines for normal thresholds
        RuleMark(y: .value("Normal Systolic", 120))
          .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
          .foregroundStyle(.secondary.opacity(0.5))

        RuleMark(y: .value("Normal Diastolic", 80))
          .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
          .foregroundStyle(.secondary.opacity(0.5))

        // Bar from diastolic to systolic
        ForEach(bpData.readings) { reading in
          BarMark(
            x: .value("Date", reading.date),
            yStart: .value("Diastolic", reading.diastolic),
            yEnd: .value("Systolic", reading.systolic)
          )
          .foregroundStyle(categoryColor)
          .clipShape(RoundedRectangle(cornerRadius: 4))
        }
      }
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
            if let bp = value.as(Double.self) {
              Text("\(Int(bp))")
            }
          }
        }
      }
      .chartYScale(domain: chartYDomain)
      .chartLegend(.hidden)
    }
  }

  var chartYDomain: ClosedRange<Double> {
    guard let bpData else { return 40...180 }

    let allValues = bpData.readings.flatMap { [$0.systolic, $0.diastolic] }
    guard let minVal = allValues.min(), let maxVal = allValues.max() else {
      return 40...180
    }

    let padding = (maxVal - minVal) * 0.15
    return max(40, minVal - padding)...min(200, maxVal + padding)
  }

  var chartLegend: some View {
    HStack(spacing: 20) {
      HStack(spacing: 6) {
        RoundedRectangle(cornerRadius: 2)
          .fill(bpData?.category.color ?? .gray)
          .frame(width: 8, height: 16)
        Text("Systolic / Diastolic")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()

      HStack(spacing: 6) {
        Rectangle()
          .fill(Color.mutedGreen.opacity(0.3))
          .frame(width: 12, height: 8)
        Text("Normal Range")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.top, 8)
  }

  // MARK: - Average Summary Section

  @ViewBuilder
  var averageSummarySection: some View {
    if let bpData {
      VStack {
        VitalDetailChartTitleView(
          title: "Period Average",
          value: ""
        )

        HStack(spacing: 20) {
          VStack {
            Text("\(Int(bpData.averageSystolic))")
              .font(.largeTitle)
              .bold()
              .fontDesign(.rounded)
            Text("Systolic")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity)

          Text("/")
            .font(.title)
            .foregroundStyle(.secondary)

          VStack {
            Text("\(Int(bpData.averageDiastolic))")
              .font(.largeTitle)
              .bold()
              .fontDesign(.rounded)
            Text("Diastolic")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)

        Text("mmHg")
          .font(.caption)
          .foregroundStyle(.tertiary)
      }
      .cardContainer()
    }
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      BloodPressureDetailsView()
    }
  }
}
