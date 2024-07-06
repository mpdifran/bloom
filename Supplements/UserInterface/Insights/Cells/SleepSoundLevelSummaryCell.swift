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
                SleepProgramSectionHeader(
                    title: "Sound Levels",
                    subtitle: "Last Night",
                    systemImage: "speaker.zzz.fill"
                )

                SleepSoundLevelChartView(soundLevels: soundLevels)
                    .frame(height: 120)
            }
            .padding(.bottom)
        }
        .tint(.yellow)
    }
}

#Preview {
    List {
        SleepSoundLevelSummaryCell(
            soundLevels: SleepAnalysis.SoundLevelDataPoint.previewData
        )
    }
}
