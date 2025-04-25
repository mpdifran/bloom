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

  @State private var triggerHealthPermissionSheet = false

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
      switch viewModel.state {
      case .loading:
        loadingView
      case .loaded:
        if viewModel.workoutSections.isNotEmpty {
          mainListView
        } else {
          emptyView
        }
      case .needsPermission:
        needsPermissionView(alreadyRequested: false)
      case .permissionDenied:
        needsPermissionView(alreadyRequested: true)
      }
    }
    .horizontallyCentered()
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
      trigger: triggerHealthPermissionSheet
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

  func needsPermissionView(alreadyRequested: Bool) -> some View {
    VStack(spacing: 16) {
      Spacer()

      Image(systemSymbol: .figureRun)
        .font(.system(size: 80))
        .foregroundColor(.gray)

      Text("Allow Access to Workouts")
        .font(.title2)
        .fontWeight(.semibold)
        .multilineTextAlignment(.center)

      Text("To show your workout history, we need access to your Health data. You can manage this permission at any time.")
        .font(.title3)
        .fontWeight(.semibold)
        .multilineTextAlignment(.center)
        .foregroundColor(.gray)
        .padding(.horizontal)

      if alreadyRequested {
        Text("Privacy & Security → Health → Bloom")
          .fontWeight(.bold)
          .foregroundColor(.white)
      } else {
        Button {
          triggerHealthPermissionSheet = true
        } label: {
          Text("Allow Access")
            .fontWeight(.bold)
            .foregroundColor(.white)
        }
      }

      Spacer()
    }
  }

  var mainListView: some View {
    BloomScrollView(padding: []) {
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
