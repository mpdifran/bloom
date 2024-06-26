//
//  SleepSummaryView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-25.
//

import SwiftUI
import AppUI
import AppFoundations
import Charts

struct SleepSummaryView: View {
    @ObservedObject private var viewModel = SleepSummaryViewModel.shared

    @State private var presentedNavigationView: AnyView?
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
                HStack {
                    Label("Trends", systemImage: "arrow.down.left.arrow.up.right")
                    Spacer()
                    Image(systemName: "chevron.forward")
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: 13)
                        .fill(.background.secondary)
                }
                .contentShape(RoundedRectangle(cornerRadius: 13))
                .onTapGesture {
                    presentedNavigationView = SleepTrendsView().asAny
                }
                .padding(.vertical, 4)
                .standardListSeparatorInset()
            }

            ForEach(viewModel.sleepAnalyses.reversed()) { sleepAnalysis in
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
                        soundChart(for: sleepAnalysis)

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
        .listStyle(.plain)
        .navigationTitle("Sleep Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination($presentedNavigationView)
        .animation(.default, value: expandedSections)
    }
}

private extension SleepSummaryView {

    var earliestStartDate: Date? {
        viewModel.sleepAnalyses.min(by: { $0.startDate < $1.startDate })?.beginningOfStartDate
    }

    var latestEndDate: Date? {
        viewModel.sleepAnalyses.min(by: { $0.endDate > $1.endDate })?.endOfEndDate
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

            ForEach(viewModel.sleepAnalyses) { sleepAnalysis in
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

            ForEach(viewModel.sleepAnalyses) { sleepAnalysis in
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
                if let hours = value.as(Double.self) {
                    AxisValueLabel {
                        Text("\(hours, specifier: "%.0f")h")
                    }
                }
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

    func soundChart(for sleepAnalysis: SleepAnalysis) -> some View {
        SleepSoundLevelChartView(soundLevels: sleepAnalysis.environmentalSoundLevels)
    }
}

#Preview {
    NavigationStack {
        SleepSummaryView()
    }
}
