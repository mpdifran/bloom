//
//  ProgressRingView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-31.
//

import SwiftUI

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
                        gradient: Gradient(colors: [color.darker(), color.lighter()]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: .lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Circle()
                .frame(width: .lineWidth, height: .lineWidth)
                .foregroundColor(color.darker())
                .offset(y: -(dimension/2))

            Circle()
                .frame(width: .lineWidth, height: .lineWidth)
                .foregroundColor(clippedProgress > 0.95 ? color.lighter() : color.opacity(0))
                .offset(y: -(dimension/2))
                .rotationEffect(Angle.degrees(360 * Double(clippedProgress)))
                .shadow(color: clippedProgress > 0.96 ? Color.black.opacity(0.1): Color.clear, radius: 3, x: 4, y: 0)

        }
        .frame(width: dimension, height: dimension, alignment: .center)
        .rotationEffect(Angle.degrees(360 * Double(remainderProgress)))
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
    ZStack {
        ProgressRingView(
            progress: .constant(1.23),
            dimension: 104,
            color: .remSleep
        )

        ProgressRingView(
            progress: .constant(0.82),
            dimension: 72,
            color: .coreSleep
        )

        ProgressRingView(
            progress: .constant(1.1),
            dimension: 40,
            color: .deepSleep
        )
    }
}
