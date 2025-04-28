//
//  GoodMorningView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-12.
//

import SFSafeSymbols
import SwiftUI
import AppUI
import AppFoundations
@preconcurrency import EventKit
import EventKitUI
@preconcurrency import WeatherKit
import Charts
import DataContainer
import SwiftData
import CoreLocation

@MainActor
struct GoodMorningView: View {

  @Environment(\.dismiss) private var dismiss

  @ObservedObject private var healthManager = HealthManager.shared
  private let vitalsViewModel = VitalsViewModel.shared

  @State private var events = [EKEvent]()
  @State private var selectedEvent: EKEvent?
  @State private var locationLocality: String?
  @State private var weather: Weather?
  @State private var isLoadingWeather = false
  @State private var showSleepTodayView = false
  @State private var showMenstruationDetails = false
  @State private var sleepAnalysis: SleepAnalysis?

  @State private var incompleteTargetMetrics = Set<TargetMetric>()

  private var locationViewModel = LocationManagerViewModel.shared

  @Query var activeHabits: [Habit]

  private let randomMenstrualCyclePhaseFactIndex = Int.random(in: 0..<6)

  init() {
    _activeHabits = Query(
      filter: #Predicate<Habit> { habit in
        habit.endDate == nil
      },
      sort: \Habit.startDate,
      order: .reverse
    )
  }

  var body: some View {
    NavigationStack {
      List {
        currentDateSection
          .removeListSeparator()
        sleepSection
        projectedPeriodSection
        focusAreasSection
        activityLevelSection
        menstrualCycleSection
        weatherSection
        calendarSection
      }
      .navigationTitle("Morning Report")
      .listStyle(.plain)
      .shelf {
        Button(action: {
          dismiss()
        }, label: {
          Text("Done")
            .horizontallyCentered()
        })
        .buttonStyle(.primary)
      }
      .navigationDestination(isPresented: $showSleepTodayView) {
        SleepDayView()
      }
      .navigationDestination(isPresented: $showMenstruationDetails) {
        MenstruationDetailView()
      }
    }
    .sheet(item: $selectedEvent) { event in
      EKEventView(event: event)
    }
    .presentationCompactAdaptation(.fullScreenCover)
    .tint(.orange)
    .animation(.default, value: sleepAnalysis)
    .animation(.default, value: events.count)
    .animation(.default, value: weather)
    .task {
      locationViewModel.requestAuth()
      locationViewModel.requestLocation()
      await loadWeather()
    }
    .onChange(of: locationViewModel.currentLocation) { oldValue, newValue in
      if oldValue == nil, newValue != nil {
        Task {
          await loadWeather()
        }
      }
    }
    .onChange(of: locationViewModel.auth) { (_, newValue) in
      switch newValue {
      case .authorizedAlways, .authorizedWhenInUse:
        locationViewModel.requestLocation()
      default:
        break
      }
    }
    .task {
      await CalendarManager.shared.promptForPermission()
      self.events = await CalendarManager.shared.eventsToday()
    }
    .task {
      await calculateHabitCompletion()
    }
    .task {
      let sleepAnalysis = await HealthStoreFetcher.shared.fetchSleepAnalysis(for: .now)
      await MainActor.run {
        self.sleepAnalysis = sleepAnalysis
      }
    }
  }
}

private extension GoodMorningView {

  func loadWeather() async {
    guard
      let location = locationViewModel.currentLocation,
      weather == nil
    else { return }

    await MainActor.run {
      isLoadingWeather = true
    }

    let weather = await WeatherForecaster.shared.forecastedWeather(location: location)
    let locality = await locationViewModel.locality(for: location)

    await MainActor.run {
      self.weather = weather
      self.locationLocality = locality
      self.isLoadingWeather = false
    }
  }
}

private extension GoodMorningView {

  @ViewBuilder
  var currentDateSection: some View {
    TodaysDateView()
  }

  var sleepSection: some View {
    Section("Sleep Score") {
      if let sleepAnalysis {
        HStack(alignment: .top) {
          VStack(alignment: .leading) {
            Text("Summary")
              .font(.title3)
              .bold()

            Text(sleepAnalysis.sleepSummaryDescription)
              .font(.subheadline)
              .foregroundStyle(.secondary)

            Spacer(minLength: 0)
          }

          Spacer(minLength: 0)

          SleepScoreView(sleepAnalysis: sleepAnalysis, isMini: true)
        }
        .contentShape(Rectangle())
        .onTapGesture {
          showSleepTodayView = true
        }
      } else {
        Text("No Sleep Data")
          .font(.title3)
          .bold()
          .foregroundStyle(.secondary)
          .horizontallyCentered()
          .frame(height: 140)
          .standardListSeparatorInset()
      }
    }
  }

  @ViewBuilder
  var activityLevelSection: some View {
    if
      let energyRatioSample = vitalsViewModel.activityLevelSummary?.details.energyRatioSamples.last(where: { Calendar.current.isDateInYesterday($0.date) })
    {
      switch ActivityLevelSummary.ActivityLevel(energyRatioSample.value) {
      case .intense:
        Section("Activity Level") {
          HStack {
            Image(systemSymbol: SFSymbol(rawValue: VitalModel.Kind.activityLevel.systemImage))
              .font(.largeTitle)
              .foregroundStyle(.green)
              .frame(width: 50)

            VStack(alignment: .leading) {
              Text("Energy Ratio")
                .font(.title3)
                .bold()

              Text("Your Energy Ratio yesterday was in the Intense level (\(energyRatioSample.value.format(using: .oneDecimalPlace))). Make sure to take a break from activity today to give your body time to recover.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
          }
        }
      case .sedentary:
        if vitalsViewModel.activityLevelSummary?.details.hasSedentaryStreakLast3Days == true {
          Section("Activity Level") {
            HStack {
              Image(systemSymbol: SFSymbol(rawValue: VitalModel.Kind.activityLevel.systemImage))
                .font(.largeTitle)
                .foregroundStyle(.green)
                .frame(width: 50)

              VStack(alignment: .leading) {
                Text("Energy Ratio")
                  .font(.title3)
                  .bold()

                Text("Your Energy Ratio has been sedentary over the last 3 days. Today might be a good day to get active!")
                  .font(.subheadline)
                  .foregroundStyle(.secondary)
              }
              Spacer(minLength: 0)
            }
          }
        }
      default:
        EmptyView()
      }
    }
  }

  @ViewBuilder
  var projectedPeriodSection: some View {
    if
      let periodDate = vitalsViewModel.menstrualSummary?.nextPredictedPeriodDate,
      let remainingDays = Calendar.current.dateComponents([.day], from: .now, to: periodDate).day,
      remainingDays <= 4,
      remainingDays >= -3
    {
      Section("Cycle Tracking") {
        UpcomingPeriodCell(predictedPeriodDate: periodDate)
          .contentShape(Rectangle())
          .onTapGesture {
            showMenstruationDetails = true
          }
      }
    }
  }

  @ViewBuilder
  var menstrualCycleSection: some View {
    if let phase = vitalsViewModel.menstrualSummary?.currentPhase() {
      switch phase {
      case .follicular, .luteal:
        Section("Cycle Phase") {
          HStack {
            Image(systemSymbol: .circleDottedAndCircle)
              .font(.largeTitle)
              .foregroundStyle(phase.color!)
              .frame(width: 50)

            VStack(alignment: .leading) {
              Text(phase.name)
                .font(.title3)
                .bold()

              Text(phase.coolFacts[randomMenstrualCyclePhaseFactIndex % phase.coolFacts.count].fact)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
          }
          .contentShape(Rectangle())
          .onTapGesture {
            showMenstruationDetails = true
          }
        }
      default:
        EmptyView()
      }
    }
  }

  @ViewBuilder
  var focusAreasSection: some View {
    if incompleteTargetMetrics.isNotEmpty {
      Section("Focus On Today") {
        ForEach(activeHabits) { habit in
          if incompleteTargetMetrics.contains(habit.targetMetric) {
            MorningHabitStatusCell(habit: habit)
          }
        }
      }
    }
  }

  func calculateHabitCompletion() async {
    for habit in activeHabits {
      let targetMetric = habit.targetMetric

      let dailyQuantity = await targetMetric.fetchTotalQuantity(for: .yesterday())

      if !habit.quantityMeetsGoal(dailyQuantity) {
        incompleteTargetMetrics.insert(targetMetric)
      }
    }
  }

  var calendarSection: some View {
    Section("Events") {
      if events.isEmpty {
        Text("No Events")
          .font(.title3)
          .bold()
          .foregroundStyle(.secondary)
          .horizontallyCentered()
          .frame(height: 100)
          .standardListSeparatorInset()
      }
      ForEach(allDayEvents) { event in
        AllDayEventCell(event: event)
          .contentShape(Rectangle())
          .onTapGesture {
            selectedEvent = event
          }
      }
      ForEach(nonAllDayEvents) { event in
        EventCell(event: event)
          .contentShape(Rectangle())
          .onTapGesture {
            selectedEvent = event
          }
      }
    }
  }

  var allDayEvents: [EKEvent] {
    events.filter({ $0.isAllDay })
  }

  var nonAllDayEvents: [EKEvent] {
    events.filter({ !$0.isAllDay })
  }

  var weatherSection: some View {
    Section("Weather") {
      if isLoadingWeather {
        ProgressView("Loading Weather")
          .horizontallyCentered()
          .frame(height: 180)
      } else if
        let weather,
        let minTemp = minTemp(from: weather),
        let maxTemp = maxTemp(from: weather),
        let closestHour = weather.hourlyForecast.filter({ Calendar.current.isDateInToday($0.date) && $0.date > .now }).min(by: {
          abs($0.date.timeIntervalSinceNow) < abs($1.date.timeIntervalSinceNow)
        }),
        !isLoadingWeather
      {
        ForEach(weather.weatherAlerts ?? [], id: \.summary) { weatherAlert in
          WeatherAlertCell(weatherAlert: weatherAlert)
        }

        VStack {
          WeatherCurrentConditionsCell(
            currentWeather: weather.currentWeather,
            locality: locationLocality ?? ""
          )

          Chart {
            ForEach(weather.hourlyForecast, id: \.date) { hourWeather in
              if Calendar.current.isDateInToday(hourWeather.date) {
                if hourWeather.date < .now || hourWeather == closestHour {
                  LineMark(
                    x: .value("Date", hourWeather.date),
                    y: .value("Temperature", hourWeather.temperature.localizedValue)
                  )
                  .lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round, dash: [10, 10]))
                  .interpolationMethod(.catmullRom)
                  .foregroundStyle(by: .value("DataSet", "Past Line"))

                  AreaMark(
                    x: .value("Date", hourWeather.date),
                    yStart: .value("", minTemp.localizedValue - 5),
                    yEnd: .value("Temperature", hourWeather.temperature.localizedValue)
                  )
                  .interpolationMethod(.catmullRom)
                  .foregroundStyle(by: .value("DataSet", "Past Area"))
                }
                if hourWeather.date >= .now {
                  LineMark(
                    x: .value("Date", hourWeather.date),
                    y: .value("Temperature", hourWeather.temperature.localizedValue)
                  )
                  .lineStyle(StrokeStyle(lineWidth: 4))
                  .interpolationMethod(.catmullRom)
                  .foregroundStyle(by: .value("DataSet", "Future Line"))

                  AreaMark(
                    x: .value("Date", hourWeather.date),
                    yStart: .value("", minTemp.localizedValue - 5),
                    yEnd: .value("Temperature", hourWeather.temperature.localizedValue)
                  )
                  .interpolationMethod(.catmullRom)
                  .foregroundStyle(by: .value("DataSet", "Future Area"))
                }
              }
            }

            PointMark(
              x: .value("Date", closestHour.date),
              y: .value("Temperature", closestHour.temperature.localizedValue)
            )
            .foregroundStyle(.text)

            RuleMark(
              x: .value("Date", closestHour.date)
            )
            .lineStyle(StrokeStyle(lineWidth: 0.5))
            .foregroundStyle(.text)
          }
          .chartForegroundStyleScale([
            "Past Line": gradientFor(minTemp: minTemp, maxTemp: maxTemp, opacity: 0.5),
            "Future Line": gradientFor(minTemp: minTemp, maxTemp: maxTemp),
            "Past Area": gradientFor(minTemp: minTemp, minTempShift: 5, maxTemp: maxTemp, opacity: 0.2),
            "Future Area": gradientFor(minTemp: minTemp, minTempShift: 5, maxTemp: maxTemp, opacity: 0.5)
          ])
          .chartLegend(.hidden)
          .chartYScale(domain: (minTemp.localizedValue - 5)...(maxTemp.localizedValue + 5), range: .plotDimension)
          .frame(height: 180)

          Link("Powered by  Weather", destination: .appleWeatherAttribution)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.vertical, 4)
            .selectable()
            .buttonStyle(.plain)
            .horizontalAlignment(.leading)
        }
        .standardListSeparatorInset()
      }
    }
  }

  func minTemp(from weather: Weather) -> Measurement<UnitTemperature>? {
    weather.hourlyForecast
      .filter({ Calendar.current.isDateInToday($0.date) })
      .min(by: \.temperature.value)
      .map { $0.temperature }
  }

  func maxTemp(from weather: Weather) -> Measurement<UnitTemperature>? {
    weather.hourlyForecast
      .filter({ Calendar.current.isDateInToday($0.date) })
      .max(by: \.temperature.value)
      .map { $0.temperature }
  }

  func gradientFor(
    minTemp: Measurement<UnitTemperature>,
    minTempShift: Double = 0,
    maxTemp: Measurement<UnitTemperature>,
    opacity: Double = 1
  ) -> LinearGradient {
    // Convert to Celsius and apply shift
    let minC = minTemp.converted(to: .celsius).value - minTempShift
    let maxC = maxTemp.converted(to: .celsius).value

    // Define temperature bands and associated colors
    let thresholds: [(limit: Double, color: Color)] = [
        (-10, .belowMinus10),
        (0,   .below0),
        (10,  .above10),
        (15,  .above15),
        (20,  .above20),
        (25,  .above25),
        (30,  .above30),
        (35,  .above35),
        (40,  .above40)
    ]

    var colors: [Color] = []

    // Include color for any part of the range <= -10°C
    if minC <= thresholds[0].limit {
        colors.append(thresholds[0].color.opacity(opacity))
    }

    // Include colors for each band intersecting the [minC, maxC] range
    for index in 1 ..< thresholds.count {
        let lower = thresholds[index - 1].limit
        let upper = thresholds[index].limit
        if maxC > lower && minC < upper {
            colors.append(thresholds[index].color.opacity(opacity))
        }
    }

    // Include color for any part of the range > 40°C
    if maxC > thresholds.last!.limit {
        colors.append(thresholds.last!.color.opacity(opacity))
    }

    // Fallback if no colors were added
    if colors.isEmpty {
        colors.append(thresholds[1].color.opacity(opacity))
    }

    return LinearGradient(colors: colors, startPoint: .bottom, endPoint: .top)
  }
}

#Preview {
  GoodMorningView()
}
