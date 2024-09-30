//
//  NewHabitResult.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-30.
//

import Foundation

struct NewHabitResult: Sendable, Hashable {
    let proposedHabits: [ProposedHabit]
    let proposedToDos: [ProposedToDo]
}
