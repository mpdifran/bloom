//
//  ExerciseEffectivenessSection.swift
//  Bloom
//
//  Created by Assistant on 2024-12-29.
//

import SwiftUI
import CoreHealth
import SFSafeSymbols
import DataContainer
import HealthKit

struct ExerciseEffectivenessSection: View {
  @Binding var presentedNavigationDestination: AnyView?
  let summary: ExerciseEffectivenessMonthlySummary?
  let zoneMinutesData: ZoneMinutesData?
  let zoneDistributionData: ZoneDistributionData?
  let recentWorkoutsData: RecentWorkoutsData?

  var body: some View {
    StatSection(symbol: SFSymbol(rawValue: VitalModel.Kind.exerciseEffectiveness.systemImage), title: "Exercise Effectiveness", subtitle: "Last 7 Days") {
      HStack {
        zoneMinutesCard
        zoneDistributionCard
      }

      recentWorkoutsList
    }
  }

  private func navigateToDetails() {
    presentedNavigationDestination = WorkoutsListView().asAny
  }
}

private extension ExerciseEffectivenessSection {

  var zoneMinutesCard: some View {
    ZoneMinutesStatCard(data: zoneMinutesData)
      .onTapGesture {
        presentedNavigationDestination = ExerciseEffectivenessView().asAny
      }
  }

  var zoneDistributionCard: some View {
    ZoneDistributionStatCard(data: zoneDistributionData)
      .onTapGesture {
        presentedNavigationDestination = ExerciseEffectivenessView().asAny
      }
  }

  @ViewBuilder
  var recentWorkoutsList: some View {
    if let data = recentWorkoutsData, !data.displayWorkouts.isEmpty {
      VStack {
        ForEach(data.displayWorkouts, id: \.id) { report in
          RecentWorkoutCell(report: report)
            .cardContainer(includePadding: false)
            .onTapGesture {
              presentedNavigationDestination = WorkoutDetailsView(workout: report.workout).asAny
            }
        }

        showMoreButton
      }
    }
  }

  var showMoreButton: some View {
    Text("Show More")
      .bold()
      .fontDesign(.rounded)
      .horizontallyCentered()
      .cardContainer()
      .onTapGesture {
        navigateToDetails()
      }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      ExerciseEffectivenessSection(
        presentedNavigationDestination: .constant(nil),
        summary: nil,
        zoneMinutesData: ZoneMinutesData(dailyValues: [15, 20, 25, 10, 30, 10, 10], weeklyTotal: 120),
        zoneDistributionData: ZoneDistributionData(
          zone1Percent: 0.1,
          zone2Percent: 0.25,
          zone3Percent: 0.35,
          zone4Percent: 0.2,
          zone5Percent: 0.1,
          workoutCount: 4
        ),
        recentWorkoutsData: RecentWorkoutsData(
          workouts: [
            WorkoutHeartRateReport(
              workout: HKWorkout(
                activityType: .running,
                start: Date().addingTimeInterval(-3600),
                end: Date()
              ),
              heartRateSamples: [],
              heartRateZones: previewHeartRateZones
            ),
            WorkoutHeartRateReport(
              workout: HKWorkout(
                activityType: .cycling,
                start: Date().addingTimeInterval(-86400),
                end: Date().addingTimeInterval(-82800)
              ),
              heartRateSamples: [],
              heartRateZones: previewHeartRateZones
            ),
            WorkoutHeartRateReport(
              workout: HKWorkout(
                activityType: .swimming,
                start: Date().addingTimeInterval(-172800),
                end: Date().addingTimeInterval(-169200)
              ),
              heartRateSamples: [],
              heartRateZones: previewHeartRateZones
            ),
            WorkoutHeartRateReport(
              workout: HKWorkout(
                activityType: .hiking,
                start: Date().addingTimeInterval(-259200),
                end: Date().addingTimeInterval(-255600)
              ),
              heartRateSamples: [],
              heartRateZones: previewHeartRateZones
            )
          ]
        )
      )
    }
  }
}

private let previewHeartRateZones = HeartRateZones(
  heartRateReserve: 120,
  restingHeartRate: 60,
  maxHeartRate: 180,
  zone1: 100,
  zone2: 120,
  zone3: 140,
  zone4: 160,
  zone5: 170
)
