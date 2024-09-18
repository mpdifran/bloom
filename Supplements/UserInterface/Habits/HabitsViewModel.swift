//
//  HabitsViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-18.
//

import SwiftUI
import DataContainer

@MainActor
final class HabitsViewModel: ObservableObject {
    static let shared = HabitsViewModel()

    private init() { }
}

extension HabitsViewModel {

    func generateProposedHabits() -> [Habit] {
        []
    }
}
