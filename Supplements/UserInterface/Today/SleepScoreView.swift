//
//  SleepScoreView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-10.
//

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
                            systemImage: "clock",
                            color: .green
                        )
                        ProgressArcView(
                            progress: CGFloat(sleepAnalysis.awakeSleepScore) / 10.0,
                            dimension: proxy.size.width - (2.0 * scaledLineWidth) - scaledRingSpacing,
                            thickness: .lineWidth / divisor,
                            systemImage: "bolt.horizontal",
                            color: .awakeSleep
                        )
                        ProgressArcView(
                            progress: CGFloat(sleepAnalysis.heartRateScore) / 10.0,
                            dimension: proxy.size.width - (4.0 * scaledLineWidth) - (2.0 * scaledRingSpacing),
                            thickness: .lineWidth / divisor,
                            systemImage: "heart",
                            color: .pink
                        )
                    }
                    ZStack(alignment: .top) {
                        ProgressArcView(
                            progress: CGFloat(sleepAnalysis.deepSleepScore) / 10.0,
                            dimension: proxy.size.width - (4.0 * scaledLineWidth) - (2.0 * scaledRingSpacing),
                            thickness: .lineWidth / divisor,
                            systemImage: "arrow.down.to.line",
                            isUpper: false,
                            color: .deepSleep
                        )
                        ProgressArcView(
                            progress: CGFloat(sleepAnalysis.coreSleepScore) / 10.0,
                            dimension: proxy.size.width - (2.0 * scaledLineWidth) - scaledRingSpacing,
                            thickness: .lineWidth / divisor,
                            systemImage: "circle.dotted.circle",
                            isUpper: false,
                            color: .coreSleep
                        )
                        ProgressArcView(
                            progress: CGFloat(sleepAnalysis.remSleepScore) / 10.0,
                            dimension: proxy.size.width,
                            thickness: .lineWidth / divisor,
                            systemImage: "eyes.inverse",
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
        SleepScoreView(sleepAnalysis: SleepAnalysis.previewData[0], isMini: true)
    }
    .listStyle(.plain)
}
