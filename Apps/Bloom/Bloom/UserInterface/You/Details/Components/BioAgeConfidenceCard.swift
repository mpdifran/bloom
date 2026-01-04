//
//  BioAgeConfidenceCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-01-04.
//

import SwiftUI
import SFSafeSymbols

struct BioAgeConfidenceCard: View {
  let result: BiologicalAgeResult

  private var icon: SFSymbol {
    result.confidence == .low ? .questionmarkCircleFill : .checkmarkSealFill
  }

  var body: some View {
    HStack {
      Image(systemSymbol: icon)
        .font(.title2)

      VStack(alignment: .leading, spacing: 2) {
        Text(result.confidence.displayName)
          .font(.headline)

        let metricsCount = result.metricContributions?.count ?? 0
        Text("\(metricsCount) of 19 metrics considered")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .fontWeight(.bold)
      }

      Spacer(minLength: 0)

      Text("\(result.availableWeightPercentage.format(using: .noDecimalPlaces))%")
        .font(.title)
        .fontDesign(.rounded)
    }
    .fontWeight(.heavy)
    .fontDesign(.rounded)
    .foregroundStyle(result.confidence.color)
    .cardContainer(fill: result.confidence.color.tertiary)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      VStack(spacing: 16) {
        // High confidence (>80% weight)
        BioAgeConfidenceCard(
          result: BiologicalAgeResult(
            biologicalAge: 32,
            actualAge: 36,
            lastCalculated: .now,
            metricContributions: [
              MetricContribution(metric: .vo2Max, rawValue: 42, equivalentAge: 30, ageDelta: -6, weight: 0.18, weightedDelta: -1.08),
              MetricContribution(metric: .restingHeartRate, rawValue: 58, equivalentAge: 32, ageDelta: -4, weight: 0.06, weightedDelta: -0.24),
              MetricContribution(metric: .zoneMinutes, rawValue: 180, equivalentAge: 28, ageDelta: -8, weight: 0.08, weightedDelta: -0.64),
              MetricContribution(metric: .sleepScore, rawValue: 85, equivalentAge: 33, ageDelta: -3, weight: 0.08, weightedDelta: -0.24),
              MetricContribution(metric: .bloodPressure, rawValue: 118, equivalentAge: 34, ageDelta: -2, weight: 0.08, weightedDelta: -0.16),
              MetricContribution(metric: .bodyFatPercentage, rawValue: 18, equivalentAge: 31, ageDelta: -5, weight: 0.07, weightedDelta: -0.35),
              MetricContribution(metric: .activityLevel, rawValue: 1.8, equivalentAge: 32, ageDelta: -4, weight: 0.06, weightedDelta: -0.24),
              MetricContribution(metric: .heartRateRecovery, rawValue: 35, equivalentAge: 30, ageDelta: -6, weight: 0.06, weightedDelta: -0.36),
              MetricContribution(metric: .hrvTrend, rawValue: 15, equivalentAge: 33, ageDelta: -3, weight: 0.06, weightedDelta: -0.18),
              MetricContribution(metric: .sleepDurationVariability, rawValue: 0.5, equivalentAge: 34, ageDelta: -2, weight: 0.04, weightedDelta: -0.08),
              MetricContribution(metric: .heartRateReserve, rawValue: 110, equivalentAge: 33, ageDelta: -3, weight: 0.04, weightedDelta: -0.12),
            ]
          )
        )

        // Moderate confidence (50-80% weight)
        BioAgeConfidenceCard(
          result: BiologicalAgeResult(
            biologicalAge: 38,
            actualAge: 36,
            lastCalculated: .now,
            metricContributions: [
              MetricContribution(metric: .vo2Max, rawValue: 35, equivalentAge: 40, ageDelta: 4, weight: 0.18, weightedDelta: 0.72),
              MetricContribution(metric: .sleepScore, rawValue: 72, equivalentAge: 39, ageDelta: 3, weight: 0.08, weightedDelta: 0.24),
              MetricContribution(metric: .zoneMinutes, rawValue: 90, equivalentAge: 38, ageDelta: 2, weight: 0.08, weightedDelta: 0.16),
              MetricContribution(metric: .bloodPressure, rawValue: 125, equivalentAge: 38, ageDelta: 2, weight: 0.08, weightedDelta: 0.16),
              MetricContribution(metric: .restingHeartRate, rawValue: 72, equivalentAge: 40, ageDelta: 4, weight: 0.06, weightedDelta: 0.24),
              MetricContribution(metric: .activityLevel, rawValue: 1.2, equivalentAge: 38, ageDelta: 2, weight: 0.06, weightedDelta: 0.12),
              MetricContribution(metric: .sleepDurationVariability, rawValue: 1.2, equivalentAge: 40, ageDelta: 4, weight: 0.04, weightedDelta: 0.16),
            ]
          )
        )

        // Low confidence (<50% weight)
        BioAgeConfidenceCard(
          result: BiologicalAgeResult(
            biologicalAge: 34,
            actualAge: 36,
            lastCalculated: .now,
            metricContributions: [
              MetricContribution(metric: .vo2Max, rawValue: 38, equivalentAge: 35, ageDelta: -1, weight: 0.18, weightedDelta: -0.18),
              MetricContribution(metric: .sleepScore, rawValue: 80, equivalentAge: 34, ageDelta: -2, weight: 0.08, weightedDelta: -0.16),
              MetricContribution(metric: .restingHeartRate, rawValue: 65, equivalentAge: 35, ageDelta: -1, weight: 0.06, weightedDelta: -0.06),
            ]
          )
        )
      }
    }
  }
}
