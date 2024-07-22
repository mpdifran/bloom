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
    static let awakeSleepMinPercent: Double = 0.05
    static let awakeSleepMaxPercent: Double = 0.25
    static let zeroSleepLengthMinutes: Double = 4 * 60
    static let fullSleepLengthMinutes: Double = 8 * 60
    static let minSoundLevel: Double = 35
    static let maxSoundLevel: Double = 60
    static let minHeartRate: Double = 60
    static let maxHeartRate: Double = 75
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
    let respiratoryRate: [RespiratoryRateDataPoint]
    let wristTemperature: [WristTemperatureDataPoint]
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
    struct RespiratoryRateDataPoint: Codable, Hashable, Identifiable {
        var id: Int { hashValue }

        let averageRespiratoryRate: Double
        let startDate: Date
        let timeRangeSeconds: TimeInterval
    }
}

extension SleepAnalysis {
    struct WristTemperatureDataPoint: Codable, Hashable, Identifiable {
        var id: Int { hashValue }

        let averageWristTemperature: Double
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
        overallHoursIncludingAwake - awakeSleepHours
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
        let average = [
            deepSleepScore,
            coreSleepScore,
            remSleepScore,
            sleepLengthScore,
            soundLevelScore,
            heartRateScore
        ].average(keyPath: \.self)
        return Int(average.rounded(.towardZero))
    }

    var sleepLengthScore: Double {
        let percent = (overallMinutes - .zeroSleepLengthMinutes) / (.fullSleepLengthMinutes - .zeroSleepLengthMinutes)
        return max(min((percent * .maxScore), .maxScore), 0)
    }

    var awakeSleepScore: Double {
        let percent = awakeSleepMinutes / overallMinutes
        let proposedScore = 1 - ((percent - .awakeSleepMinPercent) / .awakeSleepMaxPercent)
        return min(max((proposedScore * .maxScore), 0), .maxScore)
    }

    var deepSleepScore: Double {
        let percent = deepSleepMinutes / overallMinutes
        return min(((percent / .deepSleepPercent) * .maxScore), .maxScore)
    }

    var coreSleepScore: Double {
        let percent = coreSleepMinutes / overallMinutes
        return min(((percent / .coreSleepPercent) * .maxScore), .maxScore)
    }

    var remSleepScore: Double {
        let percent = remSleepMinutes / overallMinutes
        return min(((percent / .remSleepPercent) * .maxScore), .maxScore)
    }

    var averageSoundLevel: Double {
        environmentalSoundLevels.average(keyPath: \.decibelAWeightedSoundPressureLevelAverage)
    }

    var soundLevelScore: Double {
        let percent = (averageSoundLevel - .minSoundLevel) / (.maxSoundLevel - .minSoundLevel)
        let proposedScore = max(min(1, 1 - percent), 0)
        return proposedScore * .maxScore
    }

    var averageHeartRate: Double {
        heartRate.average(keyPath: \.averageHeartRate)
    }

    var heartRateScore: Double {
        let percent = (averageHeartRate - .minHeartRate) / (.maxHeartRate - .minHeartRate)
        let proposedScore = max(min(1, 1 - percent), 0)
        return proposedScore * .maxScore
    }
}

extension SleepAnalysis {

    var sleepQuality: VitalStatusCell.Mode {
        switch overallScore {
        case 0 ..< 4: .threat
        case 4 ..< 7: .warning
        case 7 ..< 9: .good
        default: .excel
        }
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
                startDate: Date().addingTimeInterval(-3600*8),
                endDate: .now,
                deepSleepMinutes: 51,
                coreSleepMinutes: 290,
                remSleepMinutes: 98,
                awakeSleepMinutes: 25,
                environmentalSoundLevels: SleepAnalysis.SoundLevelDataPoint.previewData,
                heartRate: SleepAnalysis.HeartRateDataPoint.previewData,
                respiratoryRate: SleepAnalysis.RespiratoryRateDataPoint.previewData,
                wristTemperature: SleepAnalysis.WristTemperatureDataPoint.previewData
            ),
            .init(
                startDate: Date().addingTimeInterval(-(3600*6 + 86400)),
                endDate: .now.addingTimeInterval(-86400),
                deepSleepMinutes: 36,
                coreSleepMinutes: 250,
                remSleepMinutes: 67,
                awakeSleepMinutes: 40,
                environmentalSoundLevels: SleepAnalysis.SoundLevelDataPoint.previewData,
                heartRate: SleepAnalysis.HeartRateDataPoint.previewData,
                respiratoryRate: SleepAnalysis.RespiratoryRateDataPoint.previewData,
                wristTemperature: SleepAnalysis.WristTemperatureDataPoint.previewData
            ),
            .init(
                startDate: Date().addingTimeInterval(-(3600*6 + 86400*2)),
                endDate: .now.addingTimeInterval(-86400*2),
                deepSleepMinutes: 24,
                coreSleepMinutes: 300,
                remSleepMinutes: 48,
                awakeSleepMinutes: 52,
                environmentalSoundLevels: SleepAnalysis.SoundLevelDataPoint.previewData,
                heartRate: SleepAnalysis.HeartRateDataPoint.previewData,
                respiratoryRate: SleepAnalysis.RespiratoryRateDataPoint.previewData,
                wristTemperature: SleepAnalysis.WristTemperatureDataPoint.previewData
            ),
            .init(
                startDate: Date().addingTimeInterval(-(3600*6 + 86400*3)),
                endDate: .now.addingTimeInterval(-86400*3),
                deepSleepMinutes: 46,
                coreSleepMinutes: 260,
                remSleepMinutes: 48,
                awakeSleepMinutes: 12,
                environmentalSoundLevels: SleepAnalysis.SoundLevelDataPoint.previewData,
                heartRate: SleepAnalysis.HeartRateDataPoint.previewData,
                respiratoryRate: SleepAnalysis.RespiratoryRateDataPoint.previewData,
                wristTemperature: SleepAnalysis.WristTemperatureDataPoint.previewData
            ),
            .init(
                startDate: Date().addingTimeInterval(-(3600*6 + 86400*4)),
                endDate: .now.addingTimeInterval(-86400*4),
                deepSleepMinutes: 52,
                coreSleepMinutes: 274,
                remSleepMinutes: 41,
                awakeSleepMinutes: 23,
                environmentalSoundLevels: SleepAnalysis.SoundLevelDataPoint.previewData,
                heartRate: SleepAnalysis.HeartRateDataPoint.previewData,
                respiratoryRate: SleepAnalysis.RespiratoryRateDataPoint.previewData,
                wristTemperature: SleepAnalysis.WristTemperatureDataPoint.previewData
            ),
            .init(
                startDate: Date().addingTimeInterval(-(3600*6 + 86400*5)),
                endDate: .now.addingTimeInterval(-86400*5),
                deepSleepMinutes: 35,
                coreSleepMinutes: 293,
                remSleepMinutes: 53,
                awakeSleepMinutes: 36,
                environmentalSoundLevels: SleepAnalysis.SoundLevelDataPoint.previewData,
                heartRate: SleepAnalysis.HeartRateDataPoint.previewData,
                respiratoryRate: SleepAnalysis.RespiratoryRateDataPoint.previewData,
                wristTemperature: SleepAnalysis.WristTemperatureDataPoint.previewData
            ),
            .init(
                startDate: Date().addingTimeInterval(-(3600*6 + 86400*6)),
                endDate: .now.addingTimeInterval(-86400*6),
                deepSleepMinutes: 72,
                coreSleepMinutes: 312,
                remSleepMinutes: 69,
                awakeSleepMinutes: 18,
                environmentalSoundLevels: SleepAnalysis.SoundLevelDataPoint.previewData,
                heartRate: SleepAnalysis.HeartRateDataPoint.previewData,
                respiratoryRate: SleepAnalysis.RespiratoryRateDataPoint.previewData,
                wristTemperature: SleepAnalysis.WristTemperatureDataPoint.previewData
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

extension SleepAnalysis.RespiratoryRateDataPoint {

    static let previewData: [SleepAnalysis.RespiratoryRateDataPoint] = [
        SleepAnalysis.RespiratoryRateDataPoint(
            averageRespiratoryRate: 12,
            startDate: .now,
            timeRangeSeconds: 900
        ),
        SleepAnalysis.RespiratoryRateDataPoint(
            averageRespiratoryRate: 15,
            startDate: Date(timeIntervalSinceNow: -900),
            timeRangeSeconds: 900
        ),
        SleepAnalysis.RespiratoryRateDataPoint(
            averageRespiratoryRate: 14,
            startDate: Date(timeIntervalSinceNow: -900 * 2),
            timeRangeSeconds: 900
        ),
        SleepAnalysis.RespiratoryRateDataPoint(
            averageRespiratoryRate: 11,
            startDate: Date(timeIntervalSinceNow: -900 * 3),
            timeRangeSeconds: 900
        ),
        SleepAnalysis.RespiratoryRateDataPoint(
            averageRespiratoryRate: 16,
            startDate: Date(timeIntervalSinceNow: -900 * 4),
            timeRangeSeconds: 900
        ),
        SleepAnalysis.RespiratoryRateDataPoint(
            averageRespiratoryRate: 14,
            startDate: Date(timeIntervalSinceNow: -900 * 5),
            timeRangeSeconds: 900
        ),
        SleepAnalysis.RespiratoryRateDataPoint(
            averageRespiratoryRate: 12,
            startDate: Date(timeIntervalSinceNow: -900 * 6),
            timeRangeSeconds: 900
        ),
    ]
}

extension SleepAnalysis.WristTemperatureDataPoint {

    static let previewData: [SleepAnalysis.WristTemperatureDataPoint] = [
        SleepAnalysis.WristTemperatureDataPoint(
            averageWristTemperature: 96,
            startDate: .now,
            timeRangeSeconds: 900
        ),
        SleepAnalysis.WristTemperatureDataPoint(
            averageWristTemperature: 94,
            startDate: Date(timeIntervalSinceNow: -900),
            timeRangeSeconds: 900
        ),
        SleepAnalysis.WristTemperatureDataPoint(
            averageWristTemperature: 95,
            startDate: Date(timeIntervalSinceNow: -900 * 2),
            timeRangeSeconds: 900
        ),
        SleepAnalysis.WristTemperatureDataPoint(
            averageWristTemperature: 96,
            startDate: Date(timeIntervalSinceNow: -900 * 3),
            timeRangeSeconds: 900
        ),
        SleepAnalysis.WristTemperatureDataPoint(
            averageWristTemperature: 98,
            startDate: Date(timeIntervalSinceNow: -900 * 4),
            timeRangeSeconds: 900
        ),
        SleepAnalysis.WristTemperatureDataPoint(
            averageWristTemperature: 95,
            startDate: Date(timeIntervalSinceNow: -900 * 5),
            timeRangeSeconds: 900
        ),
        SleepAnalysis.WristTemperatureDataPoint(
            averageWristTemperature: 94,
            startDate: Date(timeIntervalSinceNow: -900 * 6),
            timeRangeSeconds: 900
        )
    ]
}
