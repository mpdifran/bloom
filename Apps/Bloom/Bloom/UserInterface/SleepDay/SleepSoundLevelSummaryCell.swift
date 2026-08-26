//
//  SleepSoundLevelSummaryCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-26.
//

import SFSafeSymbols
import SwiftUI
import CoreHealth

struct SleepSoundLevelSummaryCell: View {
  let soundLevels: [SleepAnalysis.SoundLevelDataPoint]

  var body: some View {
    VStack {
      SleepSectionTitleView(
        title: String(localized: "Sound Levels", comment: "Sleep detail section heading"),
        symbol: .speakerZzzFill
      )
      .padding(.top)
      .padding(.horizontal)

      SleepSoundLevelChartView(soundLevels: soundLevels)
        .frame(height: 180)
        .padding(.trailing)
    }
    .cardContainer(includePadding: false)
    .tint(.mutedYellow)
  }
}

#Preview {
  List {
    SleepSoundLevelSummaryCell(
      soundLevels: SleepAnalysis.SoundLevelDataPoint.previewData
    )
  }
}
