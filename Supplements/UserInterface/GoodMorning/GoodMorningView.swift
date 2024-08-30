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
                TodayView()
            }
        }
        .sheet(item: $selectedEvent) { event in
            EKEventView(event: event)
        }
        .presentationCompactAdaptation(.fullScreenCover)
        .tint(.blue)
        .animation(.default, value: healthManager.sleepAnalysis7Days)
        .animation(.default, value: events.count)
        .onAppear {
            LocationManager.shared.requestAuth()
        }
        .onChange(of: LocationManager.shared.currentLocation) { oldValue, newValue in
            if oldValue == nil, weather == nil, let newValue {
                Task {
                    let weather = await WeatherForecaster.shared.forecastedWeather(location: newValue)
                    let locality = await LocationManager.shared.locality(for: newValue)

                    await MainActor.run {
                        self.weather = weather
                        self.locationLocality = locality
                    }
                }
            }
        }
        .task {
            await CalendarManager.shared.promptForPermission()
            self.events = await CalendarManager.shared.eventsToday()
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
                ForEach(events) { event in
                    EventCell(event: event)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedEvent = event
                        }
                }
            }
        }
    }

    @ViewBuilder
    var weatherSection: some View {
        if let weather {
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
                                LineMark(
                                    x: .value("Date", hourWeather.date),
                                    y: .value("Temperature", hourWeather.temperature.value)
                                )
                                .lineStyle(StrokeStyle(lineWidth: 6))
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .green, .orange, .red],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )

//                                BarMark(
//                                    x: .value("Date", hourWeather.date),
//                                    y: .value("Precipitation %", hourWeather.precipitationChance * 30)
//                                )
//                                .foregroundStyle(.blue)
                            }
                        }
                    }
                    .frame(height: 180)
                }
                .standardListSeparatorInset()
            }
        }
    }
}

#Preview {
    GoodMorningView()
}
