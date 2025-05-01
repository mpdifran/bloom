//
//  SleepDurationSummaryCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-03.
//

import SFSafeSymbols
import SwiftUI
import Charts
import CoreHealth

struct SleepDurationSummaryCell: View {
    let sleepAnalyses: [SleepAnalysis]

    var body: some View {
        VStack {
            HStack {
                trendImage
                    .font(.title)

                Text("Sleep Duration")
                    .font(.title3)
                    .bold()

                Spacer()

                VStack(alignment: .trailing) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("AVG")
                            .font(.caption)
                            .bold()

                        Text("\(averageDuration, specifier: "%.0f")h")
                            .font(.largeTitle)
                            .foregroundStyle(averageColor)
                            .bold()
                    }

                    Text("Goal 7h - 9h")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.secondary)
                }
            }

            chart

//            if summary.percentNightsWithValues < 0.8 && summary.segment != .awake {
//                HStack(alignment: .top) {
//                    Image(systemSymbol: .exclamationmarkTriangleFill)
//                        .foregroundStyle(.orange)
//                    Text("Only \(summary.percentNightsWithValues, specifier: "%.0f")% of the last month of data contain values. Make sure to wear your watch every night!")
//                        .font(.caption)
//                        .foregroundStyle(.secondary)
//                }
//            }
        }
        .fontDesign(.rounded)
    }
}

private extension SleepDurationSummaryCell {

    var averageDuration: Double {
        sleepAnalyses.average(keyPath: \.overallHours)
    }
}

private extension SleepDurationSummaryCell {

    @ViewBuilder
    var trendImage: some View {
        if averageDuration < 7 {
          Image(systemSymbol: .chevronDownCircle)
                .foregroundStyle(.primary, .green)
        } else if averageDuration > 9 {
          Image(systemSymbol: .chevronUpCircle)
                .foregroundStyle(.primary, .green)
        } else {
          Image(systemSymbol: .checkmarkCircleFill)
                .foregroundStyle(.white, .green)
        }
    }

    var averageColor: Color {
        if
            averageDuration < 6.5 ||
                averageDuration > 9.5
        {
            .red
        } else if
            averageDuration < 7 ||
                averageDuration > 9
        {
            .orange
        } else {
            .primary
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [.green.lighter(by: 0.5), .green],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var chart: some View {
        Chart {
            ForEach(sleepAnalyses) { sleepAnalysis in
                BarMark(
                    x: .value("Date", sleepAnalysis.endDate, unit: .day),
                    y: .value("Hours", sleepAnalysis.overallHours)
                )
                .foregroundStyle(gradient)
                .cornerRadius(5)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.day())
            }
        }
        .chartYAxis {
            AxisMarks(values: .stride(by: 2)) { value in
                AxisGridLine()
                AxisTick()
                if let hours = value.as(Double.self) {
                    AxisValueLabel {
                        Text("\(hours, specifier: "%.0f")h")
                    }
                }
            }
        }
    }
}

#Preview {
    List {
        Section("Segments") {
            SleepDurationSummaryCell(
                sleepAnalyses: SleepAnalysis.previewData
            )
        }
    }
    .listStyle(.plain)
}
