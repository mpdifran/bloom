//
//  MetricContributionCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-01-05.
//

import SwiftUI
import SFSafeSymbols
import CoreHealth

struct MetricContributionCell: View {

  let contribution: MetricContribution
  let isPositive: Bool?

  private var symbol: SFSymbol {
    if let isPositive {
      return isPositive ? .arrowDownCircleFill : .arrowUpCircleFill
    }
    return .minusCircleFill
  }

  private var tintColor: Color {
    if let isPositive {
      return isPositive ? .mutedGreen : .mutedPink
    }
    return .mutedBlue
  }

  private var contributionText: String {
    let delta = contribution.weightedDelta
    if delta >= 0 {
      return "+\(delta.format(using: .oneDecimalPlace)) years"
    } else {
      return "\(delta.format(using: .oneDecimalPlace)) years"
    }
  }

  var body: some View {
    HStack {
      Image(systemSymbol: symbol)
        .font(.title2)
        .foregroundStyle(tintColor, tintColor.tertiary)

      VStack(alignment: .leading, spacing: 2) {
        Text(contribution.metric.rawValue)
          .bold()
          .fontDesign(.rounded)

        Text(contribution.metric.category.rawValue)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer(minLength: 0)

      Group {
        if isPositive != nil {
          Text(contributionText)
        } else {
          Text("0 years")
        }
      }
      .font(.headline)
      .fontWeight(.heavy)
      .fontDesign(.rounded)
      .foregroundStyle(tintColor)
    }
    .fixedSize(horizontal: false, vertical: true)
    .cardContainer()
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      MetricContributionCell(
        contribution: MetricContribution(
          metric: .bedtimeConsistency,
          rawValue: 10,
          equivalentAge: 35,
          ageDelta: -2,
          weight: 0.04,
          weightedDelta: -0.3
        ),
        isPositive: true
      )
      MetricContributionCell(
        contribution: MetricContribution(
          metric: .bedtimeConsistency,
          rawValue: 10,
          equivalentAge: 35,
          ageDelta: -2,
          weight: 0.04,
          weightedDelta: 0.3
        ),
        isPositive: false
      )
    }
  }
}
