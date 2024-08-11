//
//  BodyCompositionDetailsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-04.
//

import SwiftUI
import Charts
import Foundation

struct BodyCompositionDetailsView: View {

    @State private var bodyFatPercentageSamples = [DateAverageQuantitySample]()

    @ObservedObject private var viewModel = VitalsViewModel.shared

    @State private var selectedRangeIndex = 0

    private let ranges: [BodyCompositionMonthlySummary.PercentageRange] = [
        .essentialFat,
        .athlete,
        .fit,
        .healthy,
        .high
    ]

    let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                VStack {
                    chart

                    bodyFatPercentageRangePicker
                }
                .padding()
                .background {
                    Rectangle()
                        .fill(.background)
                        .ignoresSafeArea()
                }

                detailsSection
                    .padding(.horizontal)
            }
        }
        .navigationTitle("Body Composition")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.bouncy, value: range)
        .task {
            let samples = await HealthManager.shared.fetchBodyFatPercentageSamples()

            await MainActor.run {
                self.bodyFatPercentageSamples = samples
            }
        }
        .onAppear {
            feedbackGenerator.prepare()
            if
                let range = viewModel.bodyFatPercentageSummary?.range,
                let index = ranges.firstIndex(where: { $0 == range })
            {
                self.selectedRangeIndex = index
            }
        }
    }
}

private extension BodyCompositionDetailsView {

    var average: Double {
        bodyFatPercentageSamples.average(keyPath: \.averageQuantity) * 100
    }
}

private extension BodyCompositionDetailsView {

    var chart: some View {
        VStack(alignment: .leading) {
            VitalDetailChartTitleView(title: "Body Fat Percentage", value: "\(average.format())%")

            Chart {
                ForEach(bodyFatPercentageSamples) { sample in
                    LineMark(
                        x: .value("Date", sample.date, unit: .day),
                        y: .value("BPM", sample.averageQuantity)
                    )
                    .foregroundStyle(viewModel.bodyFatPercentageSummary?.range.color ?? .blue)

                    PointMark(
                        x: .value("Date", sample.date, unit: .day),
                        y: .value("Body Fat Percentage", sample.averageQuantity)
                    )
                    .foregroundStyle(viewModel.bodyFatPercentageSummary?.range.color ?? .blue)
                    .symbolSize(40)

                    if 
                        let goals = HealthManager.shared.goalBodyFatPercentage(),
                        let goal = range.rangeValues(from: goals)
                    {

                        RectangleMark(
                            yStart: .value("Min", goal.lowerBound),
                            yEnd: .value("Max", goal.upperBound)
                        )
                        .foregroundStyle(range.color.opacity(0.1))

                        RuleMark(
                            y: .value("Min", goal.lowerBound)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(range.color)

                        RuleMark(
                            y: .value("Max", goal.upperBound)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(range.color)
                    }
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: Decimal.FormatStyle.Percent.percent)
                }
            }
        }
    }

    var range: BodyCompositionMonthlySummary.PercentageRange {
        ranges[selectedRangeIndex]
    }

    @ViewBuilder
    var bodyFatPercentageRangePicker: some View {
        if let goal = HealthManager.shared.goalBodyFatPercentage() {
            Button {
                selectedRangeIndex = (selectedRangeIndex + 1) % ranges.count
                feedbackGenerator.impactOccurred()
            } label: {
                HStack {
                    Text(range.name)

                    Spacer()

                    Text(range.rangeDescription(from: goal))
                }
            }
            .buttonStyle(.zone)
            .tint(range.color)
        }
    }

    @ViewBuilder
    var detailsSection: some View {
        if range != .unknown {
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Details")
                        .font(.headline)
                        .bold()

                    switch range {
                    case .essentialFat:
                        Text("Essential fat is the minimum amount of fat necessary for basic physiological functions. It is crucial for the protection of internal organs, insulation, and reproductive health. It can be difficult on the body to remain in this range.")
                    case .athlete:
                        Text("This range is typical for athletes who require higher muscle mass and lower fat levels for optimal performance. It reflects a high level of fitness and conditioning.")
                    case .fit:
                        Text("Individuals in this range have a healthy amount of body fat and are usually quite active. This range is often seen in non-competitive athletes or individuals who maintain a consistent exercise routine.")
                    case .healthy:
                        Text("This range is considered normal for the general population. People within this range have a balanced level of body fat, contributing to overall health and well-being.")
                    case .high:
                        Text("Higher body fat percentages can be associated with an increased risk of health issues such as cardiovascular disease, diabetes, and other metabolic conditions. It may indicate a need for lifestyle changes to improve health.")
                    case .unknown:
                        EmptyView()
                    }

                    Link("Learn More", destination: URL(string: "https://www.healthline.com/health/exercise-fitness/ideal-body-fat-percentage")!)
                        .foregroundStyle(range.color)
                }
                Spacer(minLength: 0)
            }
            .cardContainer(fill: .background.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        BodyCompositionDetailsView()
    }
}
