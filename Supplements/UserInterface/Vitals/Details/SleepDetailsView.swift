//
//  SleepDetailsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-11.
//

import SwiftUI
import Charts

struct SleepDetailsView: View {

    @ObservedObject private var healthManager = HealthManager.shared
    @ObservedObject private var viewModel = VitalsViewModel.shared

    var body: some View {
        ScrollView {
            sleepQualityChart
                .padding()
        }
        .navigationTitle("Sleep Quality")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension SleepDetailsView {

    var sleepQualityChart: some View {
        VStack(alignment: .leading) {
            VitalDetailChartTitleView(
                title: "Sleep Quality",
                value: viewModel.sleepVitalsSummary?.averageSleepScore.format() ?? ""
            )

            Chart {
                ForEach(healthManager.sleepAnalysis30Days ?? []) { sleepAnalysis in
                    BarMark(
                        x: .value("Date", sleepAnalysis.normalizedDate),
                        y: .value("Sleep Quality", sleepAnalysis.overallScoreDouble)
                    )
                    .foregroundStyle(color(for: sleepAnalysis.overallScoreDouble))
                    .cornerRadius(5)
                }
            }
            .frame(height: 200)
        }
    }

    func color(for sleepScore: Double) -> Color {
        if sleepScore < 4 {
            .pink
        } else if sleepScore < 7 {
            .yellow
        } else if sleepScore < 9 {
            .green
        } else {
            .blue
        }
    }
}

#Preview {
    NavigationView {
        SleepDetailsView()
    }
}
