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
    static let coreSleepPercentMin: Double = 0.2
    static let coreSleepPercentMax: Double = 0.45
    static let deepSleepPercentMin: Double = 0.05
    static let deepSleepPercentMax: Double = 0.15
    static let remSleepPercentMin: Double = 0.05
    static let remSleepPercentMax: Double = 0.20
    static let awakeSleepMinPercent: Double = 0.05
    static let awakeSleepMaxPercent: Double = 0.15
    static let zeroSleepLengthMinutes: Double = 4 * 60
    static let fullSleepLengthMinutes: Double = 8 * 60
    static let minSoundLevel: Double = 35
    static let maxSoundLevel: Double = 60
    static let maxRestingHeartRatePercent: Double = 0.9
    static let minHeartRate: Double = 60
    static let maxHeartRate: Double = 68
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
    let averageRestingHeartRate: Double?
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
        Int(overallScoreDouble.rounded(.towardZero))
    }

    var overallScoreDouble: Double {
        let components = [
            deepSleepScore,
            coreSleepScore,
            remSleepScore
        ].filter({ $0 < .maxScore * 0.999 })
        let componentAverage = components.isEmpty ? .maxScore : components.average(keyPath: \.self)

        return [
            sleepLengthScore,
            componentAverage,
            awakeSleepScore,
            heartRateScore
        ].average(keyPath: \.self)
    }

    var sleepLengthScore: Double {
        overallMinutes.scaledPercent(lower: .zeroSleepLengthMinutes, upper: .fullSleepLengthMinutes) * .maxScore
    }

    var awakeSleepScore: Double {
        let percent = awakeSleepMinutes / overallMinutes
        return percent.scaledPercent(lower: .awakeSleepMaxPercent, upper: .awakeSleepMinPercent) * .maxScore
    }

    var deepSleepScore: Double {
        let percent = deepSleepMinutes / overallMinutes
        return percent.scaledPercent(lower: .deepSleepPercentMin, upper: .deepSleepPercentMax) * .maxScore
    }

    var coreSleepScore: Double {
        let percent = coreSleepMinutes / overallMinutes
        return percent.scaledPercent(lower: .coreSleepPercentMin, upper: .coreSleepPercentMax) * .maxScore
    }

    var remSleepScore: Double {
        let percent = remSleepMinutes / overallMinutes
        return percent.scaledPercent(lower: .remSleepPercentMin, upper: .remSleepPercentMax) * .maxScore
    }

    var averageSoundLevel: Double {
        environmentalSoundLevels.average(keyPath: \.decibelAWeightedSoundPressureLevelAverage)
    }

    var soundLevelScore: Double {
        averageSoundLevel.scaledPercent(lower: .maxSoundLevel, upper: .minSoundLevel) * .maxScore
    }

    var averageHeartRate: Double {
        heartRate.average(keyPath: \.averageHeartRate)
    }

    var heartRateScore: Double {
        if let averageRestingHeartRate {
            return averageHeartRate.scaledPercent(
                lower: averageRestingHeartRate,
                upper: averageRestingHeartRate * .maxRestingHeartRatePercent
            ) * .maxScore
        }
        return averageHeartRate.scaledPercent(
            lower: .maxHeartRate,
            upper: .minHeartRate
        ) * .maxScore
    }
}

extension SleepAnalysis {

    var sleepQuality: VitalStatusData.Mode {
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
                averageRestingHeartRate: 65,
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
                averageRestingHeartRate: 65,
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
                averageRestingHeartRate: 65,
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
                averageRestingHeartRate: 65,
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
                averageRestingHeartRate: 65,
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
                averageRestingHeartRate: 65,
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
                averageRestingHeartRate: 65,
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
