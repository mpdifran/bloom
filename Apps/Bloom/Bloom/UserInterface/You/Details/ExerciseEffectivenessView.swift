//
//  ExerciseEffectivenessView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-20.
//

import SwiftUI
import AppUI
import Charts
import TelemetryDeck
import CoreHealth
import SFSafeSymbols

struct ZoneMinutesDataPoint: Identifiable {
  var id: Date { date }
  let date: Date
  let zone1: Double
  let zone2: Double
  let zone3: Double
  let zone4: Double
  let zone5: Double

  var total: Double { zone1 + zone2 + zone3 + zone4 + zone5 }
}

struct ExerciseEffectivenessView: View {
  @State private var selectedPeriod: StatTimePeriod = .sevenDays
  @State private var exerciseData: ExerciseEffectivenessMonthlySummary.Details?
  @State private var zoneMinutesData: [ZoneMinutesDataPoint] = []
  @State private var isLoading = false
  @State private var presentedSheet: AnyView?

  var body: some View {
    BloomScrollView(spacing: 20) {
      StatTimePeriodPicker(selectedPeriod: $selectedPeriod)

      if exerciseData?.hasNoData == false {
        contentView
      } else {
        emptyView
      }
    }
    .task(id: selectedPeriod) {
      await loadData()
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        VitalSummaryDetailTitleView(
          title: "Exercise Effectiveness",
          subtitle: selectedPeriod.displayName
        )
      }
      ToolbarItem(placement: .primaryAction) {
        Button {
          presentedSheet =
          NavigationStack {
            HeartRateZoneSettingsView()
              .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                  DismissButton()
                }
              }
          }.asAny
        } label: {
          Label("Settings", systemSymbol: .sliderHorizontal3)
        }
        .buttonStyle(.plain)
      }
    }
    .sheet($presentedSheet)
    .onChange(of: presentedSheet == nil) { _, isDismissed in
      if isDismissed {
        Task { await loadData() }
      }
    }
    .navigationTitle("Exercise Effectiveness")
    .navigationBarTitleDisplayMode(.inline)
    .animation(.default, value: isLoading)
    .animation(.default, value: zoneMinutesData.map(\.id))
    .onAppear {
      TelemetryDeck.viewScreen("Exercise Effectiveness Vital Details")
    }
  }
}

private extension ExerciseEffectivenessView {

  @ViewBuilder
  var zoneMinutesChart: some View {
    if zoneMinutesData.isNotEmpty {
      VStack(alignment: .leading, spacing: 8) {
        Chart {
          ForEach(zoneMinutesData) { point in
            BarMark(
              x: .value("Date", point.date, unit: selectedPeriod.aggregatesByWeek ? .weekOfYear : .day),
              y: .value("Minutes", point.zone1)
            )
            .foregroundStyle(Color.heartRateZone1)

            BarMark(
              x: .value("Date", point.date, unit: selectedPeriod.aggregatesByWeek ? .weekOfYear : .day),
              y: .value("Minutes", point.zone2)
            )
            .foregroundStyle(Color.heartRateZone2)

            BarMark(
              x: .value("Date", point.date, unit: selectedPeriod.aggregatesByWeek ? .weekOfYear : .day),
              y: .value("Minutes", point.zone3)
            )
            .foregroundStyle(Color.heartRateZone3)

            BarMark(
              x: .value("Date", point.date, unit: selectedPeriod.aggregatesByWeek ? .weekOfYear : .day),
              y: .value("Minutes", point.zone4)
            )
            .foregroundStyle(Color.heartRateZone4)

            BarMark(
              x: .value("Date", point.date, unit: selectedPeriod.aggregatesByWeek ? .weekOfYear : .day),
              y: .value("Minutes", point.zone5)
            )
            .foregroundStyle(Color.heartRateZone5)
          }
        }
        .chartXAxis {
          AxisMarks(values: .automatic) { _ in
            AxisGridLine()
            AxisValueLabel(format: selectedPeriod.chartDateFormat)
          }
        }
        .chartYAxis {
          AxisMarks(position: .leading) { value in
            AxisGridLine()
            AxisValueLabel {
              if let minutes = value.as(Double.self) {
                Text("\(Int(minutes))m")
              }
            }
          }
        }
        .chartLegend(.hidden)
        .frame(height: 240)
      }
    }
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

  var loadingView: some View {
    VStack {
      Spacer()
      CircularSpinnerView()
      Spacer()
    }
    .horizontallyCentered()
    .groupedBackground()
  }

  @ViewBuilder
  var contentView: some View {
    zoneMinutesChart
      .cardContainer()

    VStack(alignment: .leading, spacing: 6) {
      targetHeartRateZonesChart
      HealthCitationLinkView(
        url: .adultActivityLevels,
        title: "Zone minute goals based on Physical Activity Guidelines by the CDC."
      )
      .padding(.horizontal)
    }

    workoutTypeSummary
  }

  var emptyView: some View {
    ContentUnavailableView(
      "No Data Available",
      systemImage: "figure.mixed.cardio",
      description: Text("Log a workout with your Apple Watch to get a better sense of your Exercise Effectiveness.")
    )
    .frame(height: 450)
  }

  @ViewBuilder
  var zoneSummary: some View {
    if let heartRateZones = exerciseData?.heartRateZones {

      VStack {
        HStack {
          VStack {
            Text("\(heartRateZones.maxHeartRate.format()) bpm")
              .font(.title2)
              .bold()
            Text("Max Heart Rate")
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          Spacer()

          Text("-")
            .bold()

          Spacer()

          VStack {
            Text("\(heartRateZones.restingHeartRate.format()) bpm")
              .font(.title2)
              .bold()
            Text("Resting Heart Rate")
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          Spacer()

          Text("=")
            .bold()

          Spacer()

          VStack {
            Text("\(heartRateZones.heartRateReserve.format()) bpm")
              .font(.title2)
              .bold()
            Text("Heart Rate Reserve")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        .multilineTextAlignment(.center)
        .padding(.bottom)

        Text("Heart rate reserve (HRR) is a measure used to calculate your target heart rate for various levels of exercise intensity.")
      }
      .cardContainer(fill: .background.secondary)
    }
  }

  @ViewBuilder
  var targetHeartRateZonesChart: some View {
    if let exerciseData {
      VStack(alignment: .leading) {
        VitalDetailChartTitleView(
          title: "Zone Minutes",
          value: ""
        )

        TargetHeartRateZonesDistributionView(
          distribution: exerciseData.overallHeartZoneDistribution,
          heartRateZones: exerciseData.heartRateZones,
          goal: selectedPeriod.zoneMinutesGoal
        )
      }
      .cardContainer()
    }
  }

  @ViewBuilder
  var workoutTypeSummary: some View {
    if let workoutTypeReports = exerciseData?.workoutTypeHeartRateReports {
      if workoutTypeReports.isNotEmpty {
        VStack {
          VitalDetailChartTitleView(title: "Workouts", value: "")
            .padding(.horizontal)

          ForEach(workoutTypeReports) { report in
            NavigationLink {
              WorkoutsListView(activityType: report.activityType)
            } label: {
              WorkoutHeartRateZoneCell(report: report)
                .cardContainer()
            }
            .buttonStyle(.plain)
          }
        }
      }
    }
  }
}

private extension ExerciseEffectivenessView {

  func loadData() async {
    isLoading = true
    defer { isLoading = false }

    let dateRange = selectedPeriod.dateRange

    guard let heartRateZones = await HealthStoreFetcher.shared.heartRateZones() else { return }
    exerciseData = await HealthStoreFetcher.shared.fetchExerciseEffectivenessDetails(
      heartRateZones: heartRateZones,
      dateRange: dateRange
    )

    zoneMinutesData = aggregateZoneMinutes()
  }

  func aggregateZoneMinutes() -> [ZoneMinutesDataPoint] {
    let reports = exerciseData?.workoutReports ?? []
    let calendar = Calendar.current
    let dateRange = selectedPeriod.dateRange
    let startDate = dateRange.start
    let endDate = dateRange.end

    if selectedPeriod.aggregatesByWeek {
      // Group workout data by week
      var weeklyData = [Date: (z1: Double, z2: Double, z3: Double, z4: Double, z5: Double)]()
      for report in reports {
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: report.workout.startDate)?.start ?? report.workout.startDate
        let dist = report.heartZoneDistribution
        let existing = weeklyData[weekStart] ?? (0, 0, 0, 0, 0)
        weeklyData[weekStart] = (
          existing.z1 + dist.zone1.doubleValue(for: .minute()) * .zone12Multiplier,
          existing.z2 + dist.zone2.doubleValue(for: .minute()) * .zone12Multiplier,
          existing.z3 + dist.zone3.doubleValue(for: .minute()) * .zone34Multiplier,
          existing.z4 + dist.zone4.doubleValue(for: .minute()) * .zone34Multiplier,
          existing.z5 + dist.zone5.doubleValue(for: .minute()) * .zone5Multiplier
        )
      }

      // Generate all weeks in range
      var allWeeks = [Date]()
      var currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: startDate)?.start ?? startDate
      while currentWeekStart <= endDate {
        allWeeks.append(currentWeekStart)
        currentWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart) ?? currentWeekStart
      }

      return allWeeks.map { weekStart in
        let data = weeklyData[weekStart] ?? (0, 0, 0, 0, 0)
        return ZoneMinutesDataPoint(
          date: weekStart,
          zone1: data.z1,
          zone2: data.z2,
          zone3: data.z3,
          zone4: data.z4,
          zone5: data.z5
        )
      }
    } else {
      // Group workout data by day
      var dailyData = [Date: (z1: Double, z2: Double, z3: Double, z4: Double, z5: Double)]()
      for report in reports {
        let day = calendar.startOfDay(for: report.workout.startDate)
        let dist = report.heartZoneDistribution
        let existing = dailyData[day] ?? (0, 0, 0, 0, 0)
        dailyData[day] = (
          existing.z1 + dist.zone1.doubleValue(for: .minute()) * .zone12Multiplier,
          existing.z2 + dist.zone2.doubleValue(for: .minute()) * .zone12Multiplier,
          existing.z3 + dist.zone3.doubleValue(for: .minute()) * .zone34Multiplier,
          existing.z4 + dist.zone4.doubleValue(for: .minute()) * .zone34Multiplier,
          existing.z5 + dist.zone5.doubleValue(for: .minute()) * .zone5Multiplier
        )
      }

      // Generate all days in range
      var allDays = [Date]()
      var currentDay = calendar.startOfDay(for: startDate)
      let endDay = calendar.startOfDay(for: endDate)
      while currentDay <= endDay {
        allDays.append(currentDay)
        currentDay = calendar.date(byAdding: .day, value: 1, to: currentDay) ?? currentDay
      }

      return allDays.map { day in
        let data = dailyData[day] ?? (0, 0, 0, 0, 0)
        return ZoneMinutesDataPoint(
          date: day,
          zone1: data.z1,
          zone2: data.z2,
          zone3: data.z3,
          zone4: data.z4,
          zone5: data.z5
        )
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      ExerciseEffectivenessView()
    }
  }
}
