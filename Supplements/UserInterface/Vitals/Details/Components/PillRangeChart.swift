//
//  PillRangeChart.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-06.
//

import SwiftUI

private extension CGFloat {
    static let innerBarHeight: CGFloat = 8
    static let barBorderWidth: CGFloat = 4
    static let circleBorderWidth: CGFloat = 2
}

struct PillRangeChart: View {
    let title: String
    let valueLabel: String
    let value: Double
    let minValue: Double
    let maxValue: Double

    var body: some View {
        VStack(spacing: 2) {
            HStack {
                Text(title)

                Spacer()

                Text(valueLabel)
                    .font(.caption)
            }
            .bold()
            .fontDesign(.rounded)
            GeometryReader { proxy in
                ZStack {
                    Capsule()
                        .fill(.regularMaterial)
                        .frame(height: .innerBarHeight + .barBorderWidth * 2)

                    Capsule()
                        .fill(.green)
                        .frame(
                            width: (proxy.size.width) * minMaxBarWidthPercent,
                            height: .innerBarHeight + .barBorderWidth * 2
                        )
                        .zStackAlignment(.leading)
                        .offset(x: (proxy.size.width) * minStartPercent)

                    Capsule()
                        .fill(.tint)
                        .frame(width: max((proxy.size.width - .barBorderWidth * 2) * barPercent, .innerBarHeight), height: .innerBarHeight)
                        .padding(.horizontal, .barBorderWidth)
                        .zStackAlignment(.leading)

//                    Circle()
//                        .fill(.text)
//                        .frame(height: .innerBarHeight - .circleBorderWidth * 2)
//                        .zStackAlignment(.leading)
//                        .offset(x: .barBorderWidth + (proxy.size.width - .barBorderWidth * 2) * barPercent - (.innerBarHeight - .circleBorderWidth))
                }
            }
            .frame(height: .innerBarHeight + .barBorderWidth * 2)
        }
    }
}

private extension PillRangeChart {

    var scaledMax: Double {
        if value > maxValue {
            return value
        }
        return max(value, min(minValue * 1.5, maxValue))
    }

    var barPercent: Double {
        min(value / scaledMax, 1)
    }

    var minStartPercent: Double {
        min(minValue / scaledMax, 1)
    }

    var minMaxBarWidthPercent: Double {
        min((maxValue - minValue) / scaledMax, 1 - minStartPercent)
    }
}

#Preview {
    VStack {
        PillRangeChart(
            title: "Protein",
            valueLabel: "182 g",
            value: 42,
            minValue: 81,
            maxValue: 96
        )
        PillRangeChart(
            title: "Carbs",
            valueLabel: "182 g",
            value: 86,
            minValue: 51,
            maxValue: 112
        )
        PillRangeChart(
            title: "Fat",
            valueLabel: "182 g",
            value: 182,
            minValue: 43,
            maxValue: 94
        )
        PillRangeChart(
            title: "Vitamin A",
            valueLabel: "0 g",
            value: 0,
            minValue: 43,
            maxValue: 94
        )
    }
    .padding()
    .tint(.coreSleep)
}
