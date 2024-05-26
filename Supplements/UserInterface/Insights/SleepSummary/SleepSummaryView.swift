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
                    Text("Sleep History")
                        .font(.title3)
                        .bold()
                        .fontDesign(.rounded)
                    chartView
                }
            }

            ForEach(sleepAnalysises.reversed()) { sleepAnalysis in
                Section {
                    HStack {
                        Text(sleepAnalysis.timeSpanDescription)
                            .font(.title3)
                            .bold()
                            .fontDesign(.rounded)
                        
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
                            title: "Core Sleep Score",
                            minutes: sleepAnalysis.coreSleepMinutes,
                            score: sleepAnalysis.coreSleepScore
                        )
                        
                        SleepSegmentScoreView(
                            title: "Deep Sleep Score",
                            minutes: sleepAnalysis.deepSleepMinutes,
                            score: sleepAnalysis.deepSleepScore
                        )
                        
                        SleepSegmentScoreView(
                            title: "REM Sleep Score",
                            minutes: sleepAnalysis.remSleepMinutes,
                            score: sleepAnalysis.remSleepScore
                        )
                        
                        SleepSegmentScoreView(
                            title: "Sleep Length Score",
                            minutes: sleepAnalysis.timeIntervalMinutes,
                            showHours: true,
                            score: sleepAnalysis.sleepLengthScore
                        )
                    }
                }
            }
        }
        .navigationTitle("Sleep Analysis")
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
                    yStart: .value("Start", 420),
                    yEnd: .value("End", 540)
                )
                .foregroundStyle(.green.opacity(0.3))

                RectangleMark(
                    xStart: .value("Start", earliestStartDate),
                    xEnd: .value("End", latestEndDate),
                    yStart: .value("Start", 0),
                    yEnd: .value("End", 420)
                )
                .foregroundStyle(.red.opacity(0.3))
            }

            ForEach(sleepAnalysises) { sleepAnalysis in
                BarMark(
                    x: .value("Date", sleepAnalysis.endDate, unit: .day),
                    y: .value("Value", sleepAnalysis.deepSleepMinutes)
                )
                .foregroundStyle(by: .value("Category", "Deep Sleep"))
                .cornerRadius(5)
                BarMark(
                    x: .value("Date", sleepAnalysis.endDate, unit: .day),
                    y: .value("Value", sleepAnalysis.coreSleepMinutes)
                )
                .foregroundStyle(by: .value("Category", "Core Sleep"))
                .cornerRadius(5)
                BarMark(
                    x: .value("Date", sleepAnalysis.endDate, unit: .day),
                    y: .value("Value", sleepAnalysis.remSleepMinutes)
                )
                .foregroundStyle(by: .value("Category", "REM Sleep"))
                .cornerRadius(5)
                BarMark(
                    x: .value("Date", sleepAnalysis.endDate, unit: .day),
                    y: .value("Value", sleepAnalysis.awakeSleepMinutes)
                )
                .foregroundStyle(by: .value("Category", "Awake"))
                .cornerRadius(5)
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
            AxisMarks(values: .automatic) { value in
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
                xStart: .value("Start", 420),
                xEnd: .value("End", 540),
                yStart: .value("Start", sleepAnalysis.beginningOfStartDate),
                yEnd: .value("End", sleepAnalysis.endOfEndDate)
            )
            .foregroundStyle(.green.opacity(0.3))

            RectangleMark(
                xStart: .value("Start", 0),
                xEnd: .value("End", 420),
                yStart: .value("Start", sleepAnalysis.beginningOfStartDate),
                yEnd: .value("End", sleepAnalysis.endOfEndDate)
            )
            .foregroundStyle(.orange.opacity(0.3))

            BarMark(
                x: .value("Value", sleepAnalysis.deepSleepMinutes),
                y: .value("Date", sleepAnalysis.endDate, unit: .day)
            )
            .foregroundStyle(by: .value("Category", "Deep Sleep"))
            .cornerRadius(5)
            BarMark(
                x: .value("Value", sleepAnalysis.coreSleepMinutes),
                y: .value("Date", sleepAnalysis.endDate, unit: .day)
            )
            .foregroundStyle(by: .value("Category", "Core Sleep"))
            .cornerRadius(5)
            BarMark(
                x: .value("Value", sleepAnalysis.remSleepMinutes),
                y: .value("Date", sleepAnalysis.endDate, unit: .day)
            )
            .foregroundStyle(by: .value("Category", "REM Sleep"))
            .cornerRadius(5)
            BarMark(
                x: .value("Value", sleepAnalysis.awakeSleepMinutes),
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
        .chartYAxis {
            AxisMarks(values: ["Total"]) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
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
