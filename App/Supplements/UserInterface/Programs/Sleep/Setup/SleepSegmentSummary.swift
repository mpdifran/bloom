//
//  SleepSegmentSummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-03.
//

import SwiftUI

extension SleepSegmentSummary {
    enum Segment: String {
        case awake
        case rem
        case core
        case deep
    }
}

struct SleepSegmentSummary: Identifiable {
    var id: Segment { segment }

    let segment: Segment
    let averagePercent: Double
    let recommendedPercentMin: Double
    let recommendedPercentMax: Double
    let percentNightsWithValues: Double
    let dataPoints: [DataPoint]
}

extension SleepSegmentSummary {

    var name: String {
        switch segment {
        case .awake: "Awake"
        case .rem: "REM Sleep"
        case .core: "Core Sleep"
        case .deep: "Deep Sleep"
        }
    }

    var color: Color {
        switch segment {
        case .awake: return .awakeSleep
        case .rem: return .remSleep
        case .core: return .coreSleep
        case .deep: return .deepSleep
        }
    }

    var verticalGradient: LinearGradient {
        LinearGradient(
            colors: [color.lighter(by: 0.5), color],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

extension SleepSegmentSummary {
    struct DataPoint: Identifiable {
        var id: String { "\(date) - \(value)" }

        let date: Date
        let value: Double
    }
}
