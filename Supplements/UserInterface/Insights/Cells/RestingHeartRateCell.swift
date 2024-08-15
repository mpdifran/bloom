//
//  RestingHeartRateCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-06.
//

import SwiftUI
import Charts

struct RestingHeartRateCell: View {
    let heartRateSamples: [DateQuantitySampleLegacy]

    var body: some View {
        Section {
            VStack {
                SleepProgramSectionHeader(
                    title: "Resting Heart Rate",
                    subtitle: "Last Two Weeks",
                    systemImage: "arrow.down.heart.fill",
                    isMulticolored: true
                )

                chart
                    .padding(.bottom)
            }

            HStack {
                LabelledMetricView(label: "Average", value: "\(overallAverage) bpm")
                    .tint(.secondary)
                Spacer()
                LabelledMetricView(label: "Goal", value: "\(goalAverage) bpm")
            }
        }
        .tint(.pink)
    }
}

private extension RestingHeartRateCell {

    var chart: some View {
        Chart {
            if let earliestDate, let latestDate {
                RuleMark(
                    xStart: .value("Start", earliestDate),
                    xEnd: .value("End", latestDate),
                    y: .value("Max", maxHeartRate)
                )
                .foregroundStyle(.pink.opacity(0.5))
//                RectangleMark(
//                    xStart: .value("Start", earliestDate),
//                    xEnd: .value("End", latestDate),
//                    yStart: .value("Start", minHeartRate),
//                    yEnd: .value("End", maxHeartRate)
//                )
            }

            ForEach(heartRateSamples) { dataPoint in
                LineMark(
                    x: .value("Date", dataPoint.date, unit: .day),
                    y: .value("BPM", dataPoint.quantity)
                )
                .foregroundStyle(.pink)

                PointMark(
                    x: .value("Date", dataPoint.date, unit: .day),
                    y: .value("BPM", dataPoint.quantity)
                )
                .foregroundStyle(.pink)
                .symbolSize(40)
            }
        }
        .frame(height: 140)
        .chartXAxis {
            AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartYScale(domain: (minY - 10)...(maxY + 10), range: .plotDimension)
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
    }

    var earliestDate: Date? {
        if let date = heartRateSamples.min(keyPath: \.date) {
            return Calendar.current.startOfDay(for: date)
        }
        return nil
    }

    var latestDate: Date? {
        if let date = heartRateSamples.max(keyPath: \.date) {
            return Calendar.current.endOfDay(for: date)
        }
        return nil
    }
}

private extension RestingHeartRateCell {

    var overallAverage: String {
        guard heartRateSamples.isNotEmpty else { return "0" }
        let average = heartRateSamples.average(keyPath: \.quantity)

        return String(format: "%.0f", average)
    }

    var goalAverage: String {
        let (_, max) = HealthManager.shared.goalRestingHeartRateForUser()

        return "<\(String(format: "%.0f", max))"
    }

    var minHeartRate: Double {
        HealthManager.shared.goalRestingHeartRateForUser().0
    }

    var maxHeartRate: Double {
        HealthManager.shared.goalRestingHeartRateForUser().1
    }

    var minY: Double {
        if let sample = heartRateSamples.min(keyPath: \.quantity) {
            return min(sample, minHeartRate)
        }
        return minHeartRate
    }

    var maxY: Double {
        if let sample = heartRateSamples.max(keyPath: \.quantity) {
            return max(sample, maxHeartRate)
        }
        return maxHeartRate
    }
}

#Preview {
    List {
        RestingHeartRateCell(
            heartRateSamples: [
                .init(date: .now, quantity: 66, unit: "bpm"),
                .init(date: .init(timeIntervalSinceNow: -86400), quantity: 66, unit: "bpm"),
                .init(date: .init(timeIntervalSinceNow: -86400 * 2), quantity: 64, unit: "bpm"),
                .init(date: .init(timeIntervalSinceNow: -86400 * 3), quantity: 72, unit: "bpm"),
                .init(date: .init(timeIntervalSinceNow: -86400 * 4), quantity: 67, unit: "bpm"),
                .init(date: .init(timeIntervalSinceNow: -86400 * 5), quantity: 66, unit: "bpm"),
                .init(date: .init(timeIntervalSinceNow: -86400 * 6), quantity: 66, unit: "bpm"),
                .init(date: .init(timeIntervalSinceNow: -86400 * 7), quantity: 72, unit: "bpm"),
                .init(date: .init(timeIntervalSinceNow: -86400 * 8), quantity: 69, unit: "bpm")
            ]
        )
    }
}
