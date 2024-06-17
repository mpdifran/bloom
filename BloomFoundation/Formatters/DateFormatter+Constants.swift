//
//  DateFormatter+Constants.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-25.
//

import Foundation

public extension DateFormatter {

    static var standardMedium: DateFormatter = {
        let dateFormatter = DateFormatter()

        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium

        return dateFormatter
    }()

    static var justDateMedium: DateFormatter = {
        let dateFormatter = DateFormatter()

        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        return dateFormatter
    }()

    static var justDateLong: DateFormatter = {
        let dateFormatter = DateFormatter()

        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none

        return dateFormatter
    }()

    static var justRelativeDateMedium: DateFormatter = {
        let dateFormatter = DateFormatter()

        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.doesRelativeDateFormatting = true

        return dateFormatter
    }()

    static var monthAndDay: DateFormatter = {
        let dateFormatter = DateFormatter()

        dateFormatter.setLocalizedDateFormatFromTemplate("MMM dd")

        return dateFormatter
    }()

    static var justDayOfWeek: DateFormatter = {
        let dateFormatter = DateFormatter()

        dateFormatter.setLocalizedDateFormatFromTemplate("EEEE")

        return dateFormatter
    }()

    static var timeIntervalHourMinuteShort: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()

        formatter.unitsStyle = .short
        formatter.allowedUnits = [.hour, .minute]

        return formatter
    }()

    static var timeIntervalHourMinuteSecondShort: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()

        formatter.unitsStyle = .short
        formatter.allowedUnits = [.hour, .minute, .second]

        return formatter
    }()
}
