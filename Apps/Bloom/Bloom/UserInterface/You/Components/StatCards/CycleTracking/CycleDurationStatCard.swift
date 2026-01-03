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
        value: "\(duration) days",
        valueStyle: .largeTinted("Average")
      )
      .tint(.pink)
    } else {
      StatCard(
        symbol: .circleGridCross,
        title: "Cycle Duration",
        value: "No Data",
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
