//
//  SleepSoundLevelSummaryCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-26.
//

import SwiftUI

struct SleepSoundLevelSummaryCell: View {
    let soundLevels: [SleepAnalysis.SoundLevelDataPoint]

    var body: some View {
        Section {
            VStack {
                SleepSectionTitleView(
                    title: "Sound Levels",
                    systemImage: "speaker.zzz.fill"
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
