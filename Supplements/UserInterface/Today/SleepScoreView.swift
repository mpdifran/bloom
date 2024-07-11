//
//  SleepScoreView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-10.
//

import SwiftUI

private extension CGFloat {
    static let lineWidth: CGFloat = 30
    static let ringSpacing: CGFloat = 8
}

struct SleepScoreView: View {
    let sleepAnalysis: SleepAnalysis

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                VStack(spacing: .lineWidth + .ringSpacing) {
                    ZStack(alignment: .bottom) {
                        ProgressArcView(
                            progress: CGFloat(sleepAnalysis.sleepLengthScore) / 10.0,
                            dimension: proxy.size.width,
                            thickness: .lineWidth,
                            systemImage: "clock",
                            color: .green
                        )
                        ProgressArcView(
                            progress: CGFloat(sleepAnalysis.soundLevelScore) / 10.0,
                            dimension: proxy.size.width - (2.0 * .lineWidth) - .ringSpacing,
                            thickness: .lineWidth,
                            systemImage: "speaker.zzz",
                            color: .yellow
                        )
                        ProgressArcView(
                            progress: CGFloat(sleepAnalysis.heartRateScore) / 10.0,
                            dimension: proxy.size.width - (4.0 * .lineWidth) - (2.0 * .ringSpacing),
                            thickness: .lineWidth,
                            systemImage: "heart",
                            color: .pink
                        )
                    }
                    ZStack(alignment: .top) {
                        ProgressArcView(
                            progress: CGFloat(sleepAnalysis.deepSleepScore) / 10.0,
                            dimension: proxy.size.width - (4.0 * .lineWidth) - (2.0 * .ringSpacing),
                            thickness: .lineWidth,
                            systemImage: "arrow.down.to.line",
                            isUpper: false,
                            color: .deepSleep
                        )
                        ProgressArcView(
                            progress: CGFloat(sleepAnalysis.coreSleepScore) / 10.0,
                            dimension: proxy.size.width - (2.0 * .lineWidth) - .ringSpacing,
                            thickness: .lineWidth,
                            systemImage: "circle.dotted.circle",
                            isUpper: false,
                            color: .coreSleep
                        )
                        ProgressArcView(
                            progress: CGFloat(sleepAnalysis.remSleepScore) / 10.0,
                            dimension: proxy.size.width,
                            thickness: .lineWidth,
                            systemImage: "eyes.inverse",
                            isUpper: false,
                            color: .remSleep
                        )
                    }
                }

                Text("\(sleepAnalysis.overallScore)")
                    .contentTransition(.numericText(value: Double(sleepAnalysis.overallScore)))
                    .font(.system(size: proxy.size.width / 3))
                    .bold()
                    .fontDesign(.rounded)
            }
        }
        .padding()
        .aspectRatio(0.9, contentMode: .fit)
        .animation(.default, value: sleepAnalysis)
    }
}

#Preview {
    List {
        SleepScoreView(sleepAnalysis: SleepAnalysis.previewData[0])
    }
    .listStyle(.plain)
}
