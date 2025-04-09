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
  @Published var selectedActivityType: HKWorkoutActivityType?
  @Published private(set) var isLoading = true
  @Published private(set) var workoutSections = [WorkoutDateSection]()
  @Published private(set) var filteredWorkoutSections = [WorkoutDateSection]()
  @Published private(set) var activityTypes = [HKWorkoutActivityType]()
  @Published private(set) var triggerHealthPermissionSheet = false

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

    isLoading = false
  }

  private func checkHealthAuth() async -> Bool {
    do {
      let authStatus = try await HealthPermissionChecker.shared.checkAccess(
        readTypes: HealthPermissionChecker.shared.activityTypes
      )

      let needsAuth = authStatus == .shouldRequest
      if needsAuth {
        triggerHealthPermissionSheet.toggle()
      }

      return !needsAuth
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
