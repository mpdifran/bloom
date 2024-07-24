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

                    HStack {
                        Text("Monthly Vital Trends")
                            .font(.headline)
                            .bold()
                        Spacer()
                    }
                    .padding(.top)
                    .padding(.horizontal)
                    .padding(.horizontal)

                    if let energyBurnedSummary = viewModel.energyBurnedSummary {
                        MonthlyVitalCardCell(
                            title: "Activity Level",
                            systemImage: "figure.run",
                            subtitleText: "Basal: \(String(format: "%.0f", energyBurnedSummary.averageBasalEnergyBurned)) Cal\nActive: \(String(format: "%.0f", energyBurnedSummary.averageActiveEnergyBurned)) Cal",
                            metricValue: energyBurnedSummary.activityLevel.name,
                            isIncreasing: energyBurnedSummary.isIncreasing
                        )
                        .tint(.green)
                        .padding(.horizontal)
                    }

                    if let sleepVitalsSummary = viewModel.sleepVitalsSummary {
                        NavigationLink {
                            TodayView()
                        } label: {
                            MonthlyVitalCardCell(
                                title: "Sleep Quality",
                                systemImage: "moon.zzz.fill",
                                subtitleText: sleepVitalsSummary.subtitleText,
                                metricValue: sleepVitalsSummary.quality.name,
                                isIncreasing: sleepVitalsSummary.isIncreasing
                            )
                            .tint(.coreSleep)
                            .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                    }
                }
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
