//
//  TodaysAdviceTodayCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-08-28.
//

import SwiftUI

struct TodaysAdviceTodayCell: View {
  let advice: String

  var body: some View {
    TodayCardCell(
      symbol: .sunHorizonFill,
      title: "Today's Advice",
      content: advice,
      color: .mutedOrange
    )
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      TodaysAdviceTodayCell(
        advice: "Fit in at least 20 minutes of moderate cardio today—go for a brisk bike ride or jog—to boost your weekly cardio minutes and support your VO2 max goal."
      )
    }
  }
}
