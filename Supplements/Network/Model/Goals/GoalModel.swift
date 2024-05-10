//
//  GoalModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import SwiftUI

struct GoalModel: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let color: Color
}
