//
//  Int+ScoreColor.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-25.
//

import SwiftUI

extension Int {
    var scoreColor: Color {
        switch self {
        case 0, 1, 2, 3:
            return .red
        case 4, 5, 6, 7:
            return .orange
        default:
            return .green
        }
    }
}
