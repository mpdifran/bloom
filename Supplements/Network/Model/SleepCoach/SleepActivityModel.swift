//
//  SleepActivityModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-02.
//

import SwiftUI

struct SleepActivityModel: Codable, Hashable, Identifiable {
    var id: Int { hashValue }

    let title: String
    let description: String
    let targetMetric: String
    let sfSymbol: String
    let tintColor: String
    let startDate: Date
    let revisitDate: Date
    let goalValue: Double
    let goalUnit: String
}

extension SleepActivityModel {

    var color: Color {
        Color(hex: tintColor) ?? Color.accentColor
    }
}
