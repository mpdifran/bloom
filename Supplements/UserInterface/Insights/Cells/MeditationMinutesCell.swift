//
//  MeditationMinutesCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-12.
//

import SwiftUI
import Charts

struct MeditationMinutesCell: View {
    let meditationMinutes: [DateQuantitySample]

    var body: some View {
        Section {
            VStack {
                SleepProgramSectionHeader(
                    title: "Meditation Minutes",
                    subtitle: "Last Two Weeks",
                    systemImage: "figure.mind.and.body"
                )

                chart
                    .padding(.bottom)
            }

            HStack {
                LabelledMetricView(label: "Average", value: "\(overallAverage) min / day")
                    .tint(.secondary)
                Spacer()
                LabelledMetricView(label: "Goal", value: "5 min / day")
            }
        }
        .tint(.teal)
    }
}

extension MeditationMinutesCell {

    var chart: some View {
        Chart {
            ForEach(meditationMinutes) { dataPoint in
                BarMark(
                    x: .value("Date", dataPoint.date, unit: .day),
                    y: .value("Meditation Minutes", dataPoint.quantity)
                )
                .foregroundStyle(.teal)
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
        guard meditationMinutes.isNotEmpty else { return "0" }
        let average = meditationMinutes.average(keyPath: \.quantity)

        return String(format: "%.0f", average)
    }
}

#Preview {
    List {
        MeditationMinutesCell(
            meditationMinutes: [
                .init(date: .now, quantity: 348, unit: "minute"),
                .init(date: .now.addingTimeInterval(-86400), quantity: 123, unit: "minute"),
                .init(date: .now.addingTimeInterval(-86400 * 2), quantity: 80, unit: "minute"),
                .init(date: .now.addingTimeInterval(-86400 * 3), quantity: 213, unit: "minute"),
            ]
        )
        MeditationMinutesCell(meditationMinutes: [])
    }
}
