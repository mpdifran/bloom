//
//  GoodMorningView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-12.
//

import SwiftUI
import AppUI
import AppFoundations
import EventKit
import EventKitUI
import WeatherKit
import Charts

@MainActor
struct GoodMorningView: View {

    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var healthManager = HealthManager.shared
    @ObservedObject private var vitalsViewModel = VitalsViewModel.shared

    @State private var events = [EKEvent]()
    @State private var selectedEvent: EKEvent?
    @State private var locationLocality: String?
    @State private var weather: Weather?
    @State private var showSleepTodayView = false

    var body: some View {
        NavigationStack {
            List {
                sleepSection
                weatherSection
                calendarSection
                activityLevelSection
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
                .buttonStyle(.tertiary)
            }
            .navigationDestination(isPresented: $showSleepTodayView) {
                SleepDayView()
            }
        }
        .sheet(item: $selectedEvent) { event in
            EKEventView(event: event)
        }
        .presentationCompactAdaptation(.fullScreenCover)
        .tint(.blue)
        .animation(.default, value: healthManager.sleepAnalysis7Days)
        .animation(.default, value: events.count)
        .animation(.default, value: weather)
        .onAppear {
            LocationManager.shared.requestAuth()
            loadWeather()
        }
        .onChange(of: LocationManager.shared.currentLocation) { oldValue, newValue in
            if oldValue == nil, newValue != nil {
                loadWeather()
            }
        }
        .task {
            await CalendarManager.shared.promptForPermission()
            self.events = await CalendarManager.shared.eventsToday()
        }
    }
}

private extension GoodMorningView {

    func loadWeather() {
        guard let location = LocationManager.shared.currentLocation, weather == nil else { return }

        Task {
            let weather = await WeatherForecaster.shared.forecastedWeather(location: location)
            let locality = await LocationManager.shared.locality(for: location)

            await MainActor.run {
                self.weather = weather
                self.locationLocality = locality
            }
        }
    }
}

private extension GoodMorningView {

    @ViewBuilder
    var sleepSection: some View {
        if let sleepAnalysis = healthManager.sleepAnalysis7Days?.last, Calendar.current.isDateInToday(sleepAnalysis.endDate) {
            Section("Sleep Score") {
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
            }
        }
    }

    @ViewBuilder
    var activityLevelSection: some View {
        if
            let energyRatioSample = vitalsViewModel.activityLevelSummary?.energyRatioSamples.last(where: { Calendar.current.isDateInYesterday($0.date) })
        {
            switch ActivityLevelSummary.ActivityLevel(energyRatioSample.quantity) {
            case .intense:
                Section("Activity Level") {
                    HStack {
                        Image(systemName: VitalModel.Kind.activityLevel.systemImage)
                            .font(.largeTitle)
                            .foregroundStyle(.green)
                            .frame(width: 50)

                        VStack(alignment: .leading) {
                            Text("Energy Ratio")
                                .font(.title3)
                                .bold()

                            Text("Your Energy Ratio yesterday was in the Intense level (\(energyRatioSample.quantity.format(to: 1))). Make sure to take a break from activity today to give your body time to recover.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                }
            case .sedentary:
                Section("Activity Level") {
                    HStack {
                        Image(systemName: VitalModel.Kind.activityLevel.systemImage)
                            .font(.largeTitle)
                            .foregroundStyle(.green)
                            .frame(width: 50)

                        VStack(alignment: .leading) {
                            Text("Energy Ratio")
                                .font(.title3)
                                .bold()

                            Text("Your Energy Ratio yesterday was in the Sedentary level (\(energyRatioSample.quantity.format(to: 1))). Today might be a good day to get active!")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                }
            default:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    var calendarSection: some View {
        if events.isNotEmpty {
            Section("Events") {
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
    }

    var allDayEvents: [EKEvent] {
        events.filter({ $0.isAllDay })
    }

    var nonAllDayEvents: [EKEvent] {
        events.filter({ !$0.isAllDay })
    }

    @ViewBuilder
    var weatherSection: some View {
        if 
            let weather,
            let minTemp = minTemp(from: weather),
            let maxTemp = maxTemp(from: weather),
            let closestHour = weather.hourlyForecast.filter({ Calendar.current.isDateInToday($0.date) && $0.date > .now }).min(by: {
                abs($0.date.timeIntervalSinceNow) < abs($1.date.timeIntervalSinceNow)
            })
        {
            Section("Weather") {
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
                                        y: .value("Temperature", hourWeather.temperature.value)
                                    )
                                    .lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round, dash: [10, 10]))
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(by: .value("DataSet", "Past Line"))

                                    AreaMark(
                                        x: .value("Date", hourWeather.date),
                                        yStart: .value("", minTemp - 5),
                                        yEnd: .value("Temperature", hourWeather.temperature.value)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(by: .value("DataSet", "Past Area"))
                                }
                                if hourWeather.date >= .now {
                                    LineMark(
                                        x: .value("Date", hourWeather.date),
                                        y: .value("Temperature", hourWeather.temperature.value)
                                    )
                                    .lineStyle(StrokeStyle(lineWidth: 4))
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(by: .value("DataSet", "Future Line"))

                                    AreaMark(
                                        x: .value("Date", hourWeather.date),
                                        yStart: .value("", minTemp - 5),
                                        yEnd: .value("Temperature", hourWeather.temperature.value)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(by: .value("DataSet", "Future Area"))
                                }
                            }
                        }

                        PointMark(
                            x: .value("Date", closestHour.date),
                            y: .value("Temperature", closestHour.temperature.value)
                        )
                        .foregroundStyle(.text)

                        RuleMark(
                            x: .value("Date", closestHour.date)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.text)
                    }
                    .chartForegroundStyleScale([
                        "Past Line" : gradientFor(minTemp: minTemp, maxTemp: maxTemp, opacity: 0.5),
                        "Future Line" : gradientFor(minTemp: minTemp, maxTemp: maxTemp),
                        "Past Area" : gradientFor(minTemp: minTemp - 5, maxTemp: maxTemp, opacity: 0.2),
                        "Future Area" : gradientFor(minTemp: minTemp - 5, maxTemp: maxTemp, opacity: 0.5)
                    ])
                    .chartLegend(.hidden)
                    .chartYScale(domain: (minTemp - 5)...(maxTemp + 5), range: .plotDimension)
                    .frame(height: 180)
                }
                .standardListSeparatorInset()
            }
        }
    }

    func minTemp(from weather: Weather) -> Double? {
        weather.hourlyForecast
            .filter({ Calendar.current.isDateInToday($0.date) })
            .min(keyPath: \.temperature.value)
    }

    func maxTemp(from weather: Weather) -> Double? {
        weather.hourlyForecast
            .filter({ Calendar.current.isDateInToday($0.date) })
            .max(keyPath: \.temperature.value)
    }

    func gradientFor(minTemp: Double, maxTemp: Double, opacity: Double = 1) -> LinearGradient {
        var colors = [Color]()

        if minTemp < -10 {
            colors.append(.belowMinus10.opacity(opacity))
        }
        if minTemp < 0 && maxTemp > 0 {
            colors.append(.below0.opacity(opacity))
        }
        if minTemp < 10 && maxTemp > 10 {
            colors.append(.above10.opacity(opacity))
        }
        if minTemp < 15 && maxTemp > 15 {
            colors.append(.above15.opacity(opacity))
        }
        if minTemp < 20 && maxTemp > 20 {
            colors.append(.above20.opacity(opacity))
        }
        if minTemp < 25 && maxTemp > 25 {
            colors.append(.above25.opacity(opacity))
        }
        if minTemp < 30 && maxTemp > 30 {
            colors.append(.above30.opacity(opacity))
        }
        if minTemp < 35 && maxTemp > 35 {
            colors.append(.above35.opacity(opacity))
        }
        if maxTemp > 40 {
            colors.append(.above40.opacity(opacity))
        }

        return LinearGradient(colors: colors, startPoint: .bottom, endPoint: .top)
    }
}

#Preview {
    GoodMorningView()
}
