//
//  DateFormatter+Constants.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-25.
//

import Foundation

public extension DateFormatter {

    static let dateTimeShort = DateFormatter().with {
        $0.dateStyle = .short
        $0.timeStyle = .short
    }

    static let dateTimeMedium = DateFormatter().with {
        $0.dateStyle = .medium
        $0.timeStyle = .medium
    }

    static let justTimeShort = DateFormatter().with {
        $0.dateStyle = .none
        $0.timeStyle = .short
    }

    static let justDateMedium = DateFormatter().with {
        $0.dateStyle = .medium
        $0.timeStyle = .none
    }

    static let justDateShort = DateFormatter().with {
        $0.dateStyle = .short
        $0.timeStyle = .none
    }

    static let justDateLong = DateFormatter().with {
        $0.dateStyle = .long
        $0.timeStyle = .none
    }

    static let justRelativeDateMedium = DateFormatter().with {
        $0.dateStyle = .medium
        $0.timeStyle = .none
        $0.doesRelativeDateFormatting = true
    }

    static let relativeDateTimeMedium = DateFormatter().with {
        $0.dateStyle = .medium
        $0.timeStyle = .medium
        $0.doesRelativeDateFormatting = true
    }

    static let relativeDateTimeShort = DateFormatter().with {
        $0.dateStyle = .short
        $0.timeStyle = .short
        $0.doesRelativeDateFormatting = true
    }

    static let justFullMonth = DateFormatter().with {
        $0.setLocalizedDateFormatFromTemplate("MMMM")
    }

    static let fullMonthAndYear = DateFormatter().with {
        $0.setLocalizedDateFormatFromTemplate("MMMM yyyy")
    }

    static let monthAndDay = DateFormatter().with {
        $0.setLocalizedDateFormatFromTemplate("MMM d")
    }

    static let justDayOfWeek = DateFormatter().with {
        $0.setLocalizedDateFormatFromTemplate("EEEE")
    }

    static let justDayOfWeekShort = DateFormatter().with {
        $0.setLocalizedDateFormatFromTemplate("E")
    }

    static let timeIntervalHourMinuteShort = DateComponentsFormatter().with {
        $0.unitsStyle = .short
        $0.allowedUnits = [.hour, .minute]
    }

    static let timeIntervalHourMinuteFull = DateComponentsFormatter().with {
        $0.unitsStyle = .full
        $0.allowedUnits = [.hour, .minute]
    }

    static let timeIntervalHourMinuteSecondShort = DateComponentsFormatter().with {
        $0.unitsStyle = .short
        $0.allowedUnits = [.hour, .minute, .second]
    }

    static let timeIntervalDaysFull = DateComponentsFormatter().with {
        $0.unitsStyle = .full
        $0.allowedUnits = [.day]
    }

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
