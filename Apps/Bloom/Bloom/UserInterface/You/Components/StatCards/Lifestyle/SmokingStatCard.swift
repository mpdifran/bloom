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
      String(localized: "Tap to set", comment: "Smoking card subtitle when no status has been recorded")
    case .never:
      nil
    case .former:
      quitDateSubtitle
    case .current:
      nil
    @unknown default:
      String(localized: "Tap to set", comment: "Smoking card subtitle when no status has been recorded")
    }
  }

  var quitDateSubtitle: String? {
    guard let quitDate else { return String(localized: "Quit", comment: "Smoking card subtitle for a former smoker with no quit date") }

    let now = Date()
    let components = Calendar.current.dateComponents([.year, .month, .day], from: quitDate, to: now)

    if let years = components.year, years >= 1 {
      return String(localized: "Quit \(years) years ago", comment: "Smoking card subtitle. The placeholder is a number of years since quitting.")
    }

    if let months = components.month, months >= 1 {
      return String(localized: "Quit \(months) months ago", comment: "Smoking card subtitle. The placeholder is a number of months since quitting.")
    }

    if let days = components.day, days >= 1 {
      return String(localized: "Quit \(days) days ago", comment: "Smoking card subtitle. The placeholder is a number of days since quitting.")
    }

    return String(localized: "Quit today", comment: "Smoking card subtitle when the quit date is today")
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
