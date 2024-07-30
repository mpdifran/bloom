//
//  VitalsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-21.
//

import SwiftUI

struct VitalsView: View {

    @ObservedObject private var viewModel = VitalsViewModel.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    VitalSummaryView(
                        hrvStatus: viewModel.hrvStatus,
                        sleepStatus: viewModel.sleepStatus,
                        rhrStatus: viewModel.rhrStatus
                    )
                    .padding(.horizontal)

                    HStack {
                        Text("Monthly Vitals")
                            .font(.headline)
                            .bold()
                        Spacer()
                    }
                    .padding(.top)
                    .padding(.horizontal)
                    .padding(.horizontal)

                    if let sleepVitalsSummary = viewModel.sleepVitalsSummary {
                        NavigationLink {
                            TodayView()
                        } label: {
                            MonthlyVitalCardCell(
                                title: "Sleep Quality",
                                systemImage: "moon.zzz.fill",
                                subtitleText: sleepVitalsSummary.subtitleText,
                                metricValue: sleepVitalsSummary.quality.name,
                                trend: sleepVitalsSummary.trend
                            )
                            .tint(sleepVitalsSummary.quality.color)
                            .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                    }

                    if let energyBurnedSummary = viewModel.energyBurnedSummary {
                        MonthlyVitalCardCell(
                            title: "Activity Level",
                            systemImage: "figure.tennis",
                            subtitleText: "Basal: \(String(format: "%.0f", energyBurnedSummary.averageBasalEnergyBurned)) Cal\nActive: \(String(format: "%.0f", energyBurnedSummary.averageActiveEnergyBurned)) Cal",
                            metricValue: energyBurnedSummary.activityLevel.name,
                            trend: energyBurnedSummary.trend
                        )
                        .tint(energyBurnedSummary.activityLevel.color)
                        .padding(.horizontal)
                    }

                    if let cardioFitnessSummary = viewModel.cardioFitnessSummary {
                        MonthlyVitalCardCell(
                            title: "Cardio Fitness",
                            systemImage: "heart.fill",
                            subtitleText: cardioFitnessSummary.subtitle,
                            metricValue: cardioFitnessSummary.level.name,
                            trend: cardioFitnessSummary.trend
                        )
                        .tint(cardioFitnessSummary.level.color)
                        .padding(.horizontal)
                    }

                    if let bodyFatPercentageSummary = viewModel.bodyFatPercentageSummary {
                        MonthlyVitalCardCell(
                            title: "Body Fat Percentage",
                            systemImage: "gauge.with.dots.needle.bottom.50percent",
                            subtitleText: bodyFatPercentageSummary.subtitle,
                            metricValue: bodyFatPercentageSummary.range.name,
                            trend: bodyFatPercentageSummary.trend
                        )
                        .tint(bodyFatPercentageSummary.range.color)
                        .padding(.horizontal)
                    }

                    if let mobilitySummary = viewModel.mobilitySummary {
                        MonthlyVitalCardCell(
                            title: "Mobility",
                            systemImage: "figure.walk",
                            subtitleText: mobilitySummary.subtitle,
                            metricValue: mobilitySummary.status.name,
                            trend: mobilitySummary.trend
                        )
                        .tint(mobilitySummary.status.color)
                        .padding(.horizontal)
                    }

                    if let stressSummary = viewModel.stressSummary {
                        MonthlyVitalCardCell(
                            title: "Stress Levels",
                            systemImage: "bolt.fill",
                            subtitleText: stressSummary.subtitle,
                            metricValue: stressSummary.level.name,
                            trend: stressSummary.trend
                        )
                        .tint(stressSummary.level.color)
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom)
            }
            .navigationTitle("Vitals")
            .background {
                Rectangle()
                    .fill(.background.secondary)
                    .ignoresSafeArea()
            }
            .animation(.default, value: viewModel.hrvStatus)
            .animation(.default, value: viewModel.sleepStatus)
            .animation(.default, value: viewModel.rhrStatus)
            .animation(.default, value: viewModel.sleepVitalsSummary)
            .animation(.default, value: viewModel.energyBurnedSummary)
            .animation(.default, value: viewModel.cardioFitnessSummary)
            .animation(.default, value: viewModel.bodyFatPercentageSummary)
            .animation(.default, value: viewModel.mobilitySummary)
            .animation(.default, value: viewModel.stressSummary)
        }
        .tabItem {
            Label("Vitals", systemImage: "bolt.heart")
        }
    }
}

#Preview {
    TabView {
        VitalsView()
    }
}
