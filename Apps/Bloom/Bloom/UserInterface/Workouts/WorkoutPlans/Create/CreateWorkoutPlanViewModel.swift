//
//  CreateWorkoutPlanViewModel.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-02-11.
//

import SwiftUI
import BloomModel
import TelemetryDeck
import CoreHealth

enum WorkoutDuration: String, CaseIterable {
  case short
  case medium
  case long

  var title: String {
    switch self {
    case .short: String(localized: "Short", comment: "Title for workout duration")
    case .medium: String(localized: "Medium", comment: "Title for workout duration")
    case .long: String(localized: "Long", comment: "Title for workout duration")
    }
  }

  var subtitle: String {
    switch self {
    case .short: String(localized: "Under 15 min", comment: "Subtitle for workout duration")
    case .medium: String(localized: "15 – 45 min", comment: "Subtitle for workout duration")
    case .long: String(localized: "45+ min", comment: "Subtitle for workout duration")
    }
  }

  var descriptionText: String {
    switch self {
    case .short: "The workout should be under 15 minutes."
    case .medium: "The workout should be between 15 and 45 minutes."
    case .long: "The workout should be 45 minutes or longer."
    }
  }
}

@Observable @MainActor
final class CreateWorkoutPlanViewModel {
  var selectedEquipment = Set<String>()
  var selectedDuration: WorkoutDuration = .medium
  var description = ""
  var error: Error?
  var generatedPlan: SocketMessage.WorkoutPlan?
  var showingPreview = false
  var showAllEquipment = false

  private var ownedEquipment: Set<String> {
    HealthManager.shared.selectedWorkoutEquipment
  }

  var visibleEquipment: [SocketMessage.WorkoutPlan.Equipment] {
    if showAllEquipment || ownedEquipment.isEmpty {
      return SocketMessage.WorkoutPlan.Equipment.allCases
    }
    return SocketMessage.WorkoutPlan.Equipment.allCases.filter {
      ownedEquipment.contains($0.rawValue)
    }
  }

  var showShowAllButton: Bool {
    ownedEquipment.isNotEmpty
  }

  var allVisibleSelected: Bool {
    let visibleRawValues = Set(visibleEquipment.map(\.rawValue))
    return visibleRawValues.isSubset(of: selectedEquipment)
  }

  func toggleSelectAll() {
    withAnimation(.easeInOut(duration: 0.2)) {
      if allVisibleSelected {
        let visibleRawValues = Set(visibleEquipment.map(\.rawValue))
        selectedEquipment.subtract(visibleRawValues)
      } else {
        let visibleRawValues = Set(visibleEquipment.map(\.rawValue))
        selectedEquipment.formUnion(visibleRawValues)
      }
    }
  }

  init() {
    selectedEquipment = HealthManager.shared.selectedWorkoutEquipment
  }

  func createPlan() async throws {
    let fullDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
      + "\n\n" + selectedDuration.descriptionText

    let request = GenerateWorkoutPlanRequest(
      equipment: Array(selectedEquipment),
      description: fullDescription
    )

    let urlRequest = try await URLRequest.Workouts.generatePlan(body: request)
    let response = try await URLSession.shared.authenticatedBloomRequestWithResponse(
      request: urlRequest,
      responseType: GenerateWorkoutPlanResponse.self
    )
    let plan = response.workoutPlan

    TelemetryDeck.signal("Generate Workout Plan")

    generatedPlan = plan
    showingPreview = true
  }

  func toggleEquipment(_ equipment: SocketMessage.WorkoutPlan.Equipment) {
    withAnimation(.easeInOut(duration: 0.2)) {
      if selectedEquipment.contains(equipment.rawValue) {
        selectedEquipment.remove(equipment.rawValue)
      } else {
        selectedEquipment.insert(equipment.rawValue)
      }
    }
  }

  func toggleShowAll() {
    withAnimation(.easeInOut(duration: 0.2)) {
      showAllEquipment.toggle()
    }
  }
}
