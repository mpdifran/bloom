//
//  DateFormatter+Constants.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-25.
//

import Foundation

public extension DateFormatter {

    static var dateTimeShort: DateFormatter = {
        let dateFormatter = DateFormatter()

        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short

        return dateFormatter
    }()

    static var dateTimeMedium: DateFormatter = {
        let dateFormatter = DateFormatter()

        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium

        return dateFormatter
    }()

    static var justTimeShort: DateFormatter = {
        let dateFormatter = DateFormatter()

        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short

        return dateFormatter
    }()

    static var justDateMedium: DateFormatter = {
        let dateFormatter = DateFormatter()

        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        return dateFormatter
    }()

    static var justDateShort: DateFormatter = {
        let dateFormatter = DateFormatter()

        dateFormatter.dateStyle = .short
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

    static var relativeDateTimeMedium: DateFormatter = {
        let dateFormatter = DateFormatter()

        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        dateFormatter.doesRelativeDateFormatting = true

        return dateFormatter
    }()

    static var relativeDateTimeShort: DateFormatter = {
        let dateFormatter = DateFormatter()

        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true

        return dateFormatter
    }()

    static var justFullMonth: DateFormatter = {
        let dateFormatter = DateFormatter()

        dateFormatter.setLocalizedDateFormatFromTemplate("MMMM")

        return dateFormatter
    }()

    static var fullMonthAndYear: DateFormatter = {
        let dateFormatter = DateFormatter()

        dateFormatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")

        return dateFormatter
    }()

    static var monthAndDay: DateFormatter = {
        let dateFormatter = DateFormatter()

        dateFormatter.setLocalizedDateFormatFromTemplate("MMM d")

        return dateFormatter
    }()

    static var justDayOfWeek: DateFormatter = {
        let dateFormatter = DateFormatter()

        dateFormatter.setLocalizedDateFormatFromTemplate("EEEE")

        return dateFormatter
    }()

    static var justDayOfWeekShort: DateFormatter = {
        let dateFormatter = DateFormatter()

        dateFormatter.setLocalizedDateFormatFromTemplate("E")

        return dateFormatter
    }()

    static var timeIntervalHourMinuteShort: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()

        formatter.unitsStyle = .short
        formatter.allowedUnits = [.hour, .minute]

        return formatter
    }()

    static var timeIntervalHourMinuteFull: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()

        formatter.unitsStyle = .full
        formatter.allowedUnits = [.hour, .minute]

        return formatter
    }()

    static var timeIntervalHourMinuteSecondShort: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()

        formatter.unitsStyle = .short
        formatter.allowedUnits = [.hour, .minute, .second]

        return formatter
    }()

    static var timeIntervalDaysFull: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()

        formatter.unitsStyle = .full
        formatter.allowedUnits = [.day]

        return formatter
    }()

    static func relativeTimeIntervalDaysFullFromNow(_ date: Date) -> String {
        if
            Calendar.current.isDateInToday(date) ||
            Calendar.current.isDateInTomorrow(date) ||
            Calendar.current.isDateInYesterday(date)
        {
            return justRelativeDateMedium.string(from: date)
        }
        return "in " + (timeIntervalDaysFull.string(from: .now, to: date) ?? "")
    }
}
