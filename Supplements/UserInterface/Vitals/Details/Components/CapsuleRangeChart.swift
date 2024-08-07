//
//  CapsuleRangeChart.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-06.
//

import SwiftUI

private extension CGFloat {
    static let innerBarHeight: CGFloat = 8
    static let barBorderWidth: CGFloat = 2
}

struct CapsuleRangeChart: View {
    let title: String
    let unitString: String
    let value: Double
    let minValue: Double
    let maxValue: Double

    @State private var showMinMaxPopup = false

    var body: some View {
        VStack(spacing: 2) {
            HStack {
                Text(title)
                    .font(.subheadline)

                Spacer()

                Text("\(value.format())\(unitString)")
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
                        .stroke(.tint, lineWidth: .barBorderWidth)
                        .frame(
                            width: (proxy.size.width) * minMaxBarWidthPercent,
                            height: .innerBarHeight + .barBorderWidth + 2
                        )
                        .zStackAlignment(.leading)
                        .offset(x: (proxy.size.width) * minStartPercent)
                        .popover(isPresented: $showMinMaxPopup) {
                            MinMaxPopupView(min: minValue, max: maxValue, unitString: unitString)
                                .presentationCompactAdaptation(.popover)
                        }

                    Capsule()
                        .fill(.tint)
                        .frame(width: max((proxy.size.width - .barBorderWidth * 2) * barPercent, .innerBarHeight), height: .innerBarHeight)
                        .padding(.horizontal, .barBorderWidth)
                        .zStackAlignment(.leading)
                }
            }
            .frame(height: .innerBarHeight + .barBorderWidth * 2)
        }
        .onTapGesture {
            showMinMaxPopup.toggle()
        }
        .padding(.vertical, 6)
    }
}

private extension CapsuleRangeChart {

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

    var isWithinRange: Bool {
        value > minValue && value < maxValue
    }
}

private struct MinMaxPopupView: View {
    let min: Double
    let max: Double
    let unitString: String

    var body: some View {
        VStack(alignment: .leading) {
            Text("Goal")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Text("\(min.format())\(unitString)")
                Text("-")
                Text("\(max.format())\(unitString)")
            }
        }
        .font(.headline)
        .bold()
        .padding()
    }
}

#Preview {
    VStack {
        CapsuleRangeChart(
            title: "Protein",
            unitString: "g",
            value: 42,
            minValue: 81,
            maxValue: 96
        )
        CapsuleRangeChart(
            title: "Carbs",
            unitString: "g",
            value: 86,
            minValue: 51,
            maxValue: 112
        )
        CapsuleRangeChart(
            title: "Fat",
            unitString: "g",
            value: 182,
            minValue: 43,
            maxValue: 94
        )
        CapsuleRangeChart(
            title: "Vitamin A",
            unitString: "g",
            value: 0,
            minValue: 82,
            maxValue: 168
        )
    }
    .padding()
    .tint(.coreSleep)
}

#Preview("Min Max Popup") {
    MinMaxPopupView(min: 40, max: 120, unitString: "g")
}
