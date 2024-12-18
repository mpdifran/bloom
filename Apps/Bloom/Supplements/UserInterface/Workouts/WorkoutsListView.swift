//
//  WorkoutsListView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-17.
//

import SwiftUI
import HealthKit
import AppUI

struct WorkoutsListView: View {

  @State private var isLoading = true
  @State private var workoutSections = [WorkoutDateSection]()

  var body: some View {
    Group {
      if isLoading {
        loadingView
      } else if workoutSections.isNotEmpty {
        mainListView
      } else {
        emptyView
      }
    }
    .groupedBackground()
    .navigationTitle("Workouts")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await loadWorkouts()
    }
  }
}

private extension WorkoutsListView {

  var loadingView: some View {
    CircularSpinnerView()
      .foregroundStyle(.green)
  }

  var emptyView: some View {
    ContentUnavailableView(
      "No Workouts",
      systemImage: "figure.run",
      description: Text("There are no workouts to show.")
    )
  }

  var mainListView: some View {
    ScrollView {
      LazyVStack(alignment: .leading) {
        ForEach(workoutSections) { section in
          VStack(alignment: .leading) {
            Text("\(section.date, formatter: DateFormatter.fullMonthAndYear)")
              .font(.title)
              .fontDesign(.rounded)
              .bold()
            Text("\(section.workouts.count) \(section.workouts.count == 1 ? "workout" : "workouts")")
              .foregroundStyle(.secondary)
              .font(.headline)
              .bold()
          }
          .fontDesign(.rounded)
          .padding(.top)

          ForEach(section.workouts, id: \.hashValue) { workout in
            NavigationLink {
              WorkoutDetailsView(workout: workout)
            } label: {
              WorkoutCell(workout: workout)
            }
          }
        }
      }
      .padding()
    }
  }
}

private extension WorkoutsListView {

  func loadWorkouts() async {
    self.workoutSections = await HealthWorkoutFetcher.shared.fetchSectionedWorkouts(dateRange: .trailingMonthsFromNow(1000))
    isLoading = false
  }
}

#Preview {
  NavigationStack {
    WorkoutsListView()
  }
}
