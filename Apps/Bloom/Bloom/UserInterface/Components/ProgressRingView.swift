//
//  ProgressRingView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-31.
//

import SwiftUI
import BloomFoundation

private extension CGFloat {
    static let lineWidth: CGFloat = 15
}

struct ProgressRingView: View {
    @Binding var progress: CGFloat

    let dimension: CGFloat
    let color: Color

    init(
        progress: Binding<CGFloat>,
        dimension: CGFloat,
        color: Color
    ) {
        self._progress = progress
        self.dimension = dimension
        self.color = color
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: .lineWidth)

            Circle()
                .trim(from: 0, to: clippedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [color.darker(by: 0.1), color.lighter()]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: .lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Circle()
                .frame(width: .lineWidth, height: .lineWidth)
                .foregroundColor(clippedProgress > 0 ? color.darker(by: 0.1) : color.opacity(0))
                .offset(y: -(dimension/2))

            Circle()
                .frame(width: .lineWidth, height: .lineWidth)
                .foregroundColor(clippedProgress >= 0.95 ? color.lighter() : color.opacity(0))
                .offset(y: -(dimension/2))
                .rotationEffect(Angle.degrees(360 * Double(clippedProgress)))
                .shadow(color: clippedProgress >= 0.96 ? Color.black.opacity(0.3): Color.clear, radius: 3, x: 5, y: 0)
                .transition(.opacity)

        }
        .frame(width: dimension, height: dimension, alignment: .center)
        .rotationEffect(Angle.degrees(360 * Double(remainderProgress)))
        .animation(.easeInOut(duration: 1.2), value: clippedProgress)
        .animation(.easeInOut(duration: 1.2), value: remainderProgress)
    }
}

private extension ProgressRingView {

    var clippedProgress: CGFloat {
        max(0, min(progress, 1))
    }

    var remainderProgress: CGFloat {
        max(0, progress - 1)
    }
}

#Preview {
    struct PreviewView: View {

        @State private var remSleepPercent: CGFloat = 0
        @State private var coreSleepPercent: CGFloat = 0
        @State private var deepSleepPercent: CGFloat = 0

        var body: some View {
            ZStack {
                ProgressRingView(
                    progress: $remSleepPercent,
                    dimension: 104,
                    color: .remSleep
                )

                ProgressRingView(
                    progress: $coreSleepPercent,
                    dimension: 72,
                    color: .coreSleep
                )

                ProgressRingView(
                    progress: $deepSleepPercent,
                    dimension: 40,
                    color: .deepSleep
                )
            }
            .task {
                await Delay(2000)
                await MainActor.run {
                    remSleepPercent = 0.96
                    coreSleepPercent = 1.2
                    deepSleepPercent = 0.23
                }
            }
        }
    }

    return PreviewView()
}
