//
//  MonitorInsightCardLoader.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-01-20.
//

import SwiftUI
import BloomModel
import BloomUI
import AppUI

struct MonitorInsightCardLoader: View {
  let monitorType: MonitorType
  let currentResult: MonitorResult

  @State private var manager = MonitorInsightManager.shared
  @ObservedObject private var aiFeatureSettings = AIFeatureSettings.shared

  var body: some View {
    Group {
      if !aiFeatureSettings.monitorEnabled {
        EmptyView()
      } else {
        MonitorInsightCard(
          insight: manager.insight(for: monitorType)?.insight,
          suggestion: manager.insight(for: monitorType)?.suggestion,
          isLoading: manager.isLoading(for: monitorType)) {
            await manager.refreshInsight(
              for: monitorType,
              currentResult: currentResult
            )
          }
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
    .animation(.default, value: manager.insight(for: monitorType))
  }
}
