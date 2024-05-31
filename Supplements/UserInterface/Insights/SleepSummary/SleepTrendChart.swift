//
//  SleepTrendChart.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-30.
//

import SwiftUI
import Charts

extension SleepTrendChart {
    enum Trend {
        case totalAverage
        case last7DayAverage
    }

    enum YAxisLabel {
        case nominal
        case percent
    }
}

struct SleepTrendChart: View {
    let sleepAnalyses: [SleepAnalysis]
    let keyPath: KeyPath<SleepAnalysis, Double>
    let color: Color
    let trends: [Trend]
    let yAxisLabel: YAxisLabel

    init(
        sleepAnalyses: [SleepAnalysis],
        keyPath: KeyPath<SleepAnalysis, Double>,
        color: Color,
        trends: [Trend] = [.totalAverage, .last7DayAverage],
        yAxisLabel: YAxisLabel = .nominal
    ) {
        self.sleepAnalyses = sleepAnalyses
        self.keyPath = keyPath
        self.color = color
        self.trends = trends
        self.yAxisLabel = yAxisLabel
    }

    var body: some View {
        Chart {
            ForEach(sleepAnalyses) { sleepAnalysis in
                BarMark(
                    x: .value("Date", sleepAnalysis.endDate, unit: .day),
                    y: .value("Value", sleepAnalysis[keyPath: keyPath])
                )
                .foregroundStyle(.fill)
                .cornerRadius(5)
            }

            if let totalAverageData {
                RuleMark(
                    xStart: .value("Start Date", totalAverageData.0),
                    xEnd: .value("End Date", totalAverageData.1),
                    y: .value("Average", totalAverageData.2)
                )
                .lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round))
                .foregroundStyle(Color(uiColor: .label))
                .annotation(position: .top, alignment: .leading) {
                    Text("Average")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(Color(uiColor: .label))
                }
            }

            if let sevenDayAverageData {
                RuleMark(
                    xStart: .value("Start Date", sevenDayAverageData.0),
                    xEnd: .value("End Date", sevenDayAverageData.1),
                    y: .value("Average", sevenDayAverageData.2)
                )
                .lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round))
                .foregroundStyle(color)
                .annotation(position: .top, alignment: .leading) {
                    Text("7 Day Average")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(color)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .weekOfYear)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic) { value in
                AxisGridLine()
                AxisTick()
                switch yAxisLabel {
                case .nominal:
                    AxisValueLabel()
                case .percent:
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text("\(Int(doubleValue * 100))%")
                        }
                    }
                }
            }
        }
    }
}

extension SleepTrendChart {

    var sevenDayAverageData: (Date, Date, Double)? {
        guard 
            trends.contains(.last7DayAverage),
            let latestDate,
            let sevenDaysStartDate
        else { return nil }

        let days = 7

        let sum = sleepAnalyses
            .sorted(by: { $0.endDate < $1.endDate })
            .suffix(days)
            .reduce(0) { sum, sleepAnalysis in
                sum + sleepAnalysis[keyPath: keyPath]
            }

        let average = sum / Double(days)

        return (sevenDaysStartDate, latestDate, average)
    }

    var totalAverageData: (Date, Date, Double)? {
        guard
            trends.contains(.totalAverage),
            let latestDate,
            let earliestDate
        else { return nil }

        let sum = sleepAnalyses
            .reduce(0) { sum, sleepAnalysis in
                sum + sleepAnalysis[keyPath: keyPath]
            }

        let average = sum / Double(sleepAnalyses.count)

        return (earliestDate, latestDate, average)
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

#Preview {
    SleepTrendChart(
        sleepAnalyses: SleepAnalysis.previewData,
        keyPath: \.deepSleepPercent,
        color: .deepSleep,
        trends: [.last7DayAverage]
    )
}
