//
//  VitalsViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-22.
//

import SwiftUI
import HealthKit
import Combine
import AppFoundations
import DataContainer
import SwiftData
import CoreHealth

@Observable @MainActor
final class VitalsViewModel: Sendable {
    static let shared = VitalsViewModel()

    var vitals = [VitalModel]()
    var noDataVitals = [VitalModel]()
    var activityLevelSummary: ActivityLevelSummary?
    var sleepVitalsSummary: SleepVitalsMonthlySummary?
    var heartHealthSummary: HeartHealthMonthlySummary?
    var bodyCompositionSummary: BodyCompositionMonthlySummary?
    var stressSummary: StressMonthlySummary?
    var nutritionSummary: NutritionMonthlySummary?
    var exerciseEffectivenessSummary: ExerciseEffectivenessMonthlySummary?
    var bowelMovementSummary: BowelMovementMonthlySummary?
    var menstrualSummary: MenstrualSummary?

    private init() {
        observeData()
    }

    private var tasks = [Task<Void, Never>]()
}

extension VitalsViewModel {

    var allVitals: [VitalModel] {
        vitals + noDataVitals
    }

    func observeData() {
        tasks.removeAll(keepingCapacity: true)

        tasks.append(Task.detached {
            for await vitals in await VitalsCalculator.shared.$vitals {
                let dataVitals = vitals.filter({ !$0.hasNoData })
                let noDataVitals = vitals.filter(\.hasNoData)

                await MainActor.run {
                    self.vitals = dataVitals
                    self.noDataVitals = noDataVitals
                }
            }
        })
        tasks.append(Task.detached {
            for await activityLevelSummary in await VitalsCalculator.shared.$activityLevelSummary {
                await MainActor.run {
                    self.activityLevelSummary = activityLevelSummary
                }
            }
        })
        tasks.append(Task.detached {
            for await sleepVitalsSummary in await VitalsCalculator.shared.$sleepVitalsSummary {
                await MainActor.run {
                    self.sleepVitalsSummary = sleepVitalsSummary
                }
            }
        })
        tasks.append(Task.detached {
            for await heartHealthSummary in await VitalsCalculator.shared.$heartHealthSummary {
                await MainActor.run {
                    self.heartHealthSummary = heartHealthSummary
                }
            }
        })
        tasks.append(Task.detached {
            for await bodyCompositionSummary in await VitalsCalculator.shared.$bodyCompositionSummary {
                await MainActor.run {
                    self.bodyCompositionSummary = bodyCompositionSummary
                }
            }
        })
        tasks.append(Task.detached {
            for await stressSummary in await VitalsCalculator.shared.$stressSummary {
                await MainActor.run {
                    self.stressSummary = stressSummary
                }
            }
        })
        tasks.append(Task.detached {
            for await nutritionSummary in await VitalsCalculator.shared.$nutritionSummary {
                await MainActor.run {
                    self.nutritionSummary = nutritionSummary
                }
            }
        })
        tasks.append(Task.detached {
            for await exerciseEffectivenessSummary in await VitalsCalculator.shared.$exerciseEffectivenessSummary {
                await MainActor.run {
                    self.exerciseEffectivenessSummary = exerciseEffectivenessSummary
                }
            }
        })
        tasks.append(Task.detached {
            for await bowelMovementSummary in await VitalsCalculator.shared.$bowelMovementSummary {
                await MainActor.run {
                    self.bowelMovementSummary = bowelMovementSummary
                }
            }
        })
        tasks.append(Task.detached {
            for await menstrualSummary in await VitalsCalculator.shared.$menstrualSummary {
                await MainActor.run {
                    self.menstrualSummary = menstrualSummary
                }
            }
        })
    }
}
