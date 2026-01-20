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
import AppUI

/// A card displaying AI-generated insight for a monitor detail view.
struct MonitorInsightCard: View {
  let insight: String?
  let suggestion: String?
  let isLoading: Bool
  let reloadInsight: () async -> Void
  var askBudAction: (() -> Void)?

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        Text("Bud's Insight")
          .font(.title3)
          .bold()
          .fontDesign(.rounded)

        Spacer()

        Image(systemSymbol: .sparkles)
          .foregroundStyle(
            LinearGradient(
              colors: [.monitorLow, .monitorHigh],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .font(.title2)
      }

      if isLoading {
        CircularSpinnerView()
          .foregroundStyle(.tint)
          .horizontallyCentered()
          .padding(.top)
      }

      Text(mainText)
        .font(.body)
        .contentTransition(.numericText())
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .if(isLoading) {
          $0.padding(.bottom)
        }
        .if(hasError) {
          $0.padding(.vertical)
        }

      if let suggestion {
        Divider()

        Text(suggestion)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }

      if hasError {
        AsyncButton {
          await reloadInsight()
        } label: {
          Text("Try Again")
        }
        .buttonStyle(.secondary)
        .horizontallyCentered()
      }
    }
    .cardContainer(
      stroke: LinearGradient(
        colors: [.monitorLow, .monitorTypical, .monitorHigh],
        startPoint: .leading,
        endPoint: .trailing
      )
    )
    .contextMenu {
      if insight != nil, let askBudAction {
        Button("Chat with Bud", systemImage: "ellipsis.message") {
          askBudAction()
        }
      }
    }
    .shadow(color: .monitorLow.opacity(0.3), radius: 20)
    .animation(.default, value: insight)
    .animation(.default, value: suggestion)
    .animation(.default, value: isLoading)
  }
}

private extension MonitorInsightCard {

  var mainText: String {
    if let insight {
      return insight
    } else if isLoading {
      return  "Thinking..."
    } else {
      return "Oops, there was an error."
    }
  }

  var hasError: Bool {
    insight == nil && !isLoading
  }
}

// MARK: - Previews

#Preview("With Suggestion") {
  PreviewEnvironment {
    BloomScrollView {
      MonitorInsightCard(
        insight: "Your recovery metrics have been elevated for 2 days now. Your resting heart rate and HRV both suggest your body is working harder than usual to recover. This pattern often appears when fighting off an illness or after intense training.",
        suggestion: "Consider taking it easy today and prioritizing sleep tonight.",
        isLoading: false,
        reloadInsight: { }
      )
    }
  }
}

#Preview("Without Suggestion") {
  PreviewEnvironment {
    BloomScrollView {
      MonitorInsightCard(
        insight: "Your sleep rhythm has been consistent this week. Your bedtime and wake time variability are both within healthy ranges, which supports better sleep quality overall.",
        suggestion: nil,
        isLoading: false,
        reloadInsight: { }
      )
    }
  }
}

#Preview("Loading and Error") {
  PreviewEnvironment {
    BloomScrollView {
      MonitorInsightCard(
        insight: nil,
        suggestion: nil,
        isLoading: true,
        reloadInsight: { }
      )
      MonitorInsightCard(
        insight: nil,
        suggestion: nil,
        isLoading: false,
        reloadInsight: { }
      )
    }
  }
}
