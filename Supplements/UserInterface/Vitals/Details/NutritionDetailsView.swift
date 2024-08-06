//
//  NutritionDetailsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-05.
//

import SwiftUI
import Charts

struct NutritionDetailsView: View {

    @ObservedObject private var viewModel = VitalsViewModel.shared

    var body: some View {
        ScrollView {
            VStack {
                netEnergyChart
                    .cardContainer()
                macrosChart
                    .cardContainer()
                vitaminsChart
                    .cardContainer()
            }
            .padding()
            .horizontallyCentered()
        }
        .navigationTitle("Nutrition")
        .navigationBarTitleDisplayMode(.inline)
        .groupedBackground()
    }
}

private extension NutritionDetailsView {

    @ViewBuilder
    var netEnergyChart: some View {
        if let netEnergy = viewModel.nutritionSummary?.details.netEnergy {
            VStack(alignment: .leading) {
                VitalDetailChartTitleView(
                    title: "Net Energy",
                    value: "\(netEnergy.format()) Cals"
                )

                Chart {
                    BarMark(xStart: .value("Origin", 0), xEnd: .value("Net Energy", netEnergy))
                        .foregroundStyle(.green)
                        .cornerRadius(5)

                    RuleMark(
                        x: .value("Min", -500)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundStyle(.text)

                    RuleMark(
                        x: .value("Max", 500)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundStyle(.text)
                }
                .frame(height: 60)
                .chartXScale(
                    domain: -(abs(netEnergy) + 300)...(abs(netEnergy) + 300),
                    range: .plotDimension
                )

                if let netEnergyDescription = viewModel.nutritionSummary?.details.netEnergyDescription {
                    HStack {
                        Text(netEnergyDescription)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    @ViewBuilder
    var macrosChart: some View {
        if let details = viewModel.nutritionSummary?.details, let macros = details.macros {
            VStack(alignment: .leading) {
                VitalDetailChartTitleView(
                    title: "Macros",
                    valueLabel: "",
                    value: details.macroStatus?.rawValue ?? ""
                )

                Chart {
                    BarMark(x: .value("Protein", macros.protein))
                        .foregroundStyle(by: .value("Name", "Protein"))
                    BarMark(x: .value("Carbohydrates", macros.carbohydrates))
                        .foregroundStyle(by: .value("Name", "Carbohydrates"))
                    BarMark(x: .value("Fat", macros.fat))
                        .foregroundStyle(by: .value("Name", "Fat"))
                    BarMark(x: .value("Remainder", macros.remainder))
                        .foregroundStyle(by: .value("Name", "Remainder"))
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartLegend(.hidden)
                .chartForegroundStyleScale([
                    "Protein" : .pink,
                    "Carbohydrates" : .purple,
                    "Fat" : .indigo,
                    "Remainder" : .gray
                ])
                .frame(height: 80)

                Divider()

                HStack {
                    VStack {
                        LabelledMetric(
                            label: "Protein",
                            value: "\(macros.protein.format()) Cals"
                        )
                        .tint(.pink)
                        LabelledMetric(
                            label: "Fat",
                            value: "\(macros.fat.format()) Cals"
                        )
                        .tint(.indigo)
                    }
                    Spacer()
                    VStack {
                        LabelledMetric(
                            label: "Carbohydrates",
                            value: "\(macros.carbohydrates.format()) Cals"
                        )
                        .tint(.purple)
                        LabelledMetric(
                            label: "Remainder",
                            value: "\(macros.remainder.format()) Cals"
                        )
                        .tint(.gray)
                    }
                }
            }
        }
    }

    @ViewBuilder
    var vitaminsChart: some View {
        if let details = viewModel.nutritionSummary?.details, let _ = details.vitaminScore {
            VStack(alignment: .leading) {
                VitalDetailChartTitleView(
                    title: "Vitamins",
                    valueLabel: "",
                    value: details.vitaminStatus ?? ""
                )

                Divider()

                if let vitaminA = details.averageVitaminA?.doubleValue(for: .gramUnit(with: .micro)), let goal = HealthManager.shared.recommendedDailyIntakeForVitaminA() {
                    PillRangeChart(
                        title: "Vitamin A",
                        valueLabel: "\(vitaminA.format()) mcg",
                        value: vitaminA,
                        minValue: goal.lowerDoubleValue(for: .gramUnit(with: .micro)),
                        maxValue: goal.upperDoubleValue(for: .gramUnit(with: .micro))
                    )
                }
                if let vitaminB6 = details.averageVitaminB6?.doubleValue(for: .gramUnit(with: .milli)), let goal = HealthManager.shared.recommendedDailyIntakeForVitaminB6() {
                    PillRangeChart(
                        title: "Vitamin B6",
                        valueLabel: "\(vitaminB6.format()) mg",
                        value: vitaminB6,
                        minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
                        maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
                    )
                }
                if let vitaminB12 = details.averageVitaminB12?.doubleValue(for: .gramUnit(with: .micro)), let goal = HealthManager.shared.recommendedMinDailyIntakeForVitaminB12() {
                    PillRangeChart(
                        title: "Vitamin B12",
                        valueLabel: "\(vitaminB12.format()) mcg",
                        value: vitaminB12,
                        minValue: goal.doubleValue(for: .gramUnit(with: .micro)),
                        maxValue: goal.doubleValue(for: .gramUnit(with: .micro)) * 100
                    )
                }
                if let vitaminC = details.averageVitaminC?.doubleValue(for: .gramUnit(with: .milli)), let goal = HealthManager.shared.recommendedDailyIntakeForVitaminC() {
                    PillRangeChart(
                        title: "Vitamin C",
                        valueLabel: "\(vitaminC.format()) mg",
                        value: vitaminC,
                        minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
                        maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
                    )
                }
                if let vitaminD = details.averageVitaminD?.doubleValue(for: .gramUnit(with: .micro)), let goal = HealthManager.shared.recommendedDailyIntakeForVitaminD() {
                    PillRangeChart(
                        title: "Vitamin D",
                        valueLabel: "\(vitaminD.format()) mcg",
                        value: vitaminD,
                        minValue: goal.lowerDoubleValue(for: .gramUnit(with: .micro)),
                        maxValue: goal.upperDoubleValue(for: .gramUnit(with: .micro))
                    )
                }
                if let vitaminE = details.averageVitaminE?.doubleValue(for: .gramUnit(with: .milli)), let goal = HealthManager.shared.recommendedDailyIntakeForVitaminE() {
                    PillRangeChart(
                        title: "Vitamin E",
                        valueLabel: "\(vitaminE.format()) mcg",
                        value: vitaminE,
                        minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
                        maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
                    )
                }
            }
            .tint(.indigo)
        }
    }
}

#Preview {
    NavigationStack {
        NutritionDetailsView()
    }
}
