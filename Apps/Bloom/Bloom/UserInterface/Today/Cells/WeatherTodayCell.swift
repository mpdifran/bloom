//
//  WeatherTodayCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-08-28.
//

import SwiftUI
import AppUI
import CoreLocation
@preconcurrency import WeatherKit
import Charts
import BloomUI
import SFSafeSymbols
import BloomFoundation

enum WeatherDay: CaseIterable {
  case today
  case tomorrow
  
  var displayName: String {
    switch self {
    case .today: return "Today"
    case .tomorrow: return "Tomorrow"  
    }
  }
}

struct WeatherTodayCell: View {
  let day: WeatherDay

  init(day: WeatherDay) {
    self.day = day
  }

  @State private var isLoadingWeather = false
  @State private var weather: Weather?
  @State private var locationLocality: String?
  @State private var alertDetails: AlertDetails?

  @StateObject private var locationViewModel = LocationManagerViewModel.shared

  var body: some View {
    VStack {
      if !locationViewModel.auth.hasAccess {
        permissionView
      } else if isLoadingWeather {
        loadingView
      } else if let weather {
        TimelineView(.periodic(from: Date(), by: 3600)) { _ in
          contentView(for: weather)
        }
      } else {
        noWeatherDataView
      }
    }
    .cardContainer()
    .animation(.default, value: weather)
    .alert(alertDetails: $alertDetails)
    .task {
      if locationViewModel.currentLocation != nil {
        await loadWeather()
      }
    }
    .onAppear {
      locationViewModel.checkPermission()
    }
    .task {
      guard locationViewModel.auth.hasAccess else { return }

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
  }
}

private extension WeatherTodayCell {

  var permissionView: some View {
    ContentUnavailableView {
      Label("Allow Location Access", systemSymbol: .cloudRain)
    } description: {
      Text("Allow access to your location in order to see local weather.")
    } actions: {
      AsyncButton {
        locationViewModel.promptForPermission(alertDetails: $alertDetails)
      } label: {
        Text("Allow Access")
      }
      .buttonStyle(.tertiary)
    }
    .fixedSize(horizontal: false, vertical: true)
    .foregroundStyle(.secondary)
    .horizontallyCentered()
  }

  var loadingView: some View {
    VStack(spacing: 20) {
      CircularSpinnerView()
        .foregroundStyle(.tint)

      Text("Loading Weather...")
        .font(.headline)
        .fontDesign(.rounded)
    }
    .horizontallyCentered()
  }

  var noWeatherDataView: some View {
    ContentUnavailableView(
      "Weather Not Available",
      systemSymbol: .cloudDrizzleFill,
      description: Text("There was a problem loading the weather.")
    )
    .fixedSize(horizontal: false, vertical: true)
    .foregroundStyle(.secondary)
  }
  
  @ViewBuilder
  func temperatureRangeView(for weather: Weather) -> some View {
    let lowTemp = minTemp(from: weather)
    let highTemp = maxTemp(from: weather)
    
    HStack {
      VStack(alignment: .leading) {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          if let lowTemp, let highTemp {
            Label {
              Text(lowTemp.formatted(
                .measurement(
                  width: .narrow,
                  numberFormatStyle: .number.precision(.fractionLength(0))
                )
              ))
            } icon: {
              Image(systemSymbol: .arrowDown)
                .foregroundStyle(.mutedLightBlue)
            }
            .font(.title2)
            .fontDesign(.rounded)
            .bold()
            
            Label {
              Text(highTemp.formatted(
                .measurement(
                  width: .narrow,
                  numberFormatStyle: .number.precision(.fractionLength(0))
                )
              ))
            } icon: {
              Image(systemSymbol: .arrowUp)
                .foregroundStyle(.mutedOrange)
            }
            .font(.title2)
            .fontDesign(.rounded)
            .bold()
          }
        }
        
        HStack(spacing: 2) {
          Image(systemSymbol: .location)
          Text(locationLocality ?? "")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
      }
      
      Spacer()
      
      Text("Tomorrow")
        .bold()
    }
  }

  @ViewBuilder
  func contentView(for weather: Weather) -> some View {
    ForEach(weather.weatherAlerts ?? [], id: \.summary) { weatherAlert in
      WeatherAlertCell(weatherAlert: weatherAlert)
    }

    if weather.weatherAlerts?.isNotEmpty == true {
      Divider()
    }

    VStack {
      if day == .today {
        // Find the hour closest to current time for display
        let currentHour = weather.hourlyForecast
          .filter({ Calendar.current.isDateInToday($0.date) })
          .min(by: { abs($0.date.timeIntervalSinceNow) < abs($1.date.timeIntervalSinceNow) })

        if let currentHour {
          WeatherCurrentConditionsCell(
            symbol: SFSymbol(rawValue: currentHour.symbolName),
            temperature: currentHour.temperature.formatted(
              .measurement(
                width: .narrow,
                numberFormatStyle: .number.precision(.fractionLength(0))
              )
            ),
            conditions: currentHour.condition.description,
            locality: locationLocality ?? ""
          )
        } else {
          // Fallback to current weather if no hourly data
          WeatherCurrentConditionsCell(
            currentWeather: weather.currentWeather,
            locality: locationLocality ?? ""
          )
        }
      } else {
        // For tomorrow, show temperature range
        temperatureRangeView(for: weather)
      }

      if
        let minTemp = minTemp(from: weather),
        let maxTemp = maxTemp(from: weather)
      {
        temperatureChartView(for: weather, minTemp: minTemp, maxTemp: maxTemp)
      }

      precipitationChartView(for: weather)

      Link("Powered by  Weather", destination: .appleWeatherAttribution)
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.vertical, 4)
        .selectable()
        .buttonStyle(.plain)
        .horizontalAlignment(.leading)
    }
  }
}

private extension WeatherTodayCell {

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

  private func isDateInSelectedDay(_ date: Date) -> Bool {
    switch day {
    case .today:
      return Calendar.current.isDateInToday(date)
    case .tomorrow:
      return Calendar.current.isDateInTomorrow(date)
    }
  }

  func minTemp(from weather: Weather) -> Measurement<UnitTemperature>? {
    weather.hourlyForecast
      .filter({ isDateInSelectedDay($0.date) })
      .min(by: \.temperature.value)
      .map { $0.temperature }
  }

  func maxTemp(from weather: Weather) -> Measurement<UnitTemperature>? {
    weather.hourlyForecast
      .filter({ isDateInSelectedDay($0.date) })
      .max(by: \.temperature.value)
      .map { $0.temperature }
  }

  func minPastTemp(from weather: Weather) -> Measurement<UnitTemperature>? {
    weather.hourlyForecast
      .filter({ isDateInSelectedDay($0.date) && $0.date <= .now })
      .min(by: \.temperature.value)
      .map { $0.temperature }
  }

  func maxPastTemp(from weather: Weather) -> Measurement<UnitTemperature>? {
    weather.hourlyForecast
      .filter({ isDateInSelectedDay($0.date) && $0.date <= .now })
      .max(by: \.temperature.value)
      .map { $0.temperature }
  }

  func minFutureTemp(from weather: Weather) -> Measurement<UnitTemperature>? {
    weather.hourlyForecast
      .filter({ isDateInSelectedDay($0.date) && $0.date > .now })
      .min(by: \.temperature.value)
      .map { $0.temperature }
  }

  func maxFutureTemp(from weather: Weather) -> Measurement<UnitTemperature>? {
    weather.hourlyForecast
      .filter({ isDateInSelectedDay($0.date) && $0.date > .now })
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

  func hasPrecipitation(from weather: Weather) -> Bool {
    weather.hourlyForecast
      .filter({ isDateInSelectedDay($0.date) })
      .contains(where: { $0.precipitationAmount.converted(to: .millimeters).value > 0 })
  }

  func precipitationColor(for condition: WeatherCondition) -> Color {
    switch condition {
    case .snow, .heavySnow, .sleet, .freezingRain:
      return .cyan.opacity(0.7)
    default:
      return .blue
    }
  }

  func formatPrecipitationValue(_ value: Double) -> String {
    let formatter: NumberFormatter = value < 1.0 ? .oneDecimalPlace : .noDecimalPlaces
    return formatter.string(from: NSNumber(value: value)) ?? "0"
  }

  @ViewBuilder
  func precipitationChartView(for weather: Weather) -> some View {
    if hasPrecipitation(from: weather) {
      let precipitationData = weather.hourlyForecast.filter({ isDateInSelectedDay($0.date) })
      let maxPrecipitation = precipitationData.map({ $0.precipitationAmount.converted(to: .millimeters).value }).max() ?? 1.0

      // Determine predominant precipitation type for color
      let hasSnow = precipitationData.contains { hourWeather in
        switch hourWeather.condition {
        case .snow, .heavySnow, .sleet, .freezingRain:
          return hourWeather.precipitationAmount.converted(to: .millimeters).value > 0
        default:
          return false
        }
      }

      // Calculate closest hour for current time indicator
      let closestHour = weather.hourlyForecast.filter({ isDateInSelectedDay($0.date) && $0.date > .now }).min(by: {
        abs($0.date.timeIntervalSinceNow) < abs($1.date.timeIntervalSinceNow)
      })
      let chartClosestHour = day == .tomorrow
        ? weather.hourlyForecast.filter({ isDateInSelectedDay($0.date) }).first
        : (closestHour ?? weather.hourlyForecast.filter({ isDateInSelectedDay($0.date) }).last)

      Text(hasSnow ? "Snow" : "Rain")
        .font(.subheadline)
        .bold()
        .fontDesign(.rounded)
        .horizontalAlignment(.leading)
        .padding(.top, 8)

      Chart {
        ForEach(weather.hourlyForecast, id: \.date) { hourWeather in
          if isDateInSelectedDay(hourWeather.date) {
            // For tomorrow, all hours are "future"; for today, check if past or future
            let isPast = day == .today && hourWeather.date < .now

            BarMark(
              x: .value("Date", hourWeather.date),
              y: .value("Precipitation", hourWeather.precipitationAmount.converted(to: .millimeters).value)
            )
            .cornerRadius(5)
            .foregroundStyle(by: .value("DataSet", isPast ? "Past Precipitation" : "Future Precipitation"))
          }
        }

        // Only show current time indicator for today
        if day == .today, let chartClosestHour {
          RuleMark(
            x: .value("Date", chartClosestHour.date)
          )
          .lineStyle(StrokeStyle(lineWidth: 0.5))
          .foregroundStyle(.text)
        }
      }
      .chartForegroundStyleScale([
        "Past Precipitation": (hasSnow ? Color.cyan.opacity(0.7) : Color.blue).opacity(0.5),
        "Future Precipitation": hasSnow ? Color.cyan.opacity(0.7) : Color.blue
      ])
      .chartLegend(.hidden)
      .chartYScale(domain: 0...(maxPrecipitation + maxPrecipitation * 0.1), range: .plotDimension)
      .chartYAxis {
        AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { value in
          AxisValueLabel {
            if let doubleValue = value.as(Double.self) {
              Text("\(formatPrecipitationValue(doubleValue)) mm")
                .font(.caption2)
                .frame(width: 40, alignment: .trailing)
            }
          }
        }
      }
      .frame(height: 100)
    }
  }

  @ViewBuilder
  func temperatureChartView(
    for weather: Weather,
    minTemp: Measurement<UnitTemperature>,
    maxTemp: Measurement<UnitTemperature>
  ) -> some View {
    // For tomorrow, all temps are future temps
    // For today, use overall temps as fallback if no past temps exist
    let minPastTemp = day == .tomorrow ? minTemp : (minPastTemp(from: weather) ?? minTemp)
    let maxPastTemp = day == .tomorrow ? maxTemp : (maxPastTemp(from: weather) ?? maxTemp)
    let minFutureTemp = minFutureTemp(from: weather) ?? minTemp
    let maxFutureTemp = maxFutureTemp(from: weather) ?? maxTemp

    let closestHour = weather.hourlyForecast.filter({ isDateInSelectedDay($0.date) && $0.date > .now }).min(by: {
      abs($0.date.timeIntervalSinceNow) < abs($1.date.timeIntervalSinceNow)
    })

    // For tomorrow, use the first hour as the "closest"
    // For today, use closestHour if available, otherwise use the last hour of the day
    let chartClosestHour = day == .tomorrow
      ? weather.hourlyForecast.filter({ isDateInSelectedDay($0.date) }).first
      : (closestHour ?? weather.hourlyForecast.filter({ isDateInSelectedDay($0.date) }).last)

    Chart {
      ForEach(weather.hourlyForecast, id: \.date) { hourWeather in
        if isDateInSelectedDay(hourWeather.date) {
          // For tomorrow, all hours are "future" so skip the past rendering
          if day == .today && (hourWeather.date < .now || hourWeather == chartClosestHour) {
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
          // For tomorrow, render all hours as future; for today, render future hours
          if day == .tomorrow || hourWeather.date >= .now {
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

      // Only show current time indicators for today
      if day == .today, let chartClosestHour {
        PointMark(
          x: .value("Date", chartClosestHour.date),
          y: .value("Temperature", chartClosestHour.temperature.localizedValue)
        )
        .foregroundStyle(.text)

        RuleMark(
          x: .value("Date", chartClosestHour.date)
        )
        .lineStyle(StrokeStyle(lineWidth: 0.5))
        .foregroundStyle(.text)
      }
    }
    .chartForegroundStyleScale([
      "Past Line": gradientFor(minTemp: minPastTemp, maxTemp: maxPastTemp, opacity: 0.5),
      "Future Line": gradientFor(minTemp: minFutureTemp, maxTemp: maxFutureTemp),
      "Past Area": gradientFor(minTemp: minPastTemp, minTempShift: 5, maxTemp: maxPastTemp, opacity: 0.2),
      "Future Area": gradientFor(minTemp: minFutureTemp, minTempShift: 5, maxTemp: maxFutureTemp, opacity: 0.5)
    ])
    .chartLegend(.hidden)
    .chartYScale(domain: (minTemp.localizedValue - 5)...(maxTemp.localizedValue + 5), range: .plotDimension)
    .chartYAxis {
      AxisMarks(position: .trailing) { value in
        AxisValueLabel {
          if let doubleValue = value.as(Double.self) {
            // Determine the temperature unit based on locale
            let temperatureUnit: UnitTemperature = Locale.current.measurementSystem == .us ? .fahrenheit : .celsius
            let measurement = Measurement(value: doubleValue, unit: temperatureUnit)
            Text(measurement.formatted(
              .measurement(
                width: .narrow,
                numberFormatStyle: .number.precision(.fractionLength(0))
              )
            ))
            .font(.caption2)
            .frame(width: 40, alignment: .trailing)
          }
        }
      }
    }
    .frame(height: 180)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      VStack(spacing: 16) {
        WeatherTodayCell(day: .today)
        WeatherTodayCell(day: .tomorrow)
      }
    }
  }
}
