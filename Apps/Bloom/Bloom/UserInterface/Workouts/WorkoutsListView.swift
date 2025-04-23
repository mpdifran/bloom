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

  private let titleDisplayMode: NavigationBarItem.TitleDisplayMode

  init(
    activityType: HKWorkoutActivityType? = nil,
    titleDisplayMode: NavigationBarItem.TitleDisplayMode = .inline
  ) {
    self.titleDisplayMode = titleDisplayMode
    if let activityType {
      self._selectedActivityType = State(initialValue: activityType)
    }
  }

  @State private var isLoading = true
  @State private var workoutSections = [WorkoutDateSection]()
  @State private var filteredWorkoutSections = [WorkoutDateSection]()
  @State private var activityTypes = [HKWorkoutActivityType]()
  @State private var selectedActivityType: HKWorkoutActivityType?

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
    .navigationBarTitleDisplayMode(titleDisplayMode)
    .animation(.default, value: selectedActivityType)
    .onChange(of: selectedActivityType) { (_, _) in
      refreshFilteredWorkoutSections()
    }
    .task {
      await loadWorkouts()
    }
  }
}

private extension WorkoutsListView {

  var loadingView: some View {
    ZStack {
      Rectangle()
        .fill(.clear)
      CircularSpinnerView()
        .foregroundStyle(.green)
    }
    .groupedBackground()
  }

  var emptyView: some View {
    ContentUnavailableView(
      "No Workouts",
      systemImage: "figure.run",
      description: Text("There are no workouts to show.")
    )
  }

  var mainListView: some View {
    BloomScrollView(padding: []) {
      VStack(alignment: .leading, spacing: 0) {
        WorkoutActivityTypeFilterView(
          activityTypes: activityTypes,
          selectedActivityType: $selectedActivityType
        )
        .tint(.green)

        LazyVStack(alignment: .leading) {
          ForEach(filteredWorkoutSections) { section in
            WorkoutSectionHeaderView(section: section)

            ForEach(section.workouts, id: \.hashValue) { workout in
              NavigationLink {
                WorkoutDetailsView(workout: workout)
              } label: {
                WorkoutCell(workout: workout)
              }
              .buttonStyle(.plain)
            }
          }
        }
        .padding()
      }
    }
  }
}

private extension WorkoutsListView {

  func refreshFilteredWorkoutSections() {
    guard let selectedActivityType else {
      filteredWorkoutSections = workoutSections
      return
    }

    var sections = [WorkoutDateSection]()

    for section in workoutSections {
      guard section.workouts.contains(where: { $0.workoutActivityType == selectedActivityType }) else {
        continue
      }

      let filteredWorkouts = section.workouts.filter({ $0.workoutActivityType == selectedActivityType })
      let filteredSection = WorkoutDateSection(date: section.date, workouts: filteredWorkouts)
      sections.append(filteredSection)
    }

    filteredWorkoutSections = sections
  }

  func loadWorkouts() async {
    let response = await HealthWorkoutFetcher.shared.fetchSectionedWorkouts(dateRange: .trailingMonthsFromNow(1000))

    self.activityTypes = response.activityTypes
    self.workoutSections = response.sections

    refreshFilteredWorkoutSections()

    isLoading = false
  }
}

private struct WorkoutSectionHeaderView: View {
  let section: WorkoutDateSection

  var body: some View {
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
  }
}

#Preview {
  NavigationStack {
    WorkoutsListView()
  }
}
