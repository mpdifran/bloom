//
//  CycleDurationStatCard.swift
//  Bloom
//
//  Created by Assistant on 2025-01-02.
//

import SwiftUI
import SFSafeSymbols
import CoreHealth

struct CycleDurationStatCard: View {
  let summary: MenstrualSummary?

  var body: some View {
    if let duration = summary?.averageCycleDuration {
      StatCard(
        symbol: .circleGridCross,
        title: "Cycle Duration",
        value: String(localized: "\(duration) days", comment: "Cycle duration card value. The placeholder is a number of days."),
        valueStyle: .largeTinted(String(localized: "Average", comment: "Stat card subtitle: the value is an average"))
      )
      .tint(.pink)
    } else {
      StatCard(
        symbol: .circleGridCross,
        title: "Cycle Duration",
        value: String(localized: "No Data", comment: "Stat card value shown when there is no data"),
        valueStyle: .largeTinted(nil)
      )
      .tint(.gray)
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HStack {
        CycleDurationStatCard(summary: previewMenstrualSummary)
        CycleDurationStatCard(summary: nil)
      }
    }
  }
}

private let previewMenstrualSummary: MenstrualSummary = {
  let calendar = Calendar.current
  let now = Date()

  // Create cycles 28 days apart, with most recent starting 10 days ago (follicular phase)
  let cycles = [
    MenstrualCycle(startDate: calendar.date(byAdding: .day, value: -10, to: now)!, samples: []),
    MenstrualCycle(startDate: calendar.date(byAdding: .day, value: -38, to: now)!, samples: []),
    MenstrualCycle(startDate: calendar.date(byAdding: .day, value: -66, to: now)!, samples: [])
  ]

  return MenstrualSummary(menstrualCycles: cycles)
}()
