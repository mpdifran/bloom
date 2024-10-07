//
//  BowelMovementsDetailView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-29.
//

import SwiftUI
import Charts
import TelemetryDeck

struct BowelMovementsDetailView: View {

    @ObservedObject private var viewModel = VitalsViewModel.shared

    @State private var selectedBristolType = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                stoolTypeChart
                timeOfDayChart
            }
            .padding()
            .horizontallyCentered()
        }
        .animation(.default, value: selectedBristolType)
        .navigationTitle("Bowel Movements")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            TelemetryDeck.viewScreen("Bowel Movements Vital Details")
        }
    }
}

private extension BowelMovementsDetailView {

    var summary: BowelMovementMonthlySummary? {
        viewModel.bowelMovementSummary
    }

    @ViewBuilder
    var stoolTypeChart: some View {
        if let summary {
            VStack(alignment: .leading, spacing: 20) {
                VitalDetailChartTitleView(
                    title: "Bristol Stool Types",
                    value: ""
                )

                Chart {
                    ForEach(summary.bowelMovements) { bowelMovement in
                        if bowelMovement.isValidBristolStoolType {
                            LineMark(
                                x: .value("Date", bowelMovement.date),
                                y: .value("Bristol Stool Type", "Type \(bowelMovement.bristolStoolType)")
                            )
                            .foregroundStyle(.fill)

                            PointMark(
                                x: .value("Date", bowelMovement.date),
                                y: .value("Bristol Stool Type", "Type \(bowelMovement.bristolStoolType)")
                            )
                            .foregroundStyle(chartForegroundColor(for: bowelMovement.bristolStoolType))
                        }
                    }

                    if selectedBristolType != 0 {
                        RectangleMark(y: .value("Bristol Stool Type", "Type \(selectedBristolType)"))
                            .foregroundStyle(color(for: selectedBristolType).opacity(0.3))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .chartXScale(numDaysToNow: 30)
                .chartYScale(domain: ["Type 1", "Type 2", "Type 3", "Type 4", "Type 5", "Type 6", "Type 7"])
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel(offsetsMarks: false)
                    }
                }
                .frame(height: 350)

                typePicker

                detailsCardForSelectedStoolType
            }
        }
    }

    var chartMinDate: Date {
        summary?.bowelMovements.min(keyPath: \.date) ?? .now
    }

    func chartForegroundColor(for stoolType: Int) -> Color {
        if selectedBristolType == 0 || selectedBristolType == stoolType {
            return color(for: stoolType)
        }
        return color(for: stoolType).opacity(0.3)
    }

    var typePicker: some View {
        Button {
            selectedBristolType = (selectedBristolType + 1) % 8
        } label: {
            HStack {
                Text("Bristol Stool Type")

                Spacer()

                if selectedBristolType == 0 {
                    Text("All")
                } else {
                    Text("Type \(selectedBristolType)")
                }
            }
        }
        .buttonStyle(.zone)
        .tint(color(for: selectedBristolType))
        .sensoryFeedback(.selection, trigger: selectedBristolType)
    }

    var detailsCardForSelectedStoolType: some View {
        DetailInfoCardView {
            switch selectedBristolType {
            case 0:
                Text("The Bristol Stool Types are a standard mechanism to help categorize bowel movements. They can help provide insights into your gut health.")
            case 1:
                Text("This type indicates constipation. This can be caused by dehydration, lack of fiber, or other digestive issues. It may be beneficial to increase fluid intake and dietary fiber.")
            case 2:
                Text("This type indicates mild constipation. You might need to improve your diet, increase hydration, and consider physical activity to help regularize bowel movements.")
            case 3:
                Text("This type indicates a healthy gut with slight indication of dehydration. Maintaining a balanced diet with sufficient fiber and hydration is recommended.")
            case 4:
                Text("This type is the ideal stool. This indicates a healthy digestive system with normal bowel function. Continue with your current diet and lifestyle.")
            case 5:
                Text("This type may indicate a dietary change, mild digestive upset, or a temporary imbalance in your gut.")
            case 6:
                Text("This type can be caused by dietary issues, infections, stress, or other gastrointestinal problems. It’s important to stay hydrated and, if persistent, consider evaluating for potential infections or intolerances.")
            case 7:
                Text("This type represents severe diarrhea. This could indicate a significant gastrointestinal issue, such as an infection, food poisoning, or a chronic condition. It’s crucial to stay hydrated and seek medical advice if this persists.")
            default:
                EmptyView()
            }
        }
    }

    func color(for bristolStoolType: Int) -> Color {
        switch bristolStoolType {
        case 7: .vitalSevere
        case 1, 6: .vitalWarning
        case 2, 5: .vitalGood
        case 3, 4: .vitalGreat
        default: .brown
        }
    }

    @ViewBuilder
    var timeOfDayChart: some View {
        if let summary {
            VStack(alignment: .leading) {
                VitalDetailChartTitleView(
                    title: "Time Of Day",
                    value: ""
                )

                Chart {
                    ForEach(Calendar.TimeOfDay.allCases) { timeOfDay in
                        BarMark(
                            x: .value("Time Of Day", timeOfDay.name),
                            y: .value("Count", summary.timeOfDayDistribution[timeOfDay, default: []].count)
                        )
                        .foregroundStyle(color(for: timeOfDay))
                        .cornerRadius(8)
                    }
                }
                .frame(height: 250)
            }
        }
    }

    func color(for timeOfDay: Calendar.TimeOfDay) -> Color {
        switch timeOfDay {
        case .morning: .mutedYellow
        case .afternoon: .mutedOrange
        case .evening: .mutedPurple
        case .overnight: .mutedIndigo
        @unknown default:
            fatalError("Unhandled case")
        }
    }
}

#Preview {
    BowelMovementsDetailView()
}
