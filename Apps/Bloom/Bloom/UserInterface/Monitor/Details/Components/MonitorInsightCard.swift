//
//  MonitorInsightCard.swift
//  Bloom
//
//  Created by Claude on 2026-01-19.
//

import SwiftUI
import SFSafeSymbols
import BloomModel
import BloomUI

/// A card displaying AI-generated insight for a monitor detail view.
struct MonitorInsightCard: View {
  let monitorType: MonitorType
  let currentResult: MonitorResult

  @State private var manager = MonitorInsightManager.shared
  @ObservedObject private var aiFeatureSettings = AIFeatureSettings.shared

  var body: some View {
    Group {
      if !aiFeatureSettings.monitorEnabled {
        // Don't show anything if monitor AI is disabled
        EmptyView()
      } else if manager.isLoading(for: monitorType) {
        loadingView
      } else if let insight = manager.insight(for: monitorType) {
        insightContent(insight)
      } else if manager.hasError(for: monitorType) {
        errorView
      } else {
        // No insight yet, will load in task
        loadingView
      }
    }
    .task {
      await manager.loadInsightIfNeeded(
        for: monitorType,
        currentResult: currentResult
      )
    }
    .onChange(of: currentResult.state) { _, _ in
      Task {
        await manager.refreshInsight(
          for: monitorType,
          currentResult: currentResult
        )
      }
    }
  }

  // MARK: - Content Views

  private func insightContent(_ insight: MonitorInsightResponse) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      // Header
      HStack(spacing: 8) {
        Image(systemSymbol: .sparkles)
          .foregroundStyle(.accent)
        Text("AI Insight")
          .font(.headline)
      }

      // Main insight text
      Text(insight.insight)
        .font(.body)
        .foregroundStyle(.primary)

      // Suggestion if present
      if let suggestion = insight.suggestion {
        HStack(alignment: .top, spacing: 8) {
          Image(systemSymbol: .lightbulbFill)
            .foregroundStyle(.yellow)
            .font(.subheadline)
          Text(suggestion)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
      }
    }
    .cardContainer()
  }

  private var loadingView: some View {
    HStack(spacing: 12) {
      ProgressView()
      Text("Generating insight...")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 20)
    .cardContainer()
  }

  private var errorView: some View {
    VStack(spacing: 8) {
      Text("Unable to load insight")
        .font(.subheadline)
        .foregroundStyle(.secondary)

      Button("Try Again") {
        Task {
          await manager.refreshInsight(
            for: monitorType,
            currentResult: currentResult
          )
        }
      }
      .font(.subheadline)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 16)
    .cardContainer()
  }
}
