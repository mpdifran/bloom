//
//  TonightsSleepTodayCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-08-28.
//

import SwiftUI

struct TonightsSleepTodayCell: View {
  let recommendations: String

  var body: some View {
    TodayCardCell(
      symbol: .moonZzzFill,
      title: "Tonight's Sleep",
      content: recommendations,
      color: .mutedIndigo
    )
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      TonightsSleepTodayCell(
        recommendations: "Wind down at least 60 minutes before bed: dim lights, put away screens, and skip the evening ice cream. Aim for a cooler room (around 18–19°C) and consider a short relaxation exercise to help you fall into deeper sleep."
      )
    }
  }
}
