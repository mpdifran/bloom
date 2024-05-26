//
//  SleepAnalysis.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-25.
//

import Foundation

// https://www.mindbodygreen.com/articles/what-is-core-sleep
// https://www.healthline.com/health/how-much-deep-sleep-do-you-need#deep-sleep
extension Double {
    static let coreSleepPercent: Double = 0.50
    static let deepSleepPercent: Double = 0.25
    static let remSleepPercent: Double = 0.25
    static let minSleepLengthMinutes: Double = 7 * 60
    static let maxScore: Double = 10
}

struct SleepAnalysis: Codable, Hashable, Identifiable {
    var id: String { "\(startDate)-\(endDate)" }

    let startDate: Date
    let endDate: Date
    let deepSleepMinutes: Double
    let coreSleepMinutes: Double
    let remSleepMinutes: Double
    let awakeSleepMinutes: Double
}

extension SleepAnalysis {

    var beginningOfStartDate: Date {
        Calendar.current.startOfDay(for: startDate)
    }

    var endOfEndDate: Date {
        guard let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: endDate) else { return endDate }

        return Calendar.current.startOfDay(for: nextDay)
    }

    var timeInterval: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    var timeIntervalMinutes: TimeInterval {
        timeInterval / 60
    }

    var timeSpanDescription: String {
        if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
            return DateFormatter.justDateMedium.string(from: startDate)
        }
        return "\(DateFormatter.justDateMedium.string(from: startDate)) to \(DateFormatter.justDateMedium.string(from: endDate))"
    }

    var overallScore: Int {
        Int((Double(deepSleepScore + coreSleepScore + remSleepScore + sleepLengthScore) / 4).rounded(.towardZero))
    }

    var sleepLengthScore: Int {
        let percent = timeIntervalMinutes / .minSleepLengthMinutes
        return min(Int((percent * .maxScore).rounded(.towardZero)), Int(Double.maxScore))
    }

    var deepSleepScore: Int {
        let percent = deepSleepMinutes / timeIntervalMinutes
        return min(Int(((percent / .deepSleepPercent) * .maxScore).rounded(.towardZero)), Int(Double.maxScore))
    }

    var coreSleepScore: Int {
        let percent = coreSleepMinutes / timeIntervalMinutes
        return min(Int(((percent / .coreSleepPercent) * .maxScore).rounded(.towardZero)), Int(Double.maxScore))
    }

    var remSleepScore: Int {
        let percent = remSleepMinutes / timeIntervalMinutes
        return min(Int(((percent / .remSleepPercent) * .maxScore).rounded(.towardZero)), Int(Double.maxScore))
    }
}
