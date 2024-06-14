//
//  RestingHeartRateCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-06.
//

import SwiftUI
import Charts

struct RestingHeartRateCell: View {
    let heartRateSamples: [HeartRateSample]

    var body: some View {
        Section {
            VStack {
                SleepProgramSectionHeader(
                    title: "Resting Heart Rate",
                    subtitle: "Last Two Weeks",
                    systemImage: "arrow.down.heart.fill",
                    isMulticolored: true
                )

                if heartRateSamples.isEmpty {
                    Text("No Data Available")
                        .foregroundStyle(.secondary)
                        .frame(minHeight: 80)
                } else {
                    chart
                        .padding(.bottom)
                }
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
                    y: .value("BPM", dataPoint.value)
                )
                .foregroundStyle(.pink)

                PointMark(
                    x: .value("Date", dataPoint.date, unit: .day),
                    y: .value("BPM", dataPoint.value)
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
        if let date = heartRateSamples.min(by: { $0.date < $1.date })?.date {
            return Calendar.current.startOfDay(for: date)
        }
        return nil
    }

    var latestDate: Date? {
        if let date = heartRateSamples.max(by: { $0.date < $1.date })?.date {
            return Calendar.current.endOfDay(for: date)
        }
        return nil
    }
}

private extension RestingHeartRateCell {

    var overallAverage: String {
        guard heartRateSamples.isNotEmpty else { return "0" }
        let average = heartRateSamples.average(keyPath: \.value)

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
        if let sample = heartRateSamples.min(by: { $0.value < $1.value })?.value {
            return min(sample, minHeartRate)
        }
        return minHeartRate
    }

    var maxY: Double {
        if let sample = heartRateSamples.max(by: { $0.value < $1.value })?.value {
            return max(sample, maxHeartRate)
        }
        return maxHeartRate
    }
}

#Preview {
    List {
        RestingHeartRateCell(
            heartRateSamples: [
                .init(date: .now, value: 66, unit: "bpm"),
                .init(date: .init(timeIntervalSinceNow: -86400), value: 66, unit: "bpm"),
                .init(date: .init(timeIntervalSinceNow: -86400 * 2), value: 64, unit: "bpm"),
                .init(date: .init(timeIntervalSinceNow: -86400 * 3), value: 72, unit: "bpm"),
                .init(date: .init(timeIntervalSinceNow: -86400 * 4), value: 67, unit: "bpm"),
                .init(date: .init(timeIntervalSinceNow: -86400 * 5), value: 66, unit: "bpm"),
                .init(date: .init(timeIntervalSinceNow: -86400 * 6), value: 66, unit: "bpm"),
                .init(date: .init(timeIntervalSinceNow: -86400 * 7), value: 72, unit: "bpm"),
                .init(date: .init(timeIntervalSinceNow: -86400 * 8), value: 69, unit: "bpm")
            ]
        )
    }
}
