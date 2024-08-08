//
//  GoalModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-31.
//

import SwiftUI

struct GoalModel: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let systemImage: String
    let summary: String
    let dueDate: Date
    let metric: Metric
    let vitalKind: VitalModel.Kind

    init(
        id: UUID = UUID(),
        title: String,
        systemImage: String,
        summary: String,
        dueDate: Date,
        metric: Metric,
        vitalKind: VitalModel.Kind
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.summary = summary
        self.dueDate = dueDate
        self.metric = metric
        self.vitalKind = vitalKind
    }
}

extension GoalModel {
    struct Metric: Hashable, Codable {
        let value: Double
        let measurement: MeasurementMetric
    }
}

extension GoalModel {
    enum MeasurementMetric: Codable {
        case timeInDaylight
        case walkRunDistance
        case walkDuration
        case runDistance
        case runDuration
        case bikeDistance
        case bikeDuration
        case walkRunBikeDistance
        case walkRunBikeDuration
        case stepCount
        case meditationMinutes
        case bedtimeSoundLevels
        case yogaWorkoutDuration
        case casualSportWorkoutDuration
        case intenseSportWorkoutDuration
        case gymTrainingWorkoutDuration
        case HIITTrainingWorkoutDuration
        case targetHeartRateZoneProportionsZone2
        case targetHeartRateZoneProportionsZone3
        case targetHeartRateZoneProportionsZone4
        case targetHeartRateZoneProportionsZone5
        case increaseProtein
        case increaseCarbs
        case increaseFat
        case increaseVitaminA
        case increaseVitaminB6
        case increaseVitaminB12
        case increaseVitaminC
        case increaseVitaminD
        case increaseVitaminE

        var color: Color {
            switch self {
            case .timeInDaylight:
                    .orange
            case .walkRunDistance, .runDistance, .bikeDistance, .walkRunBikeDistance:
                    .green
            case .walkDuration, .runDuration, .bikeDuration, .walkRunBikeDuration:
                    .pink
            case .stepCount:
                    .indigo
            case .meditationMinutes:
                    .remSleep
            case .bedtimeSoundLevels:
                    .yellow
            case .yogaWorkoutDuration:
                    .awakeSleep
            case .casualSportWorkoutDuration:
                    .blue
            case .intenseSportWorkoutDuration:
                    .orange
            case .gymTrainingWorkoutDuration, .HIITTrainingWorkoutDuration:
                    .purple
            case .targetHeartRateZoneProportionsZone2, .targetHeartRateZoneProportionsZone3, .targetHeartRateZoneProportionsZone4, .targetHeartRateZoneProportionsZone5:
                    .pink
            case .increaseProtein:
                    .protein
            case .increaseCarbs:
                    .carbohydrates
            case .increaseFat:
                    .fat
            case .increaseVitaminA:
                    .vitaminA
            case .increaseVitaminB6:
                    .vitaminB6
            case .increaseVitaminB12:
                    .vitaminB12
            case .increaseVitaminC:
                    .vitaminC
            case .increaseVitaminD:
                    .vitaminD
            case .increaseVitaminE:
                    .vitaminE
            }
        }
    }
}
