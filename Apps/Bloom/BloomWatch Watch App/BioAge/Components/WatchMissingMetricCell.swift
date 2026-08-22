//
//  WatchMissingMetricCell.swift
//  BloomWatch Watch App
//
//  Created by Claude on 2026-02-04.
//

import SwiftUI
import SFSafeSymbols
import CoreHealth

struct WatchMissingMetricCell: View {
  let metric: BiologicalAgeMetric

  var body: some View {
    HStack(spacing: 2) {
      // Question mark indicator
      Image(systemSymbol: .questionmarkCircleFill)
        .font(.title2)
        .foregroundStyle(.secondary, .secondary.tertiary)

      // Metric info
      VStack(alignment: .leading, spacing: 1) {
        Text(metric.displayName)
          .font(.caption)
          .fontWeight(.medium)
          .lineLimit(3)
      }

      Spacer(minLength: 0)

      // No data indicator
      Text(verbatim: "--")
        .font(.caption2)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  PreviewEnvironment {
    List {
      Section {
        WatchMissingMetricCell(metric: .activityLevel)
        WatchMissingMetricCell(metric: .bloodPressure)
        WatchMissingMetricCell(metric: .smoking)
      } header: {
        Text("No Data")
      }
    }
  }
}
