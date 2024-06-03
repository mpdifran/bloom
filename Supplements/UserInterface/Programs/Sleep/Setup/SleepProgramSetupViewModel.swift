//
//  SleepProgramSetupViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-03.
//

import SwiftUI

final class SleepProgramSetupViewModel: ObservableObject {
    @Published var sleepAnalyses = [SleepAnalysis]()
    @Published var segmentSummary = [SleepSegmentSummary]()
}

extension SleepProgramSetupViewModel {

    func loadData() async {
        let sleepAnalyses = await HealthManager.shared.fetchDailySleepAnalysis(period: 28)
        let segmentSummary = generateSummaries(sleepAnalyses: sleepAnalyses)

        await MainActor.run {
            self.sleepAnalyses = sleepAnalyses
            self.segmentSummary = segmentSummary
        }
    }

    func generateSummaries(sleepAnalyses: [SleepAnalysis]) -> [SleepSegmentSummary] {
        [
            generateSummary(
                sleepAnalyses: sleepAnalyses,
                segment: .deep,
                hoursKeyPath: \.deepSleepHours,
                percentKeyPath: \.deepSleepPercent,
                recommendedMinPercent: 0.15,
                recommendedMaxPercent: 0.25
            ),
            generateSummary(
                sleepAnalyses: sleepAnalyses,
                segment: .core,
                hoursKeyPath: \.coreSleepHours,
                percentKeyPath: \.coreSleepPercent,
                recommendedMinPercent: 0.45,
                recommendedMaxPercent: 0.55
            ),
            generateSummary(
                sleepAnalyses: sleepAnalyses,
                segment: .rem,
                hoursKeyPath: \.remSleepHours,
                percentKeyPath: \.remSleepPercent,
                recommendedMinPercent: 0.2,
                recommendedMaxPercent: 0.25
            ),
            generateSummary(
                sleepAnalyses: sleepAnalyses,
                segment: .awake,
                hoursKeyPath: \.awakeSleepHours,
                percentKeyPath: \.awakeSleepPercent,
                recommendedMinPercent: 0,
                recommendedMaxPercent: 0.05
            )
        ]
    }

    func generateSummary(
        sleepAnalyses: [SleepAnalysis],
        segment: SleepSegmentSummary.Segment,
        hoursKeyPath: KeyPath<SleepAnalysis, Double>,
        percentKeyPath: KeyPath<SleepAnalysis, Double>,
        recommendedMinPercent: Double,
        recommendedMaxPercent: Double
    ) -> SleepSegmentSummary {
        let analysesWithValues = sleepAnalyses
            .filter({ $0[keyPath: hoursKeyPath] > 0.0001 }) // One second in hours is 0.0002777

        let averagePercent = analysesWithValues.average(keyPath: percentKeyPath)
        let percentNightsWithValues = Double(analysesWithValues.count) / Double(sleepAnalyses.count)

        return SleepSegmentSummary(
            segment: segment,
            averagePercent: averagePercent,
            recommendedPercentMin: recommendedMinPercent,
            recommendedPercentMax: recommendedMaxPercent,
            percentNightsWithValues: percentNightsWithValues,
            dataPoints: sleepAnalyses.map { SleepSegmentSummary.DataPoint(date: $0.endDate, value: $0[keyPath: hoursKeyPath]) }
        )
    }
}
