//
//  TimeInDaylightCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-05.
//

import SwiftUI
import Charts

struct TimeInDaylightCell: View {
    let timeInDaylight: [DateQuantitySample]

    var body: some View {
        Section {
            VStack {
                SleepProgramSectionHeader(
                    title: "Time in Daylight",
                    subtitle: "Last Two Weeks",
                    systemImage: "sun.max.fill"
                )


                chart
                    .padding(.bottom)
            }

            HStack {
                LabelledMetricView(label: "Average", value: "\(overallAverage) min / day")
                    .tint(.secondary)
                Spacer()
                LabelledMetricView(label: "Goal", value: "30 min / day")
            }
        }
        .tint(.yellow)
    }
}

private extension TimeInDaylightCell {

    var chart: some View {
        Chart {
            ForEach(timeInDaylight) { dataPoint in
                BarMark(
                    x: .value("Date", dataPoint.date, unit: .day),
                    y: .value("Time In Daylight", dataPoint.quantity)
                )
                .foregroundStyle(.yellow)
                .cornerRadius(5)
            }
        }
        .frame(height: 120)
        .chartXAxis {
            AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
    }

    var overallAverage: String {
        guard timeInDaylight.isNotEmpty else { return "0" }
        let average = timeInDaylight.average(keyPath: \.quantity)

        return String(format: "%.0f", average)
    }
}

#Preview {
    List {
        TimeInDaylightCell(
            timeInDaylight: [
                .init(date: .now, quantity: 348, unit: "minute"),
                .init(date: .now.addingTimeInterval(-86400), quantity: 123, unit: "minute"),
                .init(date: .now.addingTimeInterval(-86400 * 2), quantity: 80, unit: "minute"),
                .init(date: .now.addingTimeInterval(-86400 * 3), quantity: 213, unit: "minute"),
            ]
        )
        TimeInDaylightCell(
            timeInDaylight: []
        )
    }
}
