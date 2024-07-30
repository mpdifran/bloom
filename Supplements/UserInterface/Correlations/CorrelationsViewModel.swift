//
//  CorrelationsViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-29.
//

import Foundation

final class CorrelationsViewModel: ObservableObject {
    static let shared = CorrelationsViewModel()

    @Published var timeInDaylightSleepLengthCorrelationData: ([DataPair], Double)?
    @Published var activeEnergySleepLengthCorrelationData: ([DataPair], Double)?
    @Published var exerciseMinutesSleepScoreCorrelationData: ([DataPair], Double)?

    private init() { }
}

extension CorrelationsViewModel {

    func loadCorrelations() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                let data = await CorrelationEngine.shared.timeInDaylightAndSleepLengthCorrelation()

                await MainActor.run {
                    self.timeInDaylightSleepLengthCorrelationData = data
                }
            }

            group.addTask {
                let data = await CorrelationEngine.shared.activeEnergyAndSleepLengthCorrelation()

                await MainActor.run {
                    self.activeEnergySleepLengthCorrelationData = data
                }
            }

            group.addTask {
                let data = await CorrelationEngine.shared.exerciseMinutesAndSleepScoreCorrelation()

                await MainActor.run {
                    self.exerciseMinutesSleepScoreCorrelationData = data
                }
            }

            for await _ in group { }
        }
    }
}
