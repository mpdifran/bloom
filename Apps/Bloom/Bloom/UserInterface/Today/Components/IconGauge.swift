//
//  IconGauge.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-30.
//

import SFSafeSymbols
import SwiftUI

struct IconGauge: View {
    let progress: CGFloat
    let dimension: CGFloat
    let lineThickness: CGFloat
    let symbol: SFSymbol
    let color: Color

    init(
        progress: CGFloat,
        dimension: CGFloat,
        lineThickness: CGFloat,
        symbol: SFSymbol,
        color: Color
    ) {
        self.progress = progress
        self.dimension = dimension
        self.lineThickness = lineThickness
        self.symbol = symbol
        self.color = color
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.tertiary, lineWidth: lineThickness)

            Circle()
                .trim(from: 0, to: clippedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [color, color.lighter()]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(
                        lineWidth: lineThickness,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))

            Circle()
                .frame(square: lineThickness - 1)
                .foregroundColor(clippedProgress > 0 ? color : color.opacity(0))
                .offset(y: -(dimension / 2 - lineThickness / 2))

            Circle()
                .frame(square: lineThickness)
                .foregroundColor(clippedProgress >= 0.95 ? color.lighter() : color.opacity(0))
                .offset(y: -(dimension / 2 - lineThickness / 2))
                .rotationEffect(Angle.degrees(360 * Double(clippedProgress)))
                .shadow(
                    color: clippedProgress >= 0.96 ? Color.black.opacity(0.1): Color.clear,
                    radius: 3,
                    x: 10,
                    y: 0
                )
                .transition(.opacity)

            Image(systemSymbol: symbol)
        }
        .padding(lineThickness / 2)
        .frame(width: dimension, height: dimension, alignment: .center)
        .animation(.bouncy(duration: 1.2), value: clippedProgress)
    }
}

private extension IconGauge {

    var clippedProgress: CGFloat {
        max(0, min(progress, 1))
    }
}

#Preview {
    VStack {
        IconGauge(
            progress: 0.2,
            dimension: 50,
            lineThickness: 10,
            symbol: .carrot,
            color: .mutedGreen
        )

        IconGauge(
            progress: 1,
            dimension: 70,
            lineThickness: 15,
            symbol: .forkKnife,
            color: .mutedOrange
        )
    }
}
