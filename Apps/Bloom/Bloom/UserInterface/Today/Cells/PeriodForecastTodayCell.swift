//
//  PeriodForecastTodayCell.swift
//  Bloom
//
//  Created by Assistant on 2025-10-10.
//

import SwiftUI

struct PeriodForecastTodayCell: View {
  let forecast: String

  var body: some View {
    TodayCardCell(
      symbol: .calendarBadgeClock,
      title: "Period Forecast",
      content: forecast,
      color: .mutedPurple
    )
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      PeriodForecastTodayCell(
        forecast: "Your period is predicted to start in 3 days, around October 24th. Make sure you have supplies ready!"
      )
    }
  }
}
