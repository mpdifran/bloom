//
//  ProgressBar.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-19.
//

import SwiftUI

private extension Double {
    static let rangePercent: Double = 0.1
}
extension ProgressBar {
    enum MeasurementStyle {
        case minimum
        case range
    }
}

struct ProgressBar: View {
    let value: Double
    let target: Double
    let measurementStyle: MeasurementStyle

    init(
        value: Double,
        target: Double,
        measurementStyle: MeasurementStyle = .minimum
    ) {
        self.value = value
        self.target = target
        self.measurementStyle = measurementStyle
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                shape
                    .fill(.fill)

                shape
                    .fill(.tint)
                    .frame(width: progressBarWidth(proxy: proxy))
                    .zStackAlignment(.leading)

                if measurementStyle == .range {
                    targetRangeShape
                        .frame(width: targetRangeWidth(proxy: proxy))
                        .offset(x: targetRangeOffset(proxy: proxy))
                        .zStackAlignment(.leading)
                }
            }
        }
        .frame(height: 8)
        .animation(.bouncy, value: value)
    }
}

private extension ProgressBar {

    var shape: some Shape {
        Capsule()
    }

    var clampedProgress: Double {
        min(max(value / target, 0), 1)
    }

    var progress: Double {
        value / target
    }

    var targetRangeShape: some View {
        shape
            .fill(.tint.tertiary)
            .padding(.vertical, -2)
            .overlay {
                shape
                    .stroke(.tint)
                    .padding(-2)
            }
    }

    func progressBarWidth(proxy: GeometryProxy) -> CGFloat {
        switch measurementStyle {
        case .minimum:
            return proxy.size.width * clampedProgress
        case .range:
            if value > target * (1 + .rangePercent) {
                return proxy.size.width
            }
            let fullPercentage = 1 / (1 + .rangePercent)

            return proxy.size.width * fullPercentage * progress
        }
    }

    func targetRangeOffset(proxy: GeometryProxy) -> CGFloat {
        switch measurementStyle {
        case .minimum:
            return 0
        case .range:
            let upperTarget = target * (1 + .rangePercent)

            if value >= upperTarget {
                let centerPercentage = target / value
                return proxy.size.width * (centerPercentage * (1 - .rangePercent))
            }
            let width = targetRangeWidth(proxy: proxy)
            return proxy.size.width - width
        }
    }

    func targetRangeWidth(proxy: GeometryProxy) -> CGFloat {
        switch measurementStyle {
        case .minimum:
            return 0
        case .range:
            let upperTarget = target * (1 + .rangePercent)
            let percentage = (Double.rangePercent * 2) / (1 + .rangePercent)

            if value >= upperTarget {
                let scaledPercent = upperTarget / value
                return proxy.size.width * scaledPercent * percentage
            }
            return proxy.size.width * percentage
        }
    }
}

#Preview {
    VStack {
        ProgressBar(value: 0, target: 100)
        ProgressBar(value: 20, target: 100)
        ProgressBar(value: 60, target: 100)
        ProgressBar(value: 100, target: 100)
        ProgressBar(value: 150, target: 100)

        ProgressBar(value: 60, target: 100, measurementStyle: .range)
        ProgressBar(value: 89, target: 100, measurementStyle: .range)
        ProgressBar(value: 90, target: 100, measurementStyle: .range)
        ProgressBar(value: 110, target: 100, measurementStyle: .range)
        ProgressBar(value: 111, target: 100, measurementStyle: .range)
        ProgressBar(value: 120, target: 100, measurementStyle: .range)
        ProgressBar(value: 200, target: 100, measurementStyle: .range)
    }
    .padding()
    .tint(.mutedYellow)
}
