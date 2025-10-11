//
//  PhaseTipTodayCell.swift
//  Bloom
//
//  Created by Assistant on 2025-10-10.
//

import SwiftUI

struct PhaseTipTodayCell: View {
  let phaseName: String?
  let tip: String

  var body: some View {
    TodayCardCell(
      symbol: .circleDottedAndCircle,
      title: title,
      content: tip,
      color: .mutedPink
    )
  }

  private var title: String {
    if let phaseName = phaseName, !phaseName.isEmpty {
      return "\(phaseName.capitalized) Phase Tip"
    }
    return "Cycle Phase Tip"
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      PhaseTipTodayCell(
        phaseName: "Follicular",
        tip: "You're in your follicular phase with higher energy levels. This is a great time for intense workouts and challenging yourself with new exercises."
      )
    }
  }
}
