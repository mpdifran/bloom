//
//  MissingMetricCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-01-05.
//

import SwiftUI
import CoreHealth

struct MissingMetricCell: View {

  let metric: BiologicalAgeMetric

  var body: some View {
    HStack {
      Image(systemSymbol: .questionmarkCircleFill)
        .font(.title2)
        .foregroundStyle(.tint, .tint.tertiary)

      VStack(alignment: .leading, spacing: 2) {
        Text(metric.rawValue)
          .bold()
          .fontDesign(.rounded)

        Text(metric.category.rawValue)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer(minLength: 0)

      Text(verbatim: "--")
        .font(.headline)
        .fontWeight(.heavy)
        .fontDesign(.rounded)
        .foregroundStyle(.tint)
    }
    .fixedSize(horizontal: false, vertical: true)
    .cardContainer()
    .tint(.gray)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      MissingMetricCell(metric: .activityLevel)
    }
  }
}
