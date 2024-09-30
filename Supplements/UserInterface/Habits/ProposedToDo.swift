//
//  ProposedToDo.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-30.
//

import Foundation

struct ProposedToDo: Sendable, Identifiable, Hashable {
    let id = UUID()
    let todoKind: ToDoModel.Kind
    let todoCadence: ToDoModel.Cadence
    let context: String
}
