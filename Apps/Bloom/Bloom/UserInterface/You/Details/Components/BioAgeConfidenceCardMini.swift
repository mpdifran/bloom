//
//  BioAgeConfidenceCardMini.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-01-04.
//

import SwiftUI
import SFSafeSymbols
import CoreHealth

struct BioAgeConfidenceCardMini: View {
  let result: BiologicalAgeResult

  private var icon: SFSymbol {
    result.confidence == .low ? .questionmarkCircleFill : .checkmarkSealFill
  }

  var body: some View {
    HStack(spacing: 4) {
      Image(systemSymbol: icon)
      Text(result.confidence.displayName)
    }
    .font(.caption)
    .fontWeight(.heavy)
    .fontDesign(.rounded)
    .foregroundStyle(result.confidence.color)
    .padding(.trailing, 8)
    .padding(.leading, 4)
    .padding(.vertical, 4)
    .background {
      Capsule()
        .fill(result.confidence.color.tertiary)
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      VStack(spacing: 16) {
        // High confidence (>80% weight)
        BioAgeConfidenceCardMini(
          result: BiologicalAgeResult(
            biologicalAge: 32,
            actualAge: 36,
            lastCalculated: .now,
            metricContributions: [
              MetricContribution(metric: .vo2Max, rawValue: 42, equivalentAge: 30, ageDelta: -6, weight: 0.18, weightedDelta: -1.08),
              MetricContribution(metric: .restingHeartRate, rawValue: 58, equivalentAge: 32, ageDelta: -4, weight: 0.06, weightedDelta: -0.24),
              MetricContribution(metric: .zoneMinutes, rawValue: 180, equivalentAge: 28, ageDelta: -8, weight: 0.07, weightedDelta: -0.56),
              MetricContribution(metric: .sleepScore, rawValue: 85, equivalentAge: 33, ageDelta: -3, weight: 0.07, weightedDelta: -0.21),
              MetricContribution(metric: .bloodPressure, rawValue: 118, equivalentAge: 34, ageDelta: -2, weight: 0.08, weightedDelta: -0.16),
              MetricContribution(metric: .bodyFatPercentage, rawValue: 18, equivalentAge: 31, ageDelta: -5, weight: 0.06, weightedDelta: -0.30),
              MetricContribution(metric: .activityLevel, rawValue: 1.8, equivalentAge: 32, ageDelta: -4, weight: 0.06, weightedDelta: -0.24),
              MetricContribution(metric: .heartRateRecovery, rawValue: 35, equivalentAge: 30, ageDelta: -6, weight: 0.04, weightedDelta: -0.24),
              MetricContribution(metric: .hrvTrend, rawValue: 15, equivalentAge: 33, ageDelta: -3, weight: 0.06, weightedDelta: -0.18),
              MetricContribution(metric: .sleepDurationVariability, rawValue: 0.5, equivalentAge: 34, ageDelta: -2, weight: 0.04, weightedDelta: -0.08),
              MetricContribution(metric: .heartRateReserve, rawValue: 110, equivalentAge: 33, ageDelta: -3, weight: 0.04, weightedDelta: -0.12),
            ]
          )
        )

        // Moderate confidence (50-80% weight)
        BioAgeConfidenceCardMini(
          result: BiologicalAgeResult(
            biologicalAge: 38,
            actualAge: 36,
            lastCalculated: .now,
            metricContributions: [
              MetricContribution(metric: .vo2Max, rawValue: 35, equivalentAge: 40, ageDelta: 4, weight: 0.18, weightedDelta: 0.72),
              MetricContribution(metric: .sleepScore, rawValue: 72, equivalentAge: 39, ageDelta: 3, weight: 0.07, weightedDelta: 0.21),
              MetricContribution(metric: .zoneMinutes, rawValue: 90, equivalentAge: 38, ageDelta: 2, weight: 0.07, weightedDelta: 0.14),
              MetricContribution(metric: .bloodPressure, rawValue: 125, equivalentAge: 38, ageDelta: 2, weight: 0.08, weightedDelta: 0.16),
              MetricContribution(metric: .restingHeartRate, rawValue: 72, equivalentAge: 40, ageDelta: 4, weight: 0.06, weightedDelta: 0.24),
              MetricContribution(metric: .activityLevel, rawValue: 1.2, equivalentAge: 38, ageDelta: 2, weight: 0.06, weightedDelta: 0.12),
              MetricContribution(metric: .sleepDurationVariability, rawValue: 1.2, equivalentAge: 40, ageDelta: 4, weight: 0.04, weightedDelta: 0.16),
            ]
          )
        )

        // Low confidence (<50% weight)
        BioAgeConfidenceCardMini(
          result: BiologicalAgeResult(
            biologicalAge: 34,
            actualAge: 36,
            lastCalculated: .now,
            metricContributions: [
              MetricContribution(metric: .vo2Max, rawValue: 38, equivalentAge: 35, ageDelta: -1, weight: 0.18, weightedDelta: -0.18),
              MetricContribution(metric: .sleepScore, rawValue: 80, equivalentAge: 34, ageDelta: -2, weight: 0.07, weightedDelta: -0.14),
              MetricContribution(metric: .restingHeartRate, rawValue: 65, equivalentAge: 35, ageDelta: -1, weight: 0.06, weightedDelta: -0.06),
            ]
          )
        )
      }
    }
  }
}
