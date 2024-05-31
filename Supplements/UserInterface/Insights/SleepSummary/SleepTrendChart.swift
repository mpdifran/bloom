//
//  SleepTrendChart.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-30.
//

import SwiftUI
import Charts
import Algorithms
import AppUI

extension SleepTrendChart {
    enum YAxisLabel {
        case nominal(String)
        case percent
    }
}

struct SleepTrendChart: View {
    let title: String
    let sleepAnalyses: [SleepAnalysis]
    let keyPath: KeyPath<SleepAnalysis, Double>
    let color: Color
    let yAxisLabel: YAxisLabel

    init(
        title: String,
        sleepAnalyses: [SleepAnalysis],
        keyPath: KeyPath<SleepAnalysis, Double>,
        color: Color,
        yAxisLabel: YAxisLabel = .percent
    ) {
        self.title = title
        self.sleepAnalyses = sleepAnalyses
        self.keyPath = keyPath
        self.color = color
        self.yAxisLabel = yAxisLabel
    }

    var body: some View {
        VStack(alignment: .leading) {
            Label(title, systemImage: "bed.double.fill")
                .font(.headline)
                .bold()
                .foregroundStyle(color)

            Chart {
                ForEach(sleepAnalyses) { sleepAnalysis in
                    BarMark(
                        x: .value("Date", sleepAnalysis.endDate, unit: .day),
                        y: .value("Value", sleepAnalysis[keyPath: keyPath])
                    )
                    .foregroundStyle(.fill)
                    .cornerRadius(5)
                }

                ForEach(trendLines) { trendLine in
                    RuleMark(
                        xStart: .value("Start Date", trendLine.startDate),
                        xEnd: .value("End Date", trendLine.endDate),
                        y: .value("Average", trendLine.average)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round))
                    .foregroundStyle(trendLine.isHighlighted ? AnyShapeStyle(color) : AnyShapeStyle(FillShapeStyle.fill.secondary))
                    .annotation(position: .top, alignment: .leading) {
                        Group {
                            switch yAxisLabel {
                            case .nominal(let unit):
                                Text("\(trendLine.average, specifier: "%.1f") \(unit)")
                            case .percent:
                                Text("\(trendLine.average * 100, specifier: "%.0f")%")
                            }
                        }
                        .font(.caption)
                        .fontDesign(.rounded)
                        .bold()
                        .foregroundStyle(trendLine.isHighlighted ? AnyShapeStyle(color) : AnyShapeStyle(FillShapeStyle.fill.secondary))
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { _ in }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic) { _ in }
        }
        }
    }
}

extension SleepTrendChart {

    var trendLines: [TrendLine] {
        if sleepAnalyses.count > 7 {
            let daysCount = 7
            let remainderCount = sleepAnalyses.count - daysCount
            let sevenDayAverage = sleepAnalyses.average(keyPath: keyPath, subsequence: .suffix(daysCount))
            let remainderAverage = sleepAnalyses.average(keyPath: keyPath, subsequence: .prefix(remainderCount))

            if abs((sevenDayAverage / remainderAverage) - 1) > 0.05 {
                let sevenDayStart = sleepAnalyses[sleepAnalyses.count - 7].endDate
                let sevenDayEnd = sleepAnalyses[sleepAnalyses.count - 1].endDate

                let remainderStart = sleepAnalyses[0].endDate
                let remainderEnd = sleepAnalyses[sleepAnalyses.count - 8].endDate

                return [
                    TrendLine(
                        startDate: remainderStart,
                        endDate: remainderEnd,
                        average: remainderAverage,
                        isHighlighted: false,
                        labelAlignment: .leading
                    ),
                    TrendLine(
                        startDate: sevenDayStart,
                        endDate: sevenDayEnd,
                        average: sevenDayAverage,
                        isHighlighted: true,
                        labelAlignment: .trailing
                    )
                ]
            }
        }

        if sleepAnalyses.count >= 2 {
            let average = sleepAnalyses.average(keyPath: keyPath)

            let startDate = sleepAnalyses.first!.endDate
            let endDate = sleepAnalyses.last!.endDate

            return [TrendLine(
                startDate: startDate,
                endDate: endDate,
                average: average,
                isHighlighted: true,
                labelAlignment: .leading
            )]
        }

        return []
    }

    var earliestDate: Date? {
        sleepAnalyses.min(by: { $0.endDate < $1.endDate })?.endDate
    }

    var latestDate: Date? {
        sleepAnalyses.max(by: { $0.endDate < $1.endDate })?.endDate
    }

    var sevenDaysStartDate: Date? {
        guard 
            let latestDate,
            let startDate = Calendar.current.date(byAdding: .day, value: -7, to: latestDate)
        else { return nil }

        return startDate
    }
}

struct TrendLine: Identifiable {
    var id: String { "\(startDate) - \(endDate) - \(average) - \(isHighlighted)" }

    let startDate: Date
    let endDate: Date
    let average: Double
    let isHighlighted: Bool
    let labelAlignment: HorizontalAlignment
}

#Preview {
    SleepTrendChart(
        title: "REM Sleep",
        sleepAnalyses: SleepAnalysis.previewData,
        keyPath: \.remSleepPercent,
        color: .remSleep,
        yAxisLabel: .percent
    )
}
