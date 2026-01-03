//
//  NextPeriodStatCard.swift
//  Bloom
//
//  Created by Assistant on 2025-01-02.
//

import SwiftUI
import SFSafeSymbols
import CoreHealth

struct NextPeriodStatCard: View {
  let summary: MenstrualSummary?

  var body: some View {
    if let nextPeriod = summary?.nextPredictedPeriodDate {
      StatCard(
        symbol: .calendarBadgeClock,
        title: "Next Period",
        value: DateFormatter.justRelativeDateMedium.string(from: nextPeriod),
        valueStyle: .largeTinted("Predicted")
      )
      .tint(.pink)
    } else {
      StatCard(
        symbol: .calendarBadgeClock,
        title: "Next Period",
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
        NextPeriodStatCard(summary: previewMenstrualSummary)
        NextPeriodStatCard(summary: nil)
      }
    }
  }
}

private let previewMenstrualSummary: MenstrualSummary = {
  let calendar = Calendar.current
  let now = Date()

  // Create cycles 28 days apart, with most recent starting 10 days ago
  // Next period predicted in 18 days
  let cycles = [
    MenstrualCycle(startDate: calendar.date(byAdding: .day, value: -10, to: now)!, samples: []),
    MenstrualCycle(startDate: calendar.date(byAdding: .day, value: -38, to: now)!, samples: []),
    MenstrualCycle(startDate: calendar.date(byAdding: .day, value: -66, to: now)!, samples: [])
  ]

  return MenstrualSummary(menstrualCycles: cycles)
}()
