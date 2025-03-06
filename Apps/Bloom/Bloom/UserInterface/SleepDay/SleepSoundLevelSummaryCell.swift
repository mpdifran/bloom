//
//  SleepSoundLevelSummaryCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-26.
//

import SFSafeSymbols
import SwiftUI

struct SleepSoundLevelSummaryCell: View {
    let soundLevels: [SleepAnalysis.SoundLevelDataPoint]

    var body: some View {
        Section {
            VStack {
                SleepSectionTitleView(
                    title: "Sound Levels",
                    symbol: .speakerZzzFill
                )

                SleepSoundLevelChartView(soundLevels: soundLevels)
                    .frame(height: 120)
            }
            .padding(.bottom)
        }
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
