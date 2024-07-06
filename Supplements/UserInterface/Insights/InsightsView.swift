//
//  InsightsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import SwiftUI
import AppUI

struct InsightsView: View {

    @State private var presentedSheet: AnyView?
    @State private var presentedNavigationView: AnyView?
    @State private var error: Error?

    @ObservedObject private var viewModel = InsightsViewModel.shared
    @ObservedObject private var healthManager = HealthManager.shared

    @State private var iconColor = Color.yellow
    @State private var gradientColors: [Color] = [.orange, .red, .pink]

    let timer = Timer.publish(every: 1, tolerance: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            List {
                HStack {
                    HStack {
                        Image(systemName: "sunrise.fill")
                            .font(.title2)
                            .bold()
                            .foregroundStyle(iconColor)

                        Text("Good Morning Survey")
                            .font(.title2)
                            .fontDesign(.rounded)
                            .bold()
                    }
                    .foregroundStyle(LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing))
                    .animation(.linear(duration: 1), value: gradientColors)
                    .animation(.linear(duration: 1), value: iconColor)
                    .onReceive(timer) { time in
                        shiftGradientColors()
                    }

                    Spacer()

                    Image(systemName: "chevron.forward")
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    presentedSheet = GoodMorningView().asAny
                }

                if viewModel.sleepAnalysis.isNotEmpty {
                    SleepScoreCell(sleepAnalysis: viewModel.sleepAnalysis) {
                        presentedNavigationView = SleepSummaryView().asAny
                    }

                    if let firstSleepAnalysis = viewModel.sleepAnalysis.last {
                        SleepHeartRateSummaryCell(heartRates: firstSleepAnalysis.heartRate)
                        SleepSoundLevelSummaryCell(soundLevels: firstSleepAnalysis.environmentalSoundLevels)
                    }
                }

                WorkoutSummaryCell(workoutSummaries: viewModel.workoutSummary)

                TimeInDaylightCell(timeInDaylight: viewModel.timeInDaylight)

                RestingHeartRateCell(heartRateSamples: viewModel.restingHeartRate)

                MeditationMinutesCell(meditationMinutes: viewModel.meditationMinutes)

//                ScreenUsageReportCell()
            }
            .navigationTitle("Insights")
            .navigationDestination($presentedNavigationView)
            .sheet($presentedSheet)
        }
        .animation(.default, value: viewModel.sleepAnalysis)
        .animation(.default, value: viewModel.workoutSummary.count)
        .onChange(of: healthManager.userInfoModel, { oldValue, newValue in
            guard newValue != nil else {
                return
            }
        })
        .tabItem {
            Label("Insights", systemImage: "heart.text.square")
        }
    }
}

private extension InsightsView {

    @ViewBuilder
    func content(response: InsightsResponse) -> some View {
        UserInfoInsightsSection(insights: response.userInfoInsights)

        Section {
            ForEach(response.activityRecommendations) { activity in
                ActivityCell(activityModel: activity)
            }
        } header: {
            Text("Activities")
                .multilineTextAlignment(.leading)
                .font(.title2)
                .fontDesign(.rounded)
                .bold()
                .textCase(.none)
        }

        if let insights = response.supplementInsights {
            SupplementInsightsSection(insights: insights)
        }
        if let insights = response.goalRecommendations {
            GoalInsightsSection(goalInsights: insights)
        }
    }

    func shiftGradientColors() {
        gradientColors.insert(iconColor, at: 0)
        iconColor = gradientColors.removeLast()
    }
}

#Preview {
    TabView {
        InsightsView()
    }
}
