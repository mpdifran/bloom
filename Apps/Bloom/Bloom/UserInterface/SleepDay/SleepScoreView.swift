//
//  SleepScoreView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-10.
//

import SFSafeSymbols
import SwiftUI

private extension CGFloat {
  static let lineWidth: CGFloat = 20
  static let ringSpacing: CGFloat = 4
  static let maxWidth: CGFloat = 250
}

struct SleepScoreView: View {
  let sleepAnalysis: SleepAnalysis
  let isMini: Bool

  init(sleepAnalysis: SleepAnalysis, isMini: Bool = false) {
    self.sleepAnalysis = sleepAnalysis
    self.isMini = isMini
  }

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        VStack(spacing: spacing) {
          ZStack(alignment: .bottom) {
            ProgressArcView(
              progress: CGFloat(sleepAnalysis.sleepLengthScore) / 10.0,
              dimension: proxy.size.width,
              thickness: .lineWidth / divisor,
              symbol: .clock,
              color: .mutedGreen
            )
            ProgressArcView(
              progress: sleepAnalysis.awakeSleepScore.map { $0.asCGFloat / 10 },
              dimension: proxy.size.width - (2.0 * scaledLineWidth) - scaledRingSpacing,
              thickness: .lineWidth / divisor,
              symbol: .boltHorizontal,
              color: .awakeSleep
            )
            ProgressArcView(
              progress: sleepAnalysis.heartRateScore.map { $0.asCGFloat / 10 },
              dimension: proxy.size.width - (4.0 * scaledLineWidth) - (2.0 * scaledRingSpacing),
              thickness: .lineWidth / divisor,
              symbol: .heart,
              color: .mutedPink
            )
          }
          ZStack(alignment: .top) {
            ProgressArcView(
              progress: sleepAnalysis.deepSleepScore.map { $0.asCGFloat / 10 },
              dimension: proxy.size.width - (4.0 * scaledLineWidth) - (2.0 * scaledRingSpacing),
              thickness: .lineWidth / divisor,
              symbol: .arrowDownToLine,
              isUpper: false,
              color: .deepSleep
            )
            ProgressArcView(
              progress: sleepAnalysis.coreSleepScore.map { $0.asCGFloat / 10 },
              dimension: proxy.size.width - (2.0 * scaledLineWidth) - scaledRingSpacing,
              thickness: .lineWidth / divisor,
              symbol: .circleDottedCircle,
              isUpper: false,
              color: .coreSleep
            )
            ProgressArcView(
              progress: sleepAnalysis.remSleepScore.map { $0.asCGFloat / 10 },
              dimension: proxy.size.width,
              thickness: .lineWidth / divisor,
              symbol: .eyesInverse,
              isUpper: false,
              color: .remSleep
            )
          }
        }

        //                if !isMini {
        Text("\(sleepAnalysis.overallScore)")
          .contentTransition(.numericText(value: Double(sleepAnalysis.overallScore)))
          .font(.system(size: (proxy.size.width / 3)))
          .bold()
          .fontDesign(.rounded)
        //                }
      }
    }
    .padding(isMini ? 6 : 16)
    .aspectRatio(0.9, contentMode: .fit)
    .frame(width: .maxWidth / divisor)
    .animation(.default, value: sleepAnalysis)
  }

  var scaledLineWidth: CGFloat {
    .lineWidth / divisor
  }

  var scaledRingSpacing: CGFloat {
    .ringSpacing / divisor
  }

  var spacing: CGFloat {
    (.lineWidth + .ringSpacing) / divisor
  }

  var divisor: CGFloat {
    isMini ? 2 : 1
  }
}

#Preview {
  List {
    SleepScoreView(sleepAnalysis: SleepAnalysis.previewData[0])
    SleepScoreView(
      sleepAnalysis: SleepAnalysis(
        startDate: .now.addingTimeInterval(-20000),
        endDate: .now,
        hasDetailedSleepCategories: false,
        deepSleepMinutes: 0,
        coreSleepMinutes: 0,
        remSleepMinutes: 0,
        awakeSleepMinutes: 0,
        averageRestingHeartRate: nil,
        environmentalSoundLevels: [],
        heartRate: [],
        respiratoryRate: [],
        wristTemperature: nil
      )
    )
    SleepScoreView(sleepAnalysis: SleepAnalysis.previewData[0], isMini: true)
  }
  .listStyle(.plain)
}
