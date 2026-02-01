//
//  WatchConfidenceCell.swift
//  BloomWatch Watch App
//
//  Created by Claude on 2026-02-01.
//

import SwiftUI
import SFSafeSymbols
import BloomFoundation
import CoreHealth

struct WatchConfidenceCell: View {
  let confidence: WatchBioAgeConfidence?
  let metricsCount: Int

  private var icon: SFSymbol {
    guard let confidence else { return .questionmarkCircleFill }
    switch confidence {
    case .high, .moderate:
      return .checkmarkSealFill
    case .low:
      return .questionmarkCircleFill
    }
  }

  private var tintColor: Color {
    guard let confidence else { return .secondary }
    switch confidence {
    case .high:
      return .mutedGreen
    case .moderate:
      return .mutedYellow
    case .low:
      return .secondary
    }
  }

  var body: some View {
    HStack(spacing: 8) {
      Image(systemSymbol: icon)
        .font(.title3)
        .foregroundStyle(tintColor)

      VStack(alignment: .leading, spacing: 2) {
        Text(confidence?.displayName ?? "Unknown")
          .font(.footnote)
          .fontWeight(.semibold)
          .foregroundStyle(tintColor)

        Text("\(metricsCount) of \(BiologicalAgeMetric.allCases.count) metrics")
          .font(.caption2)
          .foregroundStyle(tintColor)
      }

      Spacer(minLength: 0)
    }
    .padding(.vertical, 8)
    .listRowBackground(
      RoundedRectangle(cornerRadius: 12)
        .fill(tintColor.tertiary)
    )
  }
}

#Preview {
  PreviewEnvironment {
    List {
      WatchConfidenceCell(confidence: .high, metricsCount: 17)
      WatchConfidenceCell(confidence: .moderate, metricsCount: 11)
      WatchConfidenceCell(confidence: .low, metricsCount: 4)
      WatchConfidenceCell(confidence: nil, metricsCount: 0)
    }
    .listStyle(.carousel)
  }
}
