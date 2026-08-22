//
//  WatchMetricCell.swift
//  BloomWatch Watch App
//
//  Created by Claude on 2026-02-01.
//

import SwiftUI
import SFSafeSymbols
import BloomFoundation
import CoreHealth

struct WatchMetricCell: View {
  let contribution: WatchMetricContribution

  private var icon: SFSymbol {
    if contribution.isPositive {
      return .arrowDownCircleFill
    } else if contribution.isNegative {
      return .arrowUpCircleFill
    } else {
      return .minusCircleFill
    }
  }

  private var tintColor: Color {
    if contribution.isPositive {
      return .mutedGreen
    } else if contribution.isNegative {
      return .mutedPink
    } else {
      return .mutedBlue
    }
  }

  private var contributionText: String {
    let delta = contribution.weightedDelta
    if abs(delta) <= 0.1 {
      return String(localized: "0 yrs", comment: "Bio age contribution of zero years")
    } else if delta >= 0 {
      return String(format: String(localized: "+%.1f yrs", comment: "Bio age contribution, adds years"), locale: .current, delta)
    } else {
      return String(format: String(localized: "%.1f yrs", comment: "Bio age contribution, removes years"), locale: .current, delta)
    }
  }

  /// The metric arrives from the phone as `BiologicalAgeMetric.rawValue` - a canonical English
  /// identifier, which is right for the wire but wrong to show. Resolve it here so the watch
  /// displays it in the user's language, falling back to the raw value if the phone ever sends a
  /// metric this build doesn't know.
  private var metricName: String {
    BiologicalAgeMetric(rawValue: contribution.metric)?.displayName ?? contribution.metric
  }

  var body: some View {
    HStack(spacing: 2) {
      // Impact indicator
      Image(systemSymbol: icon)
        .font(.title2)
        .foregroundStyle(tintColor, tintColor.tertiary)

      // Metric info
      VStack(alignment: .leading, spacing: 1) {
        Text(metricName)
          .font(.caption)
          .fontWeight(.medium)
          .lineLimit(3)

//        Text(contribution.category)
//          .font(.caption2)
//          .foregroundStyle(.secondary)
//          .lineLimit(1)
      }

      Spacer(minLength: 0)

      // Year contribution
      Text(contributionText)
        .font(.caption2)
        .fontWeight(.semibold)
        .foregroundStyle(tintColor)
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  PreviewEnvironment {
    List {
      Section {
        WatchMetricCell(
          contribution: WatchMetricContribution(
            metric: "VO₂ Max",
            category: "Cardiorespiratory",
            weightedDelta: -1.5
          )
        )
        WatchMetricCell(
          contribution: WatchMetricContribution(
            metric: "Sleep Score",
            category: "Sleep",
            weightedDelta: -0.8
          )
        )
      } header: {
        Text("Positive Factors")
      }

      Section {
        WatchMetricCell(
          contribution: WatchMetricContribution(
            metric: "Blood Pressure",
            category: "Body Composition",
            weightedDelta: 0.5
          )
        )
      } header: {
        Text("Areas for Improvement")
      }

      Section {
        WatchMetricCell(
          contribution: WatchMetricContribution(
            metric: "Walking Speed",
            category: "Activity",
            weightedDelta: 0.05
          )
        )
      } header: {
        Text("No Effect")
      }
    }
  }
}
