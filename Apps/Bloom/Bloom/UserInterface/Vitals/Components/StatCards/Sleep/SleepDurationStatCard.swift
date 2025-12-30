//
//  SleepDurationStatCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-29.
//

import SwiftUI

struct SleepDurationStatCard: View {
  let duration: TimeInterval?

  private var formattedDuration: String? {
    guard let duration else { return nil }
    let totalMinutes = Int(duration / 60)
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    return "\(hours)h \(minutes)m"
  }

  var body: some View {
    StatCard(
      symbol: .clockFill,
      title: "Duration",
      value: formattedDuration ?? "No Data",
      valueStyle: .largeTinted("7 day avg")
    )
    .tint(formattedDuration == nil ? AnyShapeStyle(.gray) : AnyShapeStyle(.coreSleep))
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HStack {
        SleepDurationStatCard(duration: 25_380)
        SleepDurationStatCard(duration: nil)
      }
    }
  }
}
