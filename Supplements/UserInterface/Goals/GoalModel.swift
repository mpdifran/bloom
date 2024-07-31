//
//  GoalModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-31.
//

import SwiftUI

struct GoalModel: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let systemImage: String
    let summary: String
    let color: Color
    let metric: Metric
    let vitalKind: VitalModel.Kind
}

extension GoalModel {
    struct Metric: Hashable {
        let value: Double
        let measurement: MeasurementMetric
    }
}

extension GoalModel {
    enum MeasurementMetric {
        case timeInDaylight
        case walkWheelDistance
        case walkWheelDuration
        case runWheelDistance
        case runWheelDuration
        case bikeDistance
        case bikeDuration
        case walkRunBikeWheelDistance
        case walkRunBikeWheelDuration
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
    }
}
