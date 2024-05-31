//
//  SleepSummaryView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-25.
//

import SwiftUI
import AppFoundations
import Charts

struct SleepSummaryView: View {
    let sleepAnalysises: [SleepAnalysis]

    @State private var expandedSections = Set<String>()

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading) {
                    ChartTitleView("Sleep History")
                    chartView
                }
            }

            Section {
                NavigationLink {
                    SleepTrendsView()
                } label: {
                    Label("Trends", systemImage: "arrow.down.left.arrow.up.right")
                }
            }

            ForEach(sleepAnalysises.reversed()) { sleepAnalysis in
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(sleepAnalysis.name)
                                .font(.title3)
                                .bold()
                                .fontDesign(.rounded)

                            Text(sleepAnalysis.timeSpanDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                        
                        Text("\(sleepAnalysis.overallScore)")
                            .font(.largeTitle)
                            .bold()
                            .fontDesign(.rounded)
                            .foregroundStyle(sleepAnalysis.overallScore.scoreColor)
                        
                        Image(systemName: expandedSections.contains(sleepAnalysis.id) ? "chevron.up" : "chevron.down")
                            .font(.title3)
                            .bold()
                            .fontDesign(.rounded)
                            .foregroundStyle(.secondary)
                            .contentTransition(.symbolEffect)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        expandedSections.toggleMembership(sleepAnalysis.id)
                    }
                    
                    if expandedSections.contains(sleepAnalysis.id) {
                        chart(for: sleepAnalysis)

                        SleepSegmentScoreView(
                            title: "Sleep Length Score",
                            color: .green,
                            minutes: sleepAnalysis.overallMinutes,
                            score: sleepAnalysis.sleepLengthScore
                        )

                        SleepSegmentScoreView(
                            title: "REM Sleep Score",
                            color: .remSleep,
                            minutes: sleepAnalysis.remSleepMinutes,
                            overallMinutes: sleepAnalysis.overallHours * 60,
                            score: sleepAnalysis.remSleepScore
                        )

                        SleepSegmentScoreView(
                            title: "Core Sleep Score",
                            color: .coreSleep,
                            minutes: sleepAnalysis.coreSleepMinutes,
                            overallMinutes: sleepAnalysis.overallHours * 60,
                            score: sleepAnalysis.coreSleepScore
                        )

                        SleepSegmentScoreView(
                            title: "Deep Sleep Score",
                            color: .deepSleep,
                            minutes: sleepAnalysis.deepSleepMinutes,
                            overallMinutes: sleepAnalysis.overallHours * 60,
                            score: sleepAnalysis.deepSleepScore
                        )
                    }
                }
            }
        }
        .navigationTitle("Sleep Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.default, value: expandedSections)
    }
}

private extension SleepSummaryView {

    var earliestStartDate: Date? {
        sleepAnalysises.min(by: { $0.startDate < $1.startDate })?.beginningOfStartDate
    }

    var latestEndDate: Date? {
        sleepAnalysises.min(by: { $0.endDate > $1.endDate })?.endOfEndDate
    }

    var chartView: some View {
        Chart {
            if let earliestStartDate, let latestEndDate {
                RectangleMark(
                    xStart: .value("Start", earliestStartDate),
                    xEnd: .value("End", latestEndDate),
                    yStart: .value("Start", 7),
                    yEnd: .value("End", 9)
                )
                .foregroundStyle(.green.opacity(0.3))
            }

            ForEach(sleepAnalysises) { sleepAnalysis in
                BarMark(
                    x: .value("Date", sleepAnalysis.endDate, unit: .day),
                    y: .value("Value", sleepAnalysis.deepSleepHours)
                )
                .foregroundStyle(by: .value("Category", "Deep Sleep"))
                .cornerRadius(5)
                BarMark(
                    x: .value("Date", sleepAnalysis.endDate, unit: .day),
                    y: .value("Value", sleepAnalysis.coreSleepHours)
                )
                .foregroundStyle(by: .value("Category", "Core Sleep"))
                .cornerRadius(5)
                BarMark(
                    x: .value("Date", sleepAnalysis.endDate, unit: .day),
                    y: .value("Value", sleepAnalysis.remSleepHours)
                )
                .foregroundStyle(by: .value("Category", "REM Sleep"))
                .cornerRadius(5)
                BarMark(
                    x: .value("Date", sleepAnalysis.endDate, unit: .day),
                    y: .value("Value", sleepAnalysis.awakeSleepHours)
                )
                .foregroundStyle(by: .value("Category", "Awake"))
                .cornerRadius(5)
            }

            ForEach(sleepAnalysises) { sleepAnalysis in
                LineMark(
                    x: .value("Date", sleepAnalysis.endDate, unit: .day),
                    y: .value("Score", sleepAnalysis.overallScore)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(.green)
                PointMark(
                    x: .value("Date", sleepAnalysis.endDate, unit: .day),
                    y: .value("Score", sleepAnalysis.overallScore)
                )
                .foregroundStyle(.green)
                .symbolSize(50)
            }
        }
        .chartForegroundStyleScale([
            "Deep Sleep": .deepSleep,
            "Core Sleep": .coreSleep,
            "REM Sleep": .remSleep,
            "Awake": .awakeSleep
        ])
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.weekday())
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .stride(by: 2)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .frame(height: 250)
    }

    func chart(for sleepAnalysis: SleepAnalysis) -> some View {
        Chart {
            RectangleMark(
                xStart: .value("Start", 7),
                xEnd: .value("End", 9),
                yStart: .value("Start", sleepAnalysis.startDate),
                yEnd: .value("End", sleepAnalysis.endOfEndDate)
            )
            .foregroundStyle(.green.opacity(0.3))

            BarMark(
                x: .value("Value", sleepAnalysis.deepSleepHours),
                y: .value("Date", sleepAnalysis.endDate, unit: .day)
            )
            .foregroundStyle(by: .value("Category", "Deep Sleep"))
            .cornerRadius(5)
            BarMark(
                x: .value("Value", sleepAnalysis.coreSleepHours),
                y: .value("Date", sleepAnalysis.endDate, unit: .day)
            )
            .foregroundStyle(by: .value("Category", "Core Sleep"))
            .cornerRadius(5)
            BarMark(
                x: .value("Value", sleepAnalysis.remSleepHours),
                y: .value("Date", sleepAnalysis.endDate, unit: .day)
            )
            .foregroundStyle(by: .value("Category", "REM Sleep"))
            .cornerRadius(5)
            BarMark(
                x: .value("Value", sleepAnalysis.awakeSleepHours),
                y: .value("Date", sleepAnalysis.endDate, unit: .day)
            )
            .foregroundStyle(by: .value("Category", "Awake"))
            .cornerRadius(5)
        }
        .chartForegroundStyleScale([
            "Deep Sleep": .deepSleep,
            "Core Sleep": .coreSleep,
            "REM Sleep": .remSleep,
            "Awake": .awakeSleep
        ])
        .chartXAxis {
            AxisMarks(values: .stride(by: 2)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 0)) { value in

            }
        }
        .frame(height: 100)
    }
}

#Preview {
    NavigationStack {
        SleepSummaryView(
            sleepAnalysises: [
                .init(
                    startDate: Date().addingTimeInterval(-25200),
                    endDate: Date(),
                    deepSleepMinutes: 45.2,
                    coreSleepMinutes: 180,
                    remSleepMinutes: 93,
                    awakeSleepMinutes: 32
                )
            ]
        )
    }
}
