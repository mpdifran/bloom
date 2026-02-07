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
            for await menstrualSummary in await YouStatsCalculator.shared.$menstrualSummary {
                await MainActor.run {
                    self.menstrualSummary = menstrualSummary
                }
            }
        })
    }
}
