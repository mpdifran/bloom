//
//  DateComponents+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-03.
//

import Foundation

extension DateComponents {

    var calendarComponents: Set<Calendar.Component> {
        var componentsSet = Set<Calendar.Component>()
        if year != nil { componentsSet.insert(.year) }
        if month != nil { componentsSet.insert(.month) }
        if day != nil { componentsSet.insert(.day) }
        if hour != nil { componentsSet.insert(.hour) }
        if minute != nil { componentsSet.insert(.minute) }
        if second != nil { componentsSet.insert(.second) }
        return componentsSet
    }
}

extension DateComponents: Comparable {

    public static func < (lhs: DateComponents, rhs: DateComponents) -> Bool {
        if let lhsYear = lhs.year, let rhsYear = rhs.year, lhsYear != rhsYear {
            return lhsYear < rhsYear
        }
        if let lhsMonth = lhs.month, let rhsMonth = rhs.month, lhsMonth != rhsMonth {
            return lhsMonth < rhsMonth
        }
        if let lhsDay = lhs.day, let rhsDay = rhs.day, lhsDay != rhsDay {
            return lhsDay < rhsDay
        }
        if let lhsHour = lhs.hour, let rhsHour = rhs.hour, lhsHour != rhsHour {
            return lhsHour < rhsHour
        }
        if let lhsMinute = lhs.minute, let rhsMinute = rhs.minute, lhsMinute != rhsMinute {
            return lhsMinute < rhsMinute
        }
        if let lhsSecond = lhs.second, let rhsSecond = rhs.second, lhsSecond != rhsSecond {
            return lhsSecond < rhsSecond
        }
        // If all components are equal or nil, consider them equal
        return false
    }

    public static func == (lhs: DateComponents, rhs: DateComponents) -> Bool {
        return lhs.year == rhs.year &&
               lhs.month == rhs.month &&
               lhs.day == rhs.day &&
               lhs.hour == rhs.hour &&
               lhs.minute == rhs.minute &&
               lhs.second == rhs.second
    }
}
