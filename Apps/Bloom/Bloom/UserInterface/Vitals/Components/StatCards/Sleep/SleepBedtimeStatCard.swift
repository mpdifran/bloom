//
//  SleepBedtimeStatCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-29.
//

import SwiftUI
import Charts

struct SleepBedtimeStatCard: View {
  let data: BedtimeChartData?

  var body: some View {
    StatCard(
      symbol: .bedDoubleFill,
      title: "Bedtime",
      value: data?.trend.rawValue ?? "No Data",
      layerContent: true,
      includePadding: false
    ) {
      bedtimeChart
    }
    .tint(data == nil ? AnyShapeStyle(.gray) : AnyShapeStyle(.deepSleep))
  }
}

private extension SleepBedtimeStatCard {

  var nextHourLabel: String? {
    guard let data, let lastPoint = data.dataPoints.last else { return nil }

    // Un-negate to get actual minutes from midnight
    var minutes = -lastPoint.minutesFromMidnight

    // Handle times past midnight (values >= 1440)
    if minutes >= 1440 {
      minutes -= 1440
    }

    // Get current hour and round up to next hour
    let currentHour = Int(minutes / 60)
    let nextHour = (currentHour + 1) % 24

    // Convert to 12-hour format
    let hour12 = nextHour == 0 ? 12 : (nextHour > 12 ? nextHour - 12 : nextHour)
    let ampm = nextHour < 12 ? "AM" : "PM"

    return "\(hour12)\(ampm)"
  }

  @ViewBuilder
  var bedtimeChart: some View {
    if let data, data.dataPoints.count >= 2 {
      Chart {
        ForEach(data.dataPoints) { dataPoint in
          AreaMark(
            x: .value("Day", dataPoint.date),
            yStart: .value("Bottom", chartYDomain.lowerBound),
            yEnd: .value("Bedtime", dataPoint.minutesFromMidnight)
          )
          .interpolationMethod(.catmullRom)
          .foregroundStyle(.deepSleep.gradient)
        }

        if let lastPoint = data.dataPoints.last, let label = nextHourLabel {
          PointMark(
            x: .value("Day", lastPoint.date),
            y: .value("Bedtime", lastPoint.minutesFromMidnight)
          )
          .opacity(0)
          .annotation(position: .bottomLeading) {
            HStack(spacing: 4) {
              Text(label)
                .font(.subheadline)
                .bold()
                .fontDesign(.rounded)
                .foregroundStyle(.white)
              Capsule()
                .fill(.white)
                .frame(width: 8, height: 2)
            }
          }
        }
      }
      .chartXAxis(.hidden)
      .chartYAxis(.hidden)
      .chartXScale(domain: chartXDomain)
      .chartYScale(domain: chartYDomain)
      .padding(.top, 20)
    } else {
      Rectangle()
        .fill(.gray)
        .padding(.top, 20)
    }
  }

  var chartXDomain: ClosedRange<Date> {
    guard let data,
          let minDate = data.dataPoints.map(\.date).min(),
          let maxDate = data.dataPoints.map(\.date).max() else {
      return Date()...Date()
    }

    return minDate...maxDate
  }

  var chartYDomain: ClosedRange<Double> {
    // Values are negated, so:
    // -1260 = 9pm (top of chart, max value)
    // -1800 = 6am (bottom of chart, min value)
    let ninepm: Double = -1380
    let sixam: Double = -1800

    guard let data,
          let maxValue = data.dataPoints.map(\.minutesFromMidnight).max() else {
      return sixam...ninepm
    }

    // Use 9pm or the earliest bedtime (whichever is earlier/higher value)
    let topBound = max(maxValue, ninepm)

    return sixam...topBound
  }
}

#Preview {
  let calendar = Calendar.current

  PreviewEnvironment {
    BloomScrollView {
      HStack {
        SleepBedtimeStatCard(
          data: BedtimeChartData(
            dataPoints: [
              // Negated values: -1350 = 10:30pm, -1380 = 11pm, etc.
              BedtimeDataPoint(date: calendar.startOfDay(for: Date().addingTimeInterval(-6 * 86400)), minutesFromMidnight: -1350),
              BedtimeDataPoint(date: calendar.startOfDay(for: Date().addingTimeInterval(-5 * 86400)), minutesFromMidnight: -1380),
              BedtimeDataPoint(date: calendar.startOfDay(for: Date().addingTimeInterval(-4 * 86400)), minutesFromMidnight: -1365),
              BedtimeDataPoint(date: calendar.startOfDay(for: Date().addingTimeInterval(-3 * 86400)), minutesFromMidnight: -1395),
              BedtimeDataPoint(date: calendar.startOfDay(for: Date().addingTimeInterval(-2 * 86400)), minutesFromMidnight: -1350),
              BedtimeDataPoint(date: calendar.startOfDay(for: Date().addingTimeInterval(-1 * 86400)), minutesFromMidnight: -1380),
              BedtimeDataPoint(date: calendar.startOfDay(for: Date()), minutesFromMidnight: -1365)
            ],
            trend: .consistent
          )
        )
        SleepBedtimeStatCard(data: nil)
      }
    }
  }
}
