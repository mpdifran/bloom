//
//  GoalModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import Foundation

struct GoalModel: Codable, Identifiable, Hashable {
    var id: String { name }
    let name: String
}
