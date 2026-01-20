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
import TelemetryDeck

struct MonitorInsightCardLoader: View {
  let monitorType: MonitorType
  let currentResult: MonitorResult

  @Environment(TabController.self) private var tabController
  @State private var manager = MonitorInsightManager.shared
  @State private var presentedSheet: AnyView?
  @ObservedObject private var aiFeatureSettings = AIFeatureSettings.shared

  var body: some View {
    Group {
      if !aiFeatureSettings.monitorEnabled {
        EmptyView()
      } else {
        MonitorInsightCard(
          insight: manager.insight(for: monitorType)?.insight,
          suggestion: manager.insight(for: monitorType)?.suggestion,
          isLoading: manager.isLoading(for: monitorType),
          reloadInsight: {
            await manager.refreshInsight(
              for: monitorType,
              currentResult: currentResult
            )
          },
          askBudAction: handleAskBudAction
        )
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
    .sheet($presentedSheet)
  }

  private func handleAskBudAction() {
    guard let insight = manager.insight(for: monitorType) else { return }

    TelemetryDeck.signal("Ask Bud Attempted", parameters: ["source": "Monitor Insight"])

    EntitledAction(presentedSheet: $presentedSheet, focus: .monitor) {
      let contextBody = buildContextBody(insight: insight)
      let context = ChatContext(
        title: "\(monitorType.displayName) Monitor Insight",
        context: contextBody,
        source: .monitorInsight
      )
      tabController.chatContexts = [context]
      tabController.isShowingChat = true

      TelemetryDeck.signal("Ask Bud", parameters: ["source": "Monitor Insight"])
    }
  }

  private func buildContextBody(insight: MonitorInsightResponse) -> String {
    var body = insight.insight
    if let suggestion = insight.suggestion {
      body += "\n\nSuggestion: \(suggestion)"
    }
    return body
  }
}
