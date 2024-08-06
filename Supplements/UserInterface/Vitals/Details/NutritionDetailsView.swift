//
//  NutritionDetailsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-05.
//

import SwiftUI
import Charts

private extension NutritionDetailsView {
    enum EnergyChartScope {
        case monthlyAverage
        case last7Days
    }
}

struct NutritionDetailsView: View {

    @ObservedObject private var viewModel = VitalsViewModel.shared

    @State private var energyChartScope = EnergyChartScope.monthlyAverage
    @State private var last7DaysEnergy = [DateQuantitySampleLegacy]()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
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
        .animation(.default, value: energyChartScope)
        .task {
            let samples = await HealthManager.shared.fetchNetEnergy()
            await MainActor.run {
                self.last7DaysEnergy = samples
            }
        }
    }
}

private extension NutritionDetailsView {

    @ViewBuilder
    var netEnergyChart: some View {
        if let netEnergy = viewModel.nutritionSummary?.details.netEnergy {
            VStack(alignment: .leading, spacing: 16) {
                VitalDetailChartTitleView(
                    title: "Net Energy",
                    valueLabel: "",
                    value: ""
                )

                switch energyChartScope {
                case .monthlyAverage:
                    if let details = viewModel.nutritionSummary?.details,
                       let basalEnergy = details.basalEnergyBurned?.doubleValue(for: .largeCalorie()),
                       let activeEnergy = details.activeEnergyBurned?.doubleValue(for: .largeCalorie()),
                       let dietaryEnergy = details.dietaryEnergy?.doubleValue(for: .largeCalorie()),
                       let netEnergy = details.netEnergy {
                        NetEnergyMathView(
                            basalEnergy: basalEnergy,
                            activeEnergy: activeEnergy,
                            dietaryEnergy: dietaryEnergy,
                            netEnergy: netEnergy
                        )
                    }

                    Chart {
                        BarMark(xStart: .value("Origin", 0), xEnd: .value("Net Energy", netEnergy))
                            .foregroundStyle(.green)
                            .cornerRadius(5)

                        RuleMark(
                            x: .value("Max", 500)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(.text)

                        RuleMark(
                            x: .value("Min", -500)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(.text)
                    }
                    .frame(height: 60)
                    .chartXScale(
                        domain: -(abs(netEnergy) + 300)...(abs(netEnergy) + 300),
                        range: .plotDimension
                    )
                case .last7Days:
                    Chart{
                        ForEach(last7DaysEnergy) { sample in
                            BarMark(
                                x: .value("Date", sample.date),
                                y: .value("Net Energy", sample.quantity)
                            )
                            .foregroundStyle(.green)
                        }

                        RuleMark(
                            y: .value("Max", 500)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(.text)

                        RuleMark(
                            y: .value("Min", -500)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(.text)
                    }
                    .frame(height: 160)
                }

                Picker("", selection: $energyChartScope) {
                    Text("Last 7 Days")
                        .tag(EnergyChartScope.last7Days)

                    Text("Monthly Average")
                        .tag(EnergyChartScope.monthlyAverage)
                }
                .pickerStyle(.segmented)

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
                    "Protein" : .protein,
                    "Carbohydrates" : .carbohydrates,
                    "Fat" : .fat,
                    "Remainder" : .gray
                ])
                .frame(height: 80)

                Divider()

                VStack {
                    HStack {
                        LabelledMetric(
                            label: "Protein",
                            value: "\(macros.protein.format()) Cals"
                        )
                        .tint(.protein)
                        Spacer()
                        LabelledMetric(
                            label: "Carbohydrates",
                            value: "\(macros.carbohydrates.format()) Cals"
                        )
                        .tint(.carbohydrates)
                        Spacer()
                        LabelledMetric(
                            label: "Fat",
                            value: "\(macros.fat.format()) Cals"
                        )
                        .tint(.fat)
                    }
                    HStack {
                        LabelledMetric(
                            label: "Remainder",
                            value: "\(macros.remainder.format()) Cals"
                        )
                        .tint(.gray)
                        Spacer()
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
                    .tint(.vitaminA)
                }
                if let vitaminB6 = details.averageVitaminB6?.doubleValue(for: .gramUnit(with: .milli)), let goal = HealthManager.shared.recommendedDailyIntakeForVitaminB6() {
                    PillRangeChart(
                        title: "Vitamin B6",
                        valueLabel: "\(vitaminB6.format()) mg",
                        value: vitaminB6,
                        minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
                        maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
                    )
                    .tint(.vitaminB6)
                }
                if let vitaminB12 = details.averageVitaminB12?.doubleValue(for: .gramUnit(with: .micro)), let goal = HealthManager.shared.recommendedMinDailyIntakeForVitaminB12() {
                    PillRangeChart(
                        title: "Vitamin B12",
                        valueLabel: "\(vitaminB12.format()) mcg",
                        value: vitaminB12,
                        minValue: goal.doubleValue(for: .gramUnit(with: .micro)),
                        maxValue: 2000
                    )
                    .tint(.vitaminB12)
                }
                if let vitaminC = details.averageVitaminC?.doubleValue(for: .gramUnit(with: .milli)), let goal = HealthManager.shared.recommendedDailyIntakeForVitaminC() {
                    PillRangeChart(
                        title: "Vitamin C",
                        valueLabel: "\(vitaminC.format()) mg",
                        value: vitaminC,
                        minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
                        maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
                    )
                    .tint(.vitaminC)
                }
                if let vitaminD = details.averageVitaminD?.doubleValue(for: .gramUnit(with: .micro)), let goal = HealthManager.shared.recommendedDailyIntakeForVitaminD() {
                    PillRangeChart(
                        title: "Vitamin D",
                        valueLabel: "\(vitaminD.format()) mcg",
                        value: vitaminD,
                        minValue: goal.lowerDoubleValue(for: .gramUnit(with: .micro)),
                        maxValue: goal.upperDoubleValue(for: .gramUnit(with: .micro))
                    )
                    .tint(.vitaminD)
                }
                if let vitaminE = details.averageVitaminE?.doubleValue(for: .gramUnit(with: .milli)), let goal = HealthManager.shared.recommendedDailyIntakeForVitaminE() {
                    PillRangeChart(
                        title: "Vitamin E",
                        valueLabel: "\(vitaminE.format()) mg",
                        value: vitaminE,
                        minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
                        maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
                    )
                    .tint(.vitaminE)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        NutritionDetailsView()
    }
}
