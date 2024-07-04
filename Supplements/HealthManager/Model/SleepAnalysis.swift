//
//  SleepAnalysis.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-25.
//

import Foundation
import OpenAPIClient

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
    let environmentalSoundLevels: [SoundLevelDataPoint]
    let heartRate: [HeartRateDataPoint]
}

extension SleepAnalysis {
    struct SoundLevelDataPoint: Codable, Hashable, Identifiable {
        var id: Int { hashValue }

        let decibelAWeightedSoundPressureLevelAverage: Double
        let startDate: Date
        let timeRangeSeconds: TimeInterval
    }
}

extension SleepAnalysis {
    struct HeartRateDataPoint: Codable, Hashable, Identifiable {
        var id: Int { hashValue }

        let averageHeartRate: Double
        let startDate: Date
        let timeRangeSeconds: TimeInterval
    }
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
        DateFormatter.justRelativeDateMedium.string(from: endDate)
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

    var sleepSummary: SleepSummary {
        SleepSummary(
            startDate: startDate,
            endDate: endDate,
            deepSleepMinutes: deepSleepMinutes,
            coreSleepMinutes: coreSleepMinutes,
            remSleepMinutes: remSleepMinutes,
            awakeSleepMinutes: awakeSleepMinutes
        )
    }
}

// MARK: - Previews

extension SleepAnalysis {

    static var previewData: [SleepAnalysis] {
        [
            .init(
                startDate: Date().addingTimeInterval(-3600*6),
                endDate: .now,
                deepSleepMinutes: 51,
                coreSleepMinutes: 290,
                remSleepMinutes: 98,
                awakeSleepMinutes: 25,
                environmentalSoundLevels: SleepAnalysis.SoundLevelDataPoint.previewData,
                heartRate: SleepAnalysis.HeartRateDataPoint.previewData
            ),
            .init(
                startDate: Date().addingTimeInterval(-(3600*6 + 86400)),
                endDate: .now.addingTimeInterval(-86400),
                deepSleepMinutes: 36,
                coreSleepMinutes: 250,
                remSleepMinutes: 67,
                awakeSleepMinutes: 40,
                environmentalSoundLevels: SleepAnalysis.SoundLevelDataPoint.previewData,
                heartRate: SleepAnalysis.HeartRateDataPoint.previewData
            ),
            .init(
                startDate: Date().addingTimeInterval(-(3600*6 + 86400*2)),
                endDate: .now.addingTimeInterval(-86400*2),
                deepSleepMinutes: 24,
                coreSleepMinutes: 300,
                remSleepMinutes: 48,
                awakeSleepMinutes: 52,
                environmentalSoundLevels: SleepAnalysis.SoundLevelDataPoint.previewData,
                heartRate: SleepAnalysis.HeartRateDataPoint.previewData
            ),
            .init(
                startDate: Date().addingTimeInterval(-(3600*6 + 86400*3)),
                endDate: .now.addingTimeInterval(-86400*3),
                deepSleepMinutes: 46,
                coreSleepMinutes: 260,
                remSleepMinutes: 48,
                awakeSleepMinutes: 12,
                environmentalSoundLevels: SleepAnalysis.SoundLevelDataPoint.previewData,
                heartRate: SleepAnalysis.HeartRateDataPoint.previewData
            ),
            .init(
                startDate: Date().addingTimeInterval(-(3600*6 + 86400*4)),
                endDate: .now.addingTimeInterval(-86400*4),
                deepSleepMinutes: 52,
                coreSleepMinutes: 274,
                remSleepMinutes: 41,
                awakeSleepMinutes: 23,
                environmentalSoundLevels: SleepAnalysis.SoundLevelDataPoint.previewData,
                heartRate: SleepAnalysis.HeartRateDataPoint.previewData
            ),
            .init(
                startDate: Date().addingTimeInterval(-(3600*6 + 86400*5)),
                endDate: .now.addingTimeInterval(-86400*5),
                deepSleepMinutes: 35,
                coreSleepMinutes: 293,
                remSleepMinutes: 53,
                awakeSleepMinutes: 36,
                environmentalSoundLevels: SleepAnalysis.SoundLevelDataPoint.previewData,
                heartRate: SleepAnalysis.HeartRateDataPoint.previewData
            ),
            .init(
                startDate: Date().addingTimeInterval(-(3600*6 + 86400*6)),
                endDate: .now.addingTimeInterval(-86400*6),
                deepSleepMinutes: 72,
                coreSleepMinutes: 312,
                remSleepMinutes: 69,
                awakeSleepMinutes: 18,
                environmentalSoundLevels: SleepAnalysis.SoundLevelDataPoint.previewData,
                heartRate: SleepAnalysis.HeartRateDataPoint.previewData
            )
        ]
    }
}

extension SleepAnalysis.SoundLevelDataPoint {

    static let previewData: [SleepAnalysis.SoundLevelDataPoint] = [
        SleepAnalysis.SoundLevelDataPoint(
            decibelAWeightedSoundPressureLevelAverage: 44,
            startDate: .now,
            timeRangeSeconds: 3600
        ),
        SleepAnalysis.SoundLevelDataPoint(
            decibelAWeightedSoundPressureLevelAverage: 45,
            startDate: Date(timeIntervalSinceNow: -3600),
            timeRangeSeconds: 3600
        ),
        SleepAnalysis.SoundLevelDataPoint(
            decibelAWeightedSoundPressureLevelAverage: 51,
            startDate: Date(timeIntervalSinceNow: -3600 * 2),
            timeRangeSeconds: 3600
        ),
        SleepAnalysis.SoundLevelDataPoint(
            decibelAWeightedSoundPressureLevelAverage: 48,
            startDate: Date(timeIntervalSinceNow: -3600 * 3),
            timeRangeSeconds: 3600
        ),
        SleepAnalysis.SoundLevelDataPoint(
            decibelAWeightedSoundPressureLevelAverage: 45,
            startDate: Date(timeIntervalSinceNow: -3600 * 4),
            timeRangeSeconds: 3600
        ),
        SleepAnalysis.SoundLevelDataPoint(
            decibelAWeightedSoundPressureLevelAverage: 48,
            startDate: Date(timeIntervalSinceNow: -3600 * 4),
            timeRangeSeconds: 3600
        ),
        SleepAnalysis.SoundLevelDataPoint(
            decibelAWeightedSoundPressureLevelAverage: 42,
            startDate: Date(timeIntervalSinceNow: -3600 * 5),
            timeRangeSeconds: 3600
        ),
        SleepAnalysis.SoundLevelDataPoint(
            decibelAWeightedSoundPressureLevelAverage: 51,
            startDate: Date(timeIntervalSinceNow: -3600 * 6),
            timeRangeSeconds: 3600
        ),
        SleepAnalysis.SoundLevelDataPoint(
            decibelAWeightedSoundPressureLevelAverage: 43,
            startDate: Date(timeIntervalSinceNow: -3600 * 7),
            timeRangeSeconds: 3600
        ),
        SleepAnalysis.SoundLevelDataPoint(
            decibelAWeightedSoundPressureLevelAverage: 48,
            startDate: Date(timeIntervalSinceNow: -3600 * 8),
            timeRangeSeconds: 3600
        ),
        SleepAnalysis.SoundLevelDataPoint(
            decibelAWeightedSoundPressureLevelAverage: 42,
            startDate: Date(timeIntervalSinceNow: -3600 * 9),
            timeRangeSeconds: 3600
        ),
        SleepAnalysis.SoundLevelDataPoint(
            decibelAWeightedSoundPressureLevelAverage: 39,
            startDate: Date(timeIntervalSinceNow: -3600 * 10),
            timeRangeSeconds: 3600
        )
    ]
}

extension SleepAnalysis.HeartRateDataPoint {

    static let previewData: [SleepAnalysis.HeartRateDataPoint] = [
        SleepAnalysis.HeartRateDataPoint(
            averageHeartRate: 56,
            startDate: .now,
            timeRangeSeconds: 900
        ),
        SleepAnalysis.HeartRateDataPoint(
            averageHeartRate: 58,
            startDate: Date(timeIntervalSinceNow: -900),
            timeRangeSeconds: 900
        ),
        SleepAnalysis.HeartRateDataPoint(
            averageHeartRate: 48,
            startDate: Date(timeIntervalSinceNow: -900 * 2),
            timeRangeSeconds: 900
        ),
        SleepAnalysis.HeartRateDataPoint(
            averageHeartRate: 57,
            startDate: Date(timeIntervalSinceNow: -900 * 3),
            timeRangeSeconds: 900
        ),
        SleepAnalysis.HeartRateDataPoint(
            averageHeartRate: 48,
            startDate: Date(timeIntervalSinceNow: -900 * 4),
            timeRangeSeconds: 900
        ),
        SleepAnalysis.HeartRateDataPoint(
            averageHeartRate: 43,
            startDate: Date(timeIntervalSinceNow: -900 * 5),
            timeRangeSeconds: 900
        ),
        SleepAnalysis.HeartRateDataPoint(
            averageHeartRate: 48,
            startDate: Date(timeIntervalSinceNow: -900 * 6),
            timeRangeSeconds: 900
        ),
    ]
}
