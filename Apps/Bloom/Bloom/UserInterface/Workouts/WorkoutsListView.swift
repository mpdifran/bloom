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

  @StateObject private var viewModel = WorkoutsListViewModel()

  init(
    activityType: HKWorkoutActivityType? = nil,
    titleDisplayMode: NavigationBarItem.TitleDisplayMode = .inline
  ) {
    self.titleDisplayMode = titleDisplayMode
    if let activityType {
      viewModel.selectedActivityType = activityType
    }
  }

  var body: some View {
    Group {
      if viewModel.isLoading {
        loadingView
      } else if viewModel.workoutSections.isNotEmpty {
        mainListView
      } else {
        emptyView
      }
    }
    .groupedBackground()
    .navigationTitle("Workouts")
    .navigationBarTitleDisplayMode(titleDisplayMode)
    .animation(.default, value: viewModel.selectedActivityType)
    .onChange(of: viewModel.selectedActivityType) { (_, _) in
      viewModel.refreshFilteredWorkoutSections()
    }
    .task {
      await viewModel.loadWorkouts()
    }
    .healthDataAccessRequest(
      store: HealthPermissionChecker.shared.healthStore,
      readTypes: HealthPermissionChecker.shared.activityTypes,
      trigger: viewModel.triggerHealthPermissionSheet
    ) { result in
      switch result {
      case .success:
        Task {
          await viewModel.loadWorkouts()
        }
      case .failure:
        // No-op?
        break
      }
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
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        WorkoutActivityTypeFilterView(
          activityTypes: viewModel.activityTypes,
          selectedActivityType: $viewModel.selectedActivityType
        )
        .tint(.green)

        LazyVStack(alignment: .leading) {
          ForEach(viewModel.filteredWorkoutSections) { section in
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
