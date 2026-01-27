//
//  PinnedWorkoutsManager.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-26.
//

import SwiftUI

@MainActor
final class PinnedWorkoutsManager: ObservableObject {
  static let shared = PinnedWorkoutsManager()

  private static let storageKey = "PinnedWorkoutsManager.pinnedWorkoutIds"

  @Published var pinnedWorkoutIds: [String] = [] {
    didSet {
      UserDefaults.standard.set(pinnedWorkoutIds, forKey: Self.storageKey)
    }
  }

  private init() {
    if let ids = UserDefaults.standard.array(forKey: Self.storageKey) as? [String] {
      self.pinnedWorkoutIds = ids
    }
  }

  func isPinned(_ variant: WorkoutVariant) -> Bool {
    pinnedWorkoutIds.contains(variant.id)
  }

  func pin(_ variant: WorkoutVariant) {
    guard !pinnedWorkoutIds.contains(variant.id) else { return }
    pinnedWorkoutIds.append(variant.id)
  }

  func unpin(_ variant: WorkoutVariant) {
    pinnedWorkoutIds.removeAll { $0 == variant.id }
  }

  func move(fromOffsets source: IndexSet, toOffset destination: Int) {
    pinnedWorkoutIds.move(fromOffsets: source, toOffset: destination)
  }
}
