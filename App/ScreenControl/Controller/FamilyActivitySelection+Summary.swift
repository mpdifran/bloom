//
//  FamilyActivitySelection+Summary.swift
//  ScreenControl
//
//  Created by Mark DiFranco on 2024-06-02.
//

import Foundation
import FamilyControls

public extension FamilyActivitySelection {

    var summaryText: String? {
        var descriptions = [String]()
        if !applicationTokens.isEmpty {
            descriptions.append("\(applicationTokens.count) \(applicationTokens.count == 1 ? "App" : "Apps")")
        }
        if !categoryTokens.isEmpty {
            descriptions.append("\(categoryTokens.count) \(categoryTokens.count == 1 ? "Category" : "Categories")")
        }
        if !descriptions.isEmpty, let formatted = ListFormatter.main.string(from: descriptions) {
            return formatted + " Selected"
        }

        return nil
    }
}
