//
//  ProgressArcView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-10.
//

import SwiftUI

private extension CGFloat {
    static let lineWidth: CGFloat = 15
    static let arcPercentage: CGFloat = 0.5
}

struct ProgressArcView: View {
    let progress: CGFloat?
    let dimension: CGFloat
    let thickness: CGFloat
    let systemImage: String
    let isUpper: Bool
    let color: Color

    init(
        progress: CGFloat?,
        dimension: CGFloat,
        thickness: CGFloat? = nil,
        systemImage: String,
        isUpper: Bool = true,
        color: Color
    ) {
        self.progress = progress
        self.dimension = dimension
        self.thickness = thickness ?? CGFloat.lineWidth
        self.systemImage = systemImage
        self.isUpper = isUpper
        self.color = color
    }

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: .arcPercentage)
                .stroke(color.opacity(0.3), style: StrokeStyle(lineWidth: thickness, lineCap: .round))

            Circle()
                .trim(from: 0, to: clippedProgress * .arcPercentage)
                .stroke(
                    barFill,
                    style: StrokeStyle(lineWidth: thickness, lineCap: .round)
                )

            Image(systemName: systemImage)
                .foregroundStyle(.black)
                .font(.system(size: thickness * 0.6))
                .rotationEffect(
                    .degrees(
                        ((-360 * .arcPercentage) / 2.0 - 90.0) * -1
                    )
                )
                .offset(x: (dimension / 2) - (thickness / 2), y: 0)
                .scaleEffect(y: isUpper ? 1 : -1)
        }
        .padding(thickness / 2)
        .rotationEffect(.degrees((-360 * .arcPercentage) / 2.0 - 90.0))
        .frame(width: dimension, height: dimension, alignment: .center)
        .padding(.bottom, -dimension / 2)
        .animation(.easeInOut(duration: 1.2), value: clippedProgress)
        .scaleEffect(y: isUpper ? 1 : -1)
    }
}

private extension ProgressArcView {

    var clippedProgress: CGFloat {
        guard let progress else { return 0.001 }

        return max(0.001, min(progress, 1))
    }

    var barFill: AnyShapeStyle {
        if progress == nil {
            AnyShapeStyle(FillShapeStyle.fill)
        } else {
            AnyShapeStyle(
                AngularGradient(
                    gradient: Gradient(colors: [color, color.lighter()]),
                    center: .center,
                    startAngle: .degrees(0),
                    endAngle: .degrees(360.0 * .arcPercentage)
                )
            )
        }
    }
}

#Preview {
    struct PreviewView: View {

        @State private var remSleepPercent: CGFloat = 0
        @State private var coreSleepPercent: CGFloat = 0
        @State private var deepSleepPercent: CGFloat = 0

        var body: some View {
            ZStack(alignment: .bottom) {
                ProgressArcView(
                    progress: remSleepPercent,
                    dimension: 128,
                    systemImage: "heart",
                    color: .remSleep
                )

                ProgressArcView(
                    progress: nil,
                    dimension: 94,
                    systemImage: "heart",
                    color: .coreSleep
                )

                ProgressArcView(
                    progress: deepSleepPercent,
                    dimension: 60,
                    systemImage: "heart",
                    color: .deepSleep
                )
            }
            .onAppear {
                Task {
                    await Delay(2000)
                    await MainActor.run {
                        remSleepPercent = 0.7
                        coreSleepPercent = 0.3
                        deepSleepPercent = 0
                    }
                }
            }
        }
    }

    return PreviewView()
}
