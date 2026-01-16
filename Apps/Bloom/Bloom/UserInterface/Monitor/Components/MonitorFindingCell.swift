//
//  MonitorFindingCell.swift
//  Bloom
//
//  Created by Claude on 2026-01-09.
//

import SwiftUI

/// A cell displaying a single finding within a monitor card.
struct MonitorFindingCell: View {

  let finding: Finding

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(finding.title)
        .font(.headline)
        .fontWeight(.medium)

      Text(finding.explanation)
        .font(.body)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    VStack(spacing: 16) {
      MonitorFindingCell(finding: Finding(
        title: "Your resting heart rate is higher than usual",
        explanation: "This has been the case for a couple of days. It could be normal variation, or a sign your body needs more rest.",
        confidence: .high,
        relatedMetrics: [.restingHeartRate]
      ))

      MonitorFindingCell(finding: Finding(
        title: "Training load trending high",
        explanation: "Your recent training load is 25% above your usual. Keep an eye on how you're feeling.",
        confidence: .medium,
        relatedMetrics: [.activeEnergy]
      ))

      MonitorFindingCell(finding: Finding(
        title: "HRV is trending downward",
        explanation: "Your HRV is trending 8% below your baseline.",
        confidence: .low,
        relatedMetrics: [.heartRateVariability]
      ))
    }
    .padding()
    .cardContainer()
  }
}
