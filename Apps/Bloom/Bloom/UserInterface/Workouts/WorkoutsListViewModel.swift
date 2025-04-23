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

  @Published var selectedActivityType: HKWorkoutActivityType?
  @Published private(set) var state: State = .loading
  @Published private(set) var workoutSections = [WorkoutDateSection]()
  @Published private(set) var filteredWorkoutSections = [WorkoutDateSection]()
  @Published private(set) var activityTypes = [HKWorkoutActivityType]()

  private var backgroundDeliveryHandle: HKBackgroundDeliveryHandle?
  private var observationHandler: HKObserverQueryHandle?

  init() {
    Task {
      await observeChanges()
    }
  }

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
    guard await checkHealthAuth() else { return }

    let response = await HealthWorkoutFetcher.shared.fetchSectionedWorkouts(dateRange: .trailingMonthsFromNow(1000))

    self.activityTypes = response.activityTypes
    self.workoutSections = response.sections

    refreshFilteredWorkoutSections()

    state = .loaded
  }

  private func checkHealthAuth() async -> Bool {
    do {
      let authStatus = try await HealthPermissionChecker.shared.checkAccess(
        readTypes: HealthPermissionChecker.shared.activityTypes
      )

      if authStatus == .shouldRequest {
        state = .needsPermission
        return false
      }

      // Check if the types required were denied after we've already requested.
      let isAnyDenied = HealthPermissionChecker.shared.activityTypes.contains {
        HealthPermissionChecker.shared.healthStore.authorizationStatus(for: $0) == .sharingDenied
      }

      if isAnyDenied {
        state = .permissionDenied
        return false
      }

      // We're good.
      return true

    } catch {
      print(error)
      return false
    }
  }

  func observeChanges() async {
    let sampleType = HKCategoryType.workoutType()
    backgroundDeliveryHandle = await HealthStoreFetcher.shared.enableBackgroundDelivery(
      objectType: sampleType,
        frequency: .immediate
    )

    observationHandler = HealthManager.shared.healthStore.observeChanges(
      sampleType: sampleType,
        startDate: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
    ) { [weak self] in
        await self?.loadWorkouts()
    }
  }
}
