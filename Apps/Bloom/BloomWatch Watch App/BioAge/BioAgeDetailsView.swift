//
//  BioAgeDetailsView.swift
//  BloomWatch Watch App
//
//  Created by Claude on 2026-02-01.
//

import SwiftUI
import CoreHealth
import BloomFoundation

struct BioAgeDetailsView: View {
  @State private var provider = BiologicalAgeProvider.shared

  var body: some View {
    List {
      // Chart section
      BioAgeHistoryChartCell(
        chartData: provider.chartData,
        actualAge: provider.chronologicalAge
      )

      // Confidence section
      WatchConfidenceCell(
        confidence: provider.confidence,
        metricsCount: provider.metricsCount
      )

      // Positive factors
      if provider.positiveFactors.isNotEmpty {
        Section {
          ForEach(provider.positiveFactors) { contribution in
            WatchMetricCell(contribution: contribution)
          }
        } header: {
          Text("Positive Factors")
        }
      }

      // Negative factors
      if provider.negativeFactors.isNotEmpty {
        Section {
          ForEach(provider.negativeFactors) { contribution in
            WatchMetricCell(contribution: contribution)
          }
        } header: {
          Text("Areas for Improvement")
        }
      }

      // Neutral factors
      if provider.neutralFactors.isNotEmpty {
        Section {
          ForEach(provider.neutralFactors) { contribution in
            WatchMetricCell(contribution: contribution)
          }
        } header: {
          Text("No Effect")
        }
      }
    }
    .navigationTitle("Bio Age")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      BioAgeDetailsView()
    }
  }
}
