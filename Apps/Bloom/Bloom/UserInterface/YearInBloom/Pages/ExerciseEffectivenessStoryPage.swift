//
//  ExerciseEffectivenessStoryPage.swift
//  Bloom
//
//  Created by Claude on 2025-12-18.
//

import SwiftUI
import Charts
import CoreHealth
import BloomUI
import SFSafeSymbols

struct ExerciseEffectivenessStoryPage: View {
  let stats: YearInBloomWorkoutStats

  @State private var selectedMonth: MonthlyZoneMinutesData?
  @State private var rawSelectedDate: Date?
  @State private var selectedWorkoutType: WorkoutTypeStats?

  var body: some View {
    VStack {
      zoneMinutesChart

      legendView

      workoutTypesSection
        .padding(.top)

      Spacer()

      Image(systemSymbol: .flameFill)
        .foregroundStyle(.tint)
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

      statsGrid
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        titleView
      }
    }
    .padding(.horizontal)
    .padding(.top)
    .tint(.mutedOrange)
  }

  private var focusSentence: Text {
    let zoneMinutes = Text(formattedZoneMinutes).foregroundStyle(.tint)

    return Text(
      "You earned \(zoneMinutes) zone minutes this year!",
      comment: "Year in Bloom exercise summary. The placeholder is a number of heart rate zone minutes."
    )
  }
}

// MARK: - Title & Chart

private extension ExerciseEffectivenessStoryPage {

  var titleView: some View {
    Text("Heart Rate Zones")
      .font(.title3)
      .fontDesign(.rounded)
      .bold()
  }

  var legendView: some View {
    HStack(spacing: 12) {
      zoneLegendItem(color: .heartRateZone1, label: "Zone 1")
      zoneLegendItem(color: .heartRateZone2, label: "Zone 2")
      zoneLegendItem(color: .heartRateZone3, label: "Zone 3")
      zoneLegendItem(color: .heartRateZone4, label: "Zone 4")
      zoneLegendItem(color: .heartRateZone5, label: "Zone 5")
      Spacer()
    }
    .font(.caption2)
    .fontDesign(.rounded)
  }

  func zoneLegendItem(color: Color, label: String) -> some View {
    HStack(spacing: 4) {
      Circle()
        .fill(color)
        .frame(width: 8, height: 8)
      Text(label)
        .foregroundStyle(.secondary)
    }
  }

  var zoneMinutesChart: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(selectedWorkoutType?.activityName ?? "All Workouts")
        .font(.caption)
        .foregroundStyle(.secondary)
        .contentTransition(.numericText())

      Chart {
        ForEach(filteredMonthlyData) { month in
          BarMark(
            x: .value("Month", month.date, unit: .month),
            y: .value("Minutes", month.zone1)
          )
          .foregroundStyle(Color.heartRateZone1)

          BarMark(
            x: .value("Month", month.date, unit: .month),
            y: .value("Minutes", month.zone2)
          )
          .foregroundStyle(Color.heartRateZone2)

          BarMark(
            x: .value("Month", month.date, unit: .month),
            y: .value("Minutes", month.zone3)
          )
          .foregroundStyle(Color.heartRateZone3)

          BarMark(
            x: .value("Month", month.date, unit: .month),
            y: .value("Minutes", month.zone4)
          )
          .foregroundStyle(Color.heartRateZone4)

          BarMark(
            x: .value("Month", month.date, unit: .month),
            y: .value("Minutes", month.zone5)
          )
          .foregroundStyle(Color.heartRateZone5)

          if month.total >= 600 {
            PointMark(
              x: .value("Month", month.date, unit: .month),
              y: .value("Minutes", month.total)
            )
            .symbol {
              Image(systemSymbol: .starFill)
                .font(.system(size: 8))
                .foregroundStyle(.mutedYellow)
            }
            .offset(y: -12)
          }
        }
      }
      .chartXAxis {
        AxisMarks(values: .stride(by: .month)) { _ in
          AxisValueLabel(format: .dateTime.month(.narrow), centered: true)
            .foregroundStyle(.secondary)
        }
      }
      .chartYAxis(.hidden)
      .chartYScale(domain: 0...chartYMax)
      .chartLegend(.hidden)
      .chartXSelection(value: $rawSelectedDate)
      .frame(height: 180)
      .sensoryFeedback(.selection, trigger: selectedMonth)
      .chartOverlay { proxy in
        GeometryReader { _ in
          if let selected = selectedMonth,
             let xPosition = proxy.position(forX: selected.date) {
            Text("\(Int(selected.total)) min")
              .font(.caption)
              .fontWeight(.semibold)
              .fontDesign(.rounded)
              .padding(.horizontal, 12)
              .padding(.vertical, 4)
              .background(.regularMaterial, in: Capsule())
              .position(x: xPosition, y: 0)
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
    }
  }
}

// MARK: - Stats Grid

private extension ExerciseEffectivenessStoryPage {

  var statsGrid: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
      favouriteZoneCard
      starMonthsCard
    }
  }

  @ViewBuilder
  var favouriteZoneCard: some View {
    if let favourite = favouriteZone {
      HStack {
        Image(systemName: symbolNameForZone(favourite.zone))
          .foregroundStyle(.white, colorForZone(favourite.zone))
          .font(.title2)
        VStack(alignment: .leading, spacing: 0) {
          Text("Zone \(favourite.zone)")
            .font(.title3)
            .bold()
          Text("Favourite Zone")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer()
      }
      .cardContainer(fill: .background.secondary)
    }
  }

  var starMonthsCard: some View {
    HStack {
      Image(systemSymbol: .starFill)
        .foregroundStyle(.mutedYellow)
        .font(.title2)
      VStack(alignment: .leading, spacing: 0) {
        Text("\(starMonthsCount)")
          .font(.title3)
          .bold()
        Text("> 600m Months")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
    }
    .cardContainer(fill: .background.secondary)
  }
}

// MARK: - Workout Types

private extension ExerciseEffectivenessStoryPage {

  var topWorkoutTypes: [WorkoutTypeStats] {
    Array(stats.topWorkoutTypes.prefix(6))
  }

  var workoutTypesSection: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
      ForEach(topWorkoutTypes) { workoutType in
        workoutTypeRow(for: workoutType)
      }
    }
  }

  @ViewBuilder
  func workoutTypeRow(for workoutType: WorkoutTypeStats) -> some View {
    let isSelected = selectedWorkoutType?.id == workoutType.id

    HStack {
      Image(systemName: workoutType.activityType.systemImage)
        .frame(width: 24)
      Text("×\(workoutType.count)")
      Spacer(minLength: 0)
      Text("\(Int(workoutType.scaledZoneMinutes)) min")
    }
    .foregroundStyle(isSelected ? .invertedText : .text)
    .font(.subheadline)
    .fontDesign(.rounded)
    .bold()
    .padding(.horizontal, 12)
    .padding(.vertical, 4)
    .background(isSelected ? AnyShapeStyle(.text) : AnyShapeStyle(.background.secondary), in: Capsule())
    .contentShape(Rectangle())
    .animation(.default, value: selectedWorkoutType)
    .sensoryFeedback(.selection, trigger: selectedWorkoutType)
    .onTapGesture {
      withAnimation {
        if selectedWorkoutType?.id == workoutType.id {
          selectedWorkoutType = nil
        } else {
          selectedWorkoutType = workoutType
        }
      }
    }
  }
}

// MARK: - Helpers

private extension ExerciseEffectivenessStoryPage {

  var favouriteZone: (zone: Int, minutes: Double)? {
    guard let zones = stats.yearTotals.totalZoneMinutes else { return nil }
    let zoneMinutes = [
      (1, zones.zone1Minutes),
      (2, zones.zone2Minutes),
      (3, zones.zone3Minutes),
      (4, zones.zone4Minutes),
      (5, zones.zone5Minutes)
    ]
    return zoneMinutes.max(by: { $0.1 < $1.1 })
  }

  func colorForZone(_ zone: Int) -> Color {
    switch zone {
    case 1: .heartRateZone1
    case 2: .heartRateZone2
    case 3: .heartRateZone3
    case 4: .heartRateZone4
    case 5: .heartRateZone5
    default: .gray
    }
  }

  func symbolNameForZone(_ zone: Int) -> String {
    switch zone {
    case 1: "1.circle.fill"
    case 2: "2.circle.fill"
    case 3: "3.circle.fill"
    case 4: "4.circle.fill"
    case 5: "5.circle.fill"
    default: "circle"
    }
  }

  var formattedZoneMinutes: String {
    let zoneMinutes = Int(stats.yearTotals.totalZoneMinutes?.scaledZoneMinutes ?? 0)
    return zoneMinutes.formatted()
  }

  var formattedHighIntensityMinutes: String {
    guard let zones = stats.yearTotals.totalZoneMinutes else { return "—" }
    let highIntensity = Int(zones.zone3Minutes + zones.zone4Minutes + zones.zone5Minutes)
    return "\(highIntensity.formatted()) min"
  }

  var starMonthsCount: Int {
    stats.monthlyScaledZoneMinutes().filter { $0.total >= 600 }.count
  }

  var filteredMonthlyData: [MonthlyZoneMinutesData] {
    if let selected = selectedWorkoutType {
      return stats.monthlyScaledZoneMinutes(for: selected)
    }
    return stats.monthlyScaledZoneMinutes()
  }

  var chartYMax: Double {
    let maxTotal = filteredMonthlyData.map(\.total).max() ?? 0
    return maxTotal + 50
  }

  func findNearestMonth(to date: Date) -> MonthlyZoneMinutesData? {
    let calendar = Calendar.current
    let targetMonth = calendar.component(.month, from: date)
    return filteredMonthlyData.first { data in
      calendar.component(.month, from: data.date) == targetMonth
    }
  }
}

#Preview {
  PreviewEnvironment {
    ExerciseEffectivenessStoryPage(stats: .preview)
  }
}
