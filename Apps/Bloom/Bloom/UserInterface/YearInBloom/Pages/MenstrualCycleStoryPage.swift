//
//  MenstrualCycleStoryPage.swift
//  Bloom
//
//  Created by Claude on 2025-12-18.
//

import SwiftUI
import Charts
import CoreHealth
import BloomUI
import SFSafeSymbols

struct MenstrualCycleStoryPage: View {
  let stats: YearInBloomMenstrualStats

  @State private var rawSelectedDate: Date?
  @State private var selectedMonth: MonthlyPhaseActivityData?

  var body: some View {
    VStack {
      Spacer()

      activityChart

      Spacer()

      Image(systemSymbol: .circleDottedAndCircle)
        .foregroundStyle(.mutedPurple)
        .font(.system(size: 50))
        .contentTransition(.symbolEffect)
        .padding(.bottom)

      focusSentence
        .font(.title)
        .fontWeight(.bold)
        .fontDesign(.rounded)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)

      Spacer()

      cycleStatsGrid
    }
    .ignoresSafeArea(edges: [.horizontal])
    .toolbar {
      ToolbarItem(placement: .principal) {
        titleView
      }
    }
  }

  private var focusSentence: Text {
    Text("Your average cycle was ") +
    Text("\(Int(stats.averageCycleDuration)) days")
      .foregroundStyle(.mutedPurple) +
    Text(" long.")
  }
}

// MARK: - Title & Chart

private extension MenstrualCycleStoryPage {

  var titleView: some View {
    Text("Cycle Insights")
      .font(.title3)
      .fontDesign(.rounded)
      .bold()
  }

  var activityChart: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Activity Level")
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 24)

      Chart {
        ForEach(monthlyActivityWithValues) { data in
          if let follicular = data.follicularActivityLevel {
            LineMark(
              x: .value("Month", data.date),
              y: .value("Activity", follicular),
              series: .value("Phase", "Follicular")
            )
            .foregroundStyle(Color.mutedPurple)
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 2))

            PointMark(
              x: .value("Month", data.date),
              y: .value("Activity", follicular)
            )
            .foregroundStyle(Color.mutedPurple)
            .symbolSize(30)
          }

          if let other = data.otherActivityLevel {
            LineMark(
              x: .value("Month", data.date),
              y: .value("Activity", other),
              series: .value("Phase", "Other")
            )
            .foregroundStyle(Color.mutedPurple.opacity(0.4))
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))

            PointMark(
              x: .value("Month", data.date),
              y: .value("Activity", other)
            )
            .foregroundStyle(Color.mutedPurple.opacity(0.4))
            .symbolSize(20)
          }
        }
      }
      .chartXScale(domain: yearStart...yearEnd)
      .chartYScale(domain: activityMin...activityMax)
      .chartXAxis {
        AxisMarks(values: .stride(by: .month)) { _ in
          AxisValueLabel(format: .dateTime.month(.narrow), centered: true)
        }
      }
      .chartYAxis {
        AxisMarks { value in
          AxisGridLine()
          AxisValueLabel {
            if let activity = value.as(Double.self) {
              Text(String(format: "%.0f%%", activity * 100))
                .font(.caption2)
            }
          }
        }
      }
      .chartLegend(.hidden)
      .chartXSelection(value: $rawSelectedDate)
      .frame(height: 220)
      .padding(.horizontal, 24)
      .sensoryFeedback(.selection, trigger: selectedMonth)
      .chartOverlay { proxy in
        GeometryReader { geometry in
          if let selectedMonth, let xPosition = proxy.position(forX: selectedMonth.date) {
            activityOverlay(for: selectedMonth)
              .position(x: min(max(xPosition, 60), geometry.size.width - 60), y: 0)
          }
        }
      }
      .onChange(of: rawSelectedDate) { _, newValue in
        if let date = newValue {
          selectedMonth = findNearestMonth(to: date)
        } else {
          selectedMonth = nil
        }
      }

      HStack(spacing: 16) {
        HStack(spacing: 4) {
          Circle()
            .fill(Color.mutedPurple)
            .frame(width: 8, height: 8)
          Text("Follicular Phase")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        HStack(spacing: 4) {
          Circle()
            .fill(Color.mutedPurple.opacity(0.4))
            .frame(width: 8, height: 8)
          Text("Baseline")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
      .padding(.horizontal, 24)
    }
  }

  @ViewBuilder
  func activityOverlay(for month: MonthlyPhaseActivityData) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("\(monthName(for: month.date))")
        .font(.caption)
        .bold()

      if let follicular = month.follicularActivityLevel {
        HStack(spacing: 4) {
          Circle()
            .fill(Color.mutedPurple)
            .frame(width: 8, height: 8)
          Text("Follicular: \(String(format: "%.0f%%", follicular * 100))")
            .font(.caption2)
        }
      }

      if let other = month.otherActivityLevel {
        HStack(spacing: 4) {
          Circle()
            .fill(Color.mutedPurple.opacity(0.4))
            .frame(width: 8, height: 8)
          Text("Baseline: \(String(format: "%.0f%%", other * 100))")
            .font(.caption2)
        }
      }
    }
    .padding(8)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
  }
}

// MARK: - Stats Grid

private extension MenstrualCycleStoryPage {

  var cycleStatsGrid: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
      cycleRangeCard
      periodLengthCard
      heartRateCard
      sleepEfficiencyCard
    }
    .padding(.horizontal)
  }

  var cycleRangeCard: some View {
    HStack {
      Image(systemSymbol: .calendar)
        .foregroundStyle(.mutedPurple)
        .font(.title2)
      VStack(alignment: .leading, spacing: 0) {
        if let shortest = stats.shortestCycle, let longest = stats.longestCycle {
          Text("\(shortest.duration)-\(longest.duration) days")
            .font(.title3)
            .bold()
        } else {
          Text("—")
            .font(.title3)
            .bold()
        }
        Text("Cycle Range")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
    }
    .cardContainer(fill: .background.secondary)
  }

  var periodLengthCard: some View {
    HStack {
      Image(systemSymbol: .dropFill)
        .foregroundStyle(.mutedPurple)
        .font(.title2)
      VStack(alignment: .leading, spacing: 0) {
        if let length = stats.averagePeriodLength {
          Text(String(format: "%.1f days", length))
            .font(.title3)
            .bold()
        } else {
          Text("—")
            .font(.title3)
            .bold()
        }
        Text("Avg Period")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
    }
    .cardContainer(fill: .background.secondary)
  }

  var heartRateCard: some View {
    HStack {
      Image(systemSymbol: .heartFill)
        .foregroundStyle(.mutedPurple)
        .font(.title2)
      VStack(alignment: .leading, spacing: 0) {
        if let change = stats.lutealRestingHRChange {
          Text("\(change >= 0 ? "+" : "")\(String(format: "%.1f", change)) bpm")
            .font(.title3)
            .bold()
        } else {
          Text("—")
            .font(.title3)
            .bold()
        }
        Text("Luteal HR")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
    }
    .cardContainer(fill: .background.secondary)
  }

  var sleepEfficiencyCard: some View {
    HStack {
      Image(systemSymbol: .moonFill)
        .foregroundStyle(.mutedPurple)
        .font(.title2)
      VStack(alignment: .leading, spacing: 0) {
        if let change = stats.lutealSleepEfficiencyChange {
          Text("\(change >= 0 ? "+" : "")\(String(format: "%.1f", change))%")
            .font(.title3)
            .bold()
        } else {
          Text("—")
            .font(.title3)
            .bold()
        }
        Text("Luteal Sleep")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
    }
    .cardContainer(fill: .background.secondary)
  }
}

// MARK: - Helpers

private extension MenstrualCycleStoryPage {

  var yearStart: Date {
    Calendar.current.date(from: DateComponents(year: stats.year, month: 1, day: 1))!
  }

  var yearEnd: Date {
    Calendar.current.date(from: DateComponents(year: stats.year + 1, month: 1, day: 1))!
  }

  var monthlyActivityWithValues: [MonthlyPhaseActivityData] {
    stats.monthlyPhaseActivityData.filter {
      $0.follicularActivityLevel != nil || $0.otherActivityLevel != nil
    }
  }

  var activityMin: Double {
    let allValues = stats.monthlyPhaseActivityData.flatMap {
      [$0.follicularActivityLevel, $0.otherActivityLevel].compactMap { $0 }
    }
    return (allValues.min() ?? 0.2) - 0.05
  }

  var activityMax: Double {
    let allValues = stats.monthlyPhaseActivityData.flatMap {
      [$0.follicularActivityLevel, $0.otherActivityLevel].compactMap { $0 }
    }
    return (allValues.max() ?? 0.5) + 0.05
  }

  func findNearestMonth(to date: Date) -> MonthlyPhaseActivityData? {
    let calendar = Calendar.current
    let targetMonth = calendar.component(.month, from: date)
    return stats.monthlyPhaseActivityData.first { data in
      calendar.component(.month, from: data.date) == targetMonth
    }
  }

  func monthName(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM"
    return formatter.string(from: date)
  }
}

#Preview {
  PreviewEnvironment {
    MenstrualCycleStoryPage(stats: .preview)
  }
}
