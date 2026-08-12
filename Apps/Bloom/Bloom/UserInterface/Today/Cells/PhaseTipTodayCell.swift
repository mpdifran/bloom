//
//  PhaseTipTodayCell.swift
//  Bloom
//
//  Created by Assistant on 2025-10-10.
//

import SwiftUI
import CoreHealth

struct PhaseTipTodayCell: View {
  let phase: MenstrualCyclePhase?
  let tip: String

  var body: some View {
    TodayCardCell(
      symbol: .circleDottedAndCircle,
      title: title,
      content: tip,
      color: phase?.color ?? .mutedPink
    )
  }

  private var title: String {
    if let phaseName = phase?.name {
      return "\(phaseName) Tip"
    }
    return String(localized: "Cycle Phase Tip")
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      PhaseTipTodayCell(
        phase: .menstrual,
        tip: "You menstruating."
      )
      PhaseTipTodayCell(
        phase: .follicular,
        tip: "You're in your follicular phase with higher energy levels. This is a great time for intense workouts and challenging yourself with new exercises."
      )
      PhaseTipTodayCell(
        phase: .ovulation,
        tip: "You ovulating."
      )
      PhaseTipTodayCell(
        phase: .luteal,
        tip: "You're in your luteal phase with lower energy levels."
      )
    }
  }
}
