//
//  MonitorSummaryView.swift
//  Bloom
//
//  Created by Claude on 2026-01-10.
//

import SwiftUI
import SFSafeSymbols
import BloomModel

/// A card displaying the AI-generated summary for monitor alerts.
/// Shown at the top of the Monitor tab when monitors need attention.
struct MonitorSummaryView: View {

  let summary: MonitorSummaryResponse

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      headerView

      Text(summary.summary)
        .font(.subheadline)
        .foregroundStyle(.primary)

      if !summary.recommendations.isEmpty {
        recommendationsView
      }

      if let contextNote = summary.contextNote, !contextNote.isEmpty {
        Text(contextNote)
          .font(.caption)
          .foregroundStyle(.secondary)
          .italic()
      }
    }
    .cardContainer(fill: Color.orange.opacity(0.1))
  }

  // MARK: - Header

  private var headerView: some View {
    HStack(spacing: 10) {
      Image(systemSymbol: .lightbulbFill)
        .font(.title3)
        .foregroundStyle(.orange)

      Text("AI Insights")
        .font(.headline)
        .fontWeight(.semibold)

      Spacer()
    }
  }

  // MARK: - Recommendations

  private var recommendationsView: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("What You Can Do")
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundStyle(.secondary)

      ForEach(Array(summary.recommendations.enumerated()), id: \.offset) { index, recommendation in
        HStack(alignment: .top, spacing: 10) {
          Image(systemSymbol: .checkmarkCircleFill)
            .font(.caption)
            .foregroundStyle(.green)
            .padding(.top, 2)

          Text(recommendation)
            .font(.subheadline)
            .foregroundStyle(.primary)
        }
      }
    }
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      MonitorSummaryView(
        summary: MonitorSummaryResponse(
          summary: "Your recovery metrics have been elevated for a couple days. Your resting heart rate is higher than usual and your HRV is lower than your typical range.",
          notificationBody: "Your recovery metrics suggest taking it easy today.",
          recommendations: [
            "Consider taking it easy with workouts today",
            "Prioritize getting to bed on time tonight",
            "Stay hydrated throughout the day",
            "If you're not feeling well, it's okay to rest"
          ],
          contextNote: "These patterns often appear when your body is working harder than usual."
        )
      )
    }
  }
}
