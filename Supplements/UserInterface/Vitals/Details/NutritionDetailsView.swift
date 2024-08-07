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
                    .cardContainer(includePadding: false)
                vitaminsChart
                    .cardContainer()
                mineralsChart
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
            let samples = await HealthManager.shared.fetchNetEnergy(numPrevDays: 30)
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
                            LineMark(
                                x: .value("Date", sample.date),
                                y: .value("Net Energy", sample.quantity)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(.green)

                            PointMark(
                                x: .value("Date", sample.date),
                                y: .value("Net Energy", sample.quantity)
                            )
                            .foregroundStyle(.green)
                        }

                        RectangleMark(
                            yStart: .value("Max", 500),
                            yEnd: .value("Min", -500)
                        )
                        .foregroundStyle(.green.opacity(0.3))

                        RuleMark(
                            y: .value("Max", 500)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(.green)

                        RuleMark(
                            y: .value("Min", -500)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(.green)
                    }
                    .frame(height: 160)
                }

                Picker("", selection: $energyChartScope) {
                    Text("Daily")
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
                .padding(.horizontal)

                Divider()

                PillRangeChart(
                    title: "Protein",
                    unitString: "%",
                    value: (macros.protein / macros.total * 100),
                    minValue: HealthManager.shared.recommendedDailyProteinPercentOfDietaryEnergy().lowerBound * 100,
                    maxValue: HealthManager.shared.recommendedDailyProteinPercentOfDietaryEnergy().upperBound * 100
                )
                .tint(.protein)

                Divider()

                PillRangeChart(
                    title: "Carbohydrates",
                    unitString: "%",
                    value: (macros.carbohydrates / macros.total * 100),
                    minValue: HealthManager.shared.recommendedDailyCarbohydratesPercentOfDietaryEnergy().lowerBound * 100,
                    maxValue: HealthManager.shared.recommendedDailyCarbohydratesPercentOfDietaryEnergy().upperBound * 100
                )
                .tint(.carbohydrates)

                Divider()

                PillRangeChart(
                    title: "Fat",
                    unitString: "%",
                    value: (macros.fat / macros.total * 100),
                    minValue: HealthManager.shared.recommendedDailyFatPercentOfDietaryEnergy().lowerBound * 100,
                    maxValue: HealthManager.shared.recommendedDailyFatPercentOfDietaryEnergy().upperBound * 100
                )
                .tint(.fat)
            }
            .padding(.vertical)
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
                    CapsuleRangeChart(
                        title: "Vitamin A",
                        unitString: "mcg",
                        value: vitaminA,
                        minValue: goal.lowerDoubleValue(for: .gramUnit(with: .micro)),
                        maxValue: goal.upperDoubleValue(for: .gramUnit(with: .micro))
                    )
                    .tint(.vitaminA)
                }
                if let vitaminB6 = details.averageVitaminB6?.doubleValue(for: .gramUnit(with: .milli)), let goal = HealthManager.shared.recommendedDailyIntakeForVitaminB6() {
                    CapsuleRangeChart(
                        title: "Vitamin B6",
                        unitString: "mg",
                        value: vitaminB6,
                        minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
                        maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
                    )
                    .tint(.vitaminB6)
                }
                if let vitaminB12 = details.averageVitaminB12?.doubleValue(for: .gramUnit(with: .micro)), let goal = HealthManager.shared.recommendedMinDailyIntakeForVitaminB12() {
                    CapsuleRangeChart(
                        title: "Vitamin B12",
                        unitString: "mcg",
                        value: vitaminB12,
                        minValue: goal.doubleValue(for: .gramUnit(with: .micro)),
                        maxValue: 2000
                    )
                    .tint(.vitaminB12)
                }
                if let vitaminC = details.averageVitaminC?.doubleValue(for: .gramUnit(with: .milli)), let goal = HealthManager.shared.recommendedDailyIntakeForVitaminC() {
                    CapsuleRangeChart(
                        title: "Vitamin C",
                        unitString: "mg",
                        value: vitaminC,
                        minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
                        maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
                    )
                    .tint(.vitaminC)
                }
                if let vitaminD = details.averageVitaminD?.doubleValue(for: .gramUnit(with: .micro)), let goal = HealthManager.shared.recommendedDailyIntakeForVitaminD() {
                    CapsuleRangeChart(
                        title: "Vitamin D",
                        unitString: "mcg",
                        value: vitaminD,
                        minValue: goal.lowerDoubleValue(for: .gramUnit(with: .micro)),
                        maxValue: goal.upperDoubleValue(for: .gramUnit(with: .micro))
                    )
                    .tint(.vitaminD)
                }
                if let vitaminE = details.averageVitaminE?.doubleValue(for: .gramUnit(with: .milli)), let goal = HealthManager.shared.recommendedDailyIntakeForVitaminE() {
                    CapsuleRangeChart(
                        title: "Vitamin E",
                        unitString: "mg",
                        value: vitaminE,
                        minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
                        maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
                    )
                    .tint(.vitaminE)
                }
            }
        }
    }

    @ViewBuilder
    var mineralsChart: some View {
        if let details = viewModel.nutritionSummary?.details, let _ = details.mineralScore {
            VStack(alignment: .leading) {
                VitalDetailChartTitleView(
                    title: "Minerals",
                    valueLabel: "",
                    value: details.mineralStatus ?? ""
                )

                Divider()

                if let calcium = details.averageCalcium?.doubleValue(for: .gramUnit(with: .milli)), let goal = HealthManager.shared.recommendedDailyCalcium() {
                    CapsuleRangeChart(
                        title: "Calcium",
                        unitString: "mg",
                        value: calcium,
                        minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
                        maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
                    )
                    .tint(.calcium)
                }
                if let iron = details.averageIron?.doubleValue(for: .gramUnit(with: .milli)), let goal = HealthManager.shared.recommendedDailyIntakeForIron() {
                    CapsuleRangeChart(
                        title: "Iron",
                        unitString: "mg",
                        value: iron,
                        minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
                        maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
                    )
                    .tint(.iron)
                }
                if let magnesium = details.averageMagnesium?.doubleValue(for: .gramUnit(with: .milli)), let goal = HealthManager.shared.recommendedDailyIntakeForMagnesium() {
                    CapsuleRangeChart(
                        title: "Magnesium",
                        unitString: "mg",
                        value: magnesium,
                        minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
                        maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
                    )
                    .tint(.magnesium)
                }
                if let potassium = details.averagePotassium?.doubleValue(for: .gramUnit(with: .milli)), let goal = HealthManager.shared.recommendedDailyIntakeForPotassium() {
                    CapsuleRangeChart(
                        title: "Potassium",
                        unitString: "mg",
                        value: potassium,
                        minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
                        maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
                    )
                    .tint(.potassium)
                }
                if let zinc = details.averageZinc?.doubleValue(for: .gramUnit(with: .milli)), let goal = HealthManager.shared.recommendedDailyIntakeForZinc() {
                    CapsuleRangeChart(
                        title: "Zinc",
                        unitString: "mg",
                        value: zinc,
                        minValue: goal.lowerDoubleValue(for: .gramUnit(with: .milli)),
                        maxValue: goal.upperDoubleValue(for: .gramUnit(with: .milli))
                    )
                    .tint(.zinc)
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
