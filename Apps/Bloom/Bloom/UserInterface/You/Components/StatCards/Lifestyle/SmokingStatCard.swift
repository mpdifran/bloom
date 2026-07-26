//
//  SmokingStatCard.swift
//  Bloom
//
//  Created by Claude on 2026-01-24.
//

import SwiftUI
import CoreHealth
import SFSafeSymbols

struct SmokingStatCard: View {
  let status: SmokingStatus
  let quitDate: Date?

  var body: some View {
    StatCard(
      symbol: smokingSymbol,
      title: "Smoking",
      value: status.shortDisplayName,
      valueStyle: .largeTinted(subtitle)
    )
    .tint(tintColor)
  }
}

private extension SmokingStatCard {

  var smokingSymbol: SFSymbol {
    switch status {
    case .unknown:
      .questionmarkCircleFill
    case .never:
      .checkmarkCircleFill
    case .former:
      .clockArrowCirclepath
    case .current:
      .exclamationmarkTriangleFill
    @unknown default:
      .questionmarkCircleFill
    }
  }

  var tintColor: Color {
    switch status {
    case .unknown:
      .secondary
    case .never:
      .vitalGreat
    case .former:
      .vitalGood
    case .current:
      .vitalSevere
    @unknown default:
      .secondary
    }
  }

  var subtitle: String? {
    switch status {
    case .unknown:
      "Tap to set"
    case .never:
      nil
    case .former:
      quitDateSubtitle
    case .current:
      nil
    @unknown default:
      "Tap to set"
    }
  }

  var quitDateSubtitle: String? {
    guard let quitDate else { return "Quit" }

    let now = Date()
    let components = Calendar.current.dateComponents([.year, .month, .day], from: quitDate, to: now)

    if let years = components.year, years >= 1 {
      if years == 1 {
        return "Quit 1 year ago"
      }
      return "Quit \(years) years ago"
    }

    if let months = components.month, months >= 1 {
      if months == 1 {
        return "Quit 1 month ago"
      }
      return "Quit \(months) months ago"
    }

    if let days = components.day, days >= 1 {
      if days == 1 {
        return "Quit 1 day ago"
      }
      return "Quit \(days) days ago"
    }

    return "Quit today"
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HStack {
        SmokingStatCard(status: .unknown, quitDate: nil)
        SmokingStatCard(status: .never, quitDate: nil)
      }
      HStack {
        SmokingStatCard(status: .former, quitDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()))
        SmokingStatCard(status: .current, quitDate: nil)
      }
      HStack {
        SmokingStatCard(status: .former, quitDate: Calendar.current.date(byAdding: .year, value: -2, to: Date()))
        SmokingStatCard(status: .former, quitDate: Calendar.current.date(byAdding: .day, value: -15, to: Date()))
      }
    }
  }
}
