//
//  WorkoutsListViewModel.swift
//  Bloom
//
//  Created by Zach Radford on 2025-04-08.
//

import SwiftUI
import HealthKit

@MainActor
final class WorkoutsListViewModel: ObservableObject {
  enum State {
    case loading
    case loaded
    case needsPermission
    case permissionDenied
  }

  var onWorkoutsUpdated: (() -> Void)?

  @Published private(set) var state: State = .loading
  @Published private(set) var workoutSections = [WorkoutDateSection]()
  @Published private(set) var filteredWorkoutSections = [WorkoutDateSection]()
  @Published private(set) var activityTypes = [HKWorkoutActivityType]()

  private var observationHandler: HKObserverQueryHandle?

  init() {
    Task {
      await observeChanges()
    }
  }

  func refreshFilteredWorkoutSections(for activityType: HKWorkoutActivityType?) {
    guard let activityType else {
      filteredWorkoutSections = workoutSections
      return
    }

    var sections = [WorkoutDateSection]()

    for section in workoutSections {
      guard section.workouts.contains(where: { $0.workoutActivityType == activityType }) else {
        continue
      }

      let filteredWorkouts = section.workouts.filter({ $0.workoutActivityType == activityType })
      let filteredSection = WorkoutDateSection(date: section.date, workouts: filteredWorkouts)
      sections.append(filteredSection)
    }

    filteredWorkoutSections = sections
  }

  func loadWorkouts(for activityType: HKWorkoutActivityType?) async {
    guard await checkHealthAuth() else { return }

    let response = await HealthWorkoutFetcher.shared.fetchSectionedWorkouts(dateRange: .trailingMonthsFromNow(1000))

    self.activityTypes = response.activityTypes
    self.workoutSections = response.sections

    refreshFilteredWorkoutSections(for: activityType)

    state = .loaded
  }

  private func checkHealthAuth() async -> Bool {
    do {
      let authStatus = try await HealthPermissionChecker.shared.checkAccess(
        readTypes: [HKObjectType.workoutType()]
      )

      if authStatus == .shouldRequest {
        state = .needsPermission
        return false
      }

      // Check if the types required were denied after we've already requested.
//      let isDenied = HealthPermissionChecker.shared.healthStore.authorizationStatus(
//        for: HKObjectType.workoutType()
//      ) == .sharingDenied
//
//      if isDenied {
//        state = .permissionDenied
//        return false
//      }

      // We're good.
      return true

    } catch {
      print(error)
      return false
    }
  }

  func observeChanges() async {
    let sampleType = HKCategoryType.workoutType()
    observationHandler = HealthManager.shared.healthStore.observeChanges(
      sampleType: sampleType,
        startDate: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
    ) { [weak self] in
      await MainActor.run { [weak self] in
        self?.onWorkoutsUpdated?()
      }
    }
  }
}
