//
//  ExerciseEffectivenessView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-20.
//

import SwiftUI
import Charts
import TelemetryDeck

struct ExerciseEffectivenessView: View {

  private let viewModel = VitalsViewModel.shared

  var body: some View {
    Group {
      if viewModel.exerciseEffectivenessSummary?.details.hasNoData == false {
        contentView
      } else {
        emptyView
      }
    }
    .groupedBackground()
    .toolbar {
      ToolbarItem(placement: .principal) {
        VitalSummaryDetailTitleView(
          title: "Exercise Effectiveness",
          subtitle: "Last 30 Days"
        )
      }
    }
    .navigationTitle("Exercise Effectiveness")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      TelemetryDeck.viewScreen("Exercise Effectiveness Vital Details")
    }
  }
}

private extension ExerciseEffectivenessView {

  var contentView: some View {
    BloomScrollView(spacing: 20) {
      VStack(alignment: .leading, spacing: 6) {
        targetHeartRateZonesChart
        HealthCitationLinkView(
          url: .adultActivityLevels,
          title: "600 minutes based on Physical Activity Guidelines by the CDC."
        )
        .padding(.horizontal)
      }

      workoutTypeSummary
    }
  }

  var emptyView: some View {
    ContentUnavailableView(
      "No Data Available",
      systemImage: "figure.mixed.cardio",
      description: Text("Log a workout with your Apple Watch to get a better sense of your Exercise Effectiveness.")
    )
  }

  @ViewBuilder
  var zoneSummary: some View {
    if let heartRateZones = viewModel.exerciseEffectivenessSummary?.details.heartRateZones {

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
    if let exerciseEffectivenessSummary = viewModel.exerciseEffectivenessSummary {
      VStack(alignment: .leading) {
        VitalDetailChartTitleView(
          title: "Zone Minutes",
          value: ""
        )

        TargetHeartRateZonesDistributionView(
          distribution: exerciseEffectivenessSummary.details.overallHeartZoneDistribution,
          heartRateZones: exerciseEffectivenessSummary.details.heartRateZones
        )
      }
      .cardContainer()
    }
  }

  @ViewBuilder
  var workoutTypeSummary: some View {
    if let workoutTypeReports = viewModel.exerciseEffectivenessSummary?.details.workoutTypeHeartRateReports {
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

#Preview {
  PreviewEnvironment {
    NavigationStack {
      ExerciseEffectivenessView()
    }
  }
}
