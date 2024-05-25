//
//  DateFormatter+Constants.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-25.
//

import Foundation

extension DateFormatter {

    static var standardMedium: DateFormatter = {
        let dateFormatter = DateFormatter()

        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium

        return dateFormatter
    }()
}
