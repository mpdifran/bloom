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
    static let coreSleepPercent: Double = 0.45
    static let deepSleepPercent: Double = 0.15
    static let remSleepPercent: Double = 0.20
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

    var timeSpanDescription: String {
        if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
            return DateFormatter.monthAndDay.string(from: startDate)
        }
        return "\(DateFormatter.monthAndDay.string(from: startDate)) - \(DateFormatter.monthAndDay.string(from: endDate))"
    }

    var name: String {
        DateFormatter.justDayOfWeek.string(from: endDate)
    }

    var overallMinutesIncludingAwake: Double {
        timeInterval / 60
    }

    var overallHoursIncludingAwake: Double {
        overallMinutesIncludingAwake / 60
    }

    var overallMinutes: Double {
        overallMinutesIncludingAwake - awakeSleepMinutes
    }

    var overallHours: Double {
        // Should we include awake time in the total?
        overallHoursIncludingAwake //- awakeSleepHours
    }

    var coreSleepHours: Double {
        coreSleepMinutes / 60
    }

    var remSleepHours: Double {
        remSleepMinutes / 60
    }

    var deepSleepHours: Double {
        deepSleepMinutes / 60
    }

    var awakeSleepHours: Double {
        awakeSleepMinutes / 60
    }

    var coreSleepPercent: Double {
        coreSleepMinutes / overallMinutes
    }

    var remSleepPercent: Double {
        remSleepMinutes / overallMinutes
    }

    var deepSleepPercent: Double {
        deepSleepMinutes / overallMinutes
    }

    var awakeSleepPercent: Double {
        awakeSleepMinutes / overallMinutes
    }

    var overallScore: Int {
        Int((Double(deepSleepScore + coreSleepScore + remSleepScore + sleepLengthScore) / 4).rounded(.towardZero))
    }

    var sleepLengthScore: Int {
        let percent = overallMinutes / .minSleepLengthMinutes
        return min(Int((percent * .maxScore).rounded(.towardZero)), Int(Double.maxScore))
    }

    var deepSleepScore: Int {
        let percent = deepSleepMinutes / overallMinutes
        return min(Int(((percent / .deepSleepPercent) * .maxScore).rounded(.towardZero)), Int(Double.maxScore))
    }

    var coreSleepScore: Int {
        let percent = coreSleepMinutes / overallMinutes
        return min(Int(((percent / .coreSleepPercent) * .maxScore).rounded(.towardZero)), Int(Double.maxScore))
    }

    var remSleepScore: Int {
        let percent = remSleepMinutes / overallMinutes
        return min(Int(((percent / .remSleepPercent) * .maxScore).rounded(.towardZero)), Int(Double.maxScore))
    }
}

extension SleepAnalysis {

    static var previewData: [SleepAnalysis] {
        [
            .init(
                startDate: Date().addingTimeInterval(-3600*6),
                endDate: .now,
                deepSleepMinutes: 51,
                coreSleepMinutes: 290,
                remSleepMinutes: 98,
                awakeSleepMinutes: 25
            ),
            .init(
                startDate: Date().addingTimeInterval(-(3600*6 + 86400)),
                endDate: .now.addingTimeInterval(-86400),
                deepSleepMinutes: 36,
                coreSleepMinutes: 250,
                remSleepMinutes: 67,
                awakeSleepMinutes: 40
            ),
            .init(
                startDate: Date().addingTimeInterval(-(3600*6 + 86400*2)),
                endDate: .now.addingTimeInterval(-86400*2),
                deepSleepMinutes: 24,
                coreSleepMinutes: 300,
                remSleepMinutes: 48,
                awakeSleepMinutes: 52
            ),
            .init(
                startDate: Date().addingTimeInterval(-(3600*6 + 86400*3)),
                endDate: .now.addingTimeInterval(-86400*3),
                deepSleepMinutes: 46,
                coreSleepMinutes: 260,
                remSleepMinutes: 48,
                awakeSleepMinutes: 12
            ),
            .init(
                startDate: Date().addingTimeInterval(-(3600*6 + 86400*4)),
                endDate: .now.addingTimeInterval(-86400*4),
                deepSleepMinutes: 52,
                coreSleepMinutes: 274,
                remSleepMinutes: 41,
                awakeSleepMinutes: 23
            ),
            .init(
                startDate: Date().addingTimeInterval(-(3600*6 + 86400*5)),
                endDate: .now.addingTimeInterval(-86400*5),
                deepSleepMinutes: 35,
                coreSleepMinutes: 293,
                remSleepMinutes: 53,
                awakeSleepMinutes: 36
            ),
            .init(
                startDate: Date().addingTimeInterval(-(3600*6 + 86400*6)),
                endDate: .now.addingTimeInterval(-86400*6),
                deepSleepMinutes: 72,
                coreSleepMinutes: 312,
                remSleepMinutes: 69,
                awakeSleepMinutes: 18
            )
        ]
    }
}
