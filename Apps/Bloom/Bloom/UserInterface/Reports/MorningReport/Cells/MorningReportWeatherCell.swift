//
//  MorningReportWeatherCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-24.
//

import SwiftUI
import AppUI
import CoreLocation
@preconcurrency import WeatherKit
import Charts

struct MorningReportWeatherCell: View {
  @State private var isLoadingWeather = false
  @State private var weather: Weather?
  @State private var locationLocality: String?

  private var locationViewModel = LocationManagerViewModel.shared

  var body: some View {
    VStack {
      if isLoadingWeather {
        loadingView
      } else if let weather {
        contentView(for: weather)
      } else {
        noWeatherDataView
      }
    }
    .cardContainer()
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
  }
}

private extension MorningReportWeatherCell {

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
      WeatherCurrentConditionsCell(
        currentWeather: weather.currentWeather,
        locality: locationLocality ?? ""
      )

      if
        let minTemp = minTemp(from: weather),
        let maxTemp = maxTemp(from: weather),
        let minPastTemp = minPastTemp(from: weather),
        let maxPastTemp = maxPastTemp(from: weather),
        let minFutureTemp = minFutureTemp(from: weather),
        let maxFutureTemp = maxFutureTemp(from: weather),
        let closestHour = weather.hourlyForecast.filter({ Calendar.current.isDateInToday($0.date) && $0.date > .now }).min(by: {
          abs($0.date.timeIntervalSinceNow) < abs($1.date.timeIntervalSinceNow)
        })
      {
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
          "Past Line": gradientFor(minTemp: minPastTemp, maxTemp: maxPastTemp, opacity: 0.5),
          "Future Line": gradientFor(minTemp: minFutureTemp, maxTemp: maxFutureTemp),
          "Past Area": gradientFor(minTemp: minPastTemp, minTempShift: 5, maxTemp: maxPastTemp, opacity: 0.2),
          "Future Area": gradientFor(minTemp: minFutureTemp, minTempShift: 5, maxTemp: maxFutureTemp, opacity: 0.5)
        ])
        .chartLegend(.hidden)
        .chartYScale(domain: (minTemp.localizedValue - 5)...(maxTemp.localizedValue + 5), range: .plotDimension)
        .frame(height: 180)
      }

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

private extension MorningReportWeatherCell {

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

  func minPastTemp(from weather: Weather) -> Measurement<UnitTemperature>? {
    weather.hourlyForecast
      .filter({ Calendar.current.isDateInToday($0.date) && $0.date <= .now })
      .min(by: \.temperature.value)
      .map { $0.temperature }
  }

  func maxPastTemp(from weather: Weather) -> Measurement<UnitTemperature>? {
    weather.hourlyForecast
      .filter({ Calendar.current.isDateInToday($0.date) && $0.date <= .now })
      .max(by: \.temperature.value)
      .map { $0.temperature }
  }

  func minFutureTemp(from weather: Weather) -> Measurement<UnitTemperature>? {
    weather.hourlyForecast
      .filter({ Calendar.current.isDateInToday($0.date) && $0.date > .now })
      .min(by: \.temperature.value)
      .map { $0.temperature }
  }

  func maxFutureTemp(from weather: Weather) -> Measurement<UnitTemperature>? {
    weather.hourlyForecast
      .filter({ Calendar.current.isDateInToday($0.date) && $0.date > .now })
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
  PreviewEnvironment {
    BloomScrollView {
      MorningReportWeatherCell()
    }
  }
}
