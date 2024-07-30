//
//  CorrelationEngine.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-29.
//

import Foundation
import StatKit

final actor CorrelationEngine {
    static let shared = CorrelationEngine()

    private init() { }
}

extension CorrelationEngine {

    func timeInDaylightAndSleepLengthCorrelation() async -> ([DataPair], Double)? {
        let endDate = Date.now
        guard let startDate = Calendar.current.date(byAdding: .month, value: -6, to: endDate) else {
            return nil
        }

        let sleepAnalyses = await HealthManager.shared.fetchSleepAnalysis(startDate: startDate, endDate: endDate)
        let timeInDaylight = await HealthManager.shared.fetchTimeInDaylight(startDate: startDate, endDate: endDate)

        var dataSet = [DataPair]()

        for timeInDaylightSample in timeInDaylight {
            guard 
                let sleepAnalysis = sleepAnalyses.last(where: {
                    Calendar.current.isDate($0.endDate, nextDayAfter: timeInDaylightSample.date)
                }),
                sleepAnalysis.overallHours > 0.5
            else {
                continue
            }

            let pair = DataPair(
                date: timeInDaylightSample.date,
                a: timeInDaylightSample.quantity / 60,
                b: sleepAnalysis.overallHours
            )
            dataSet.append(pair)
        }

        let coefficient = correlationCoefficient(dataSet: dataSet)

        return (dataSet, coefficient)
    }

    func activeEnergyAndSleepLengthCorrelation() async -> ([DataPair], Double)? {
        let endDate = Date.now
        guard let startDate = Calendar.current.date(byAdding: .month, value: -6, to: endDate) else {
            return nil
        }

        let sleepAnalyses = await HealthManager.shared.fetchSleepAnalysis(startDate: startDate, endDate: endDate)
        let activeEnergies = await HealthManager.shared.fetchActiveEnergy(startDate: startDate, endDate: endDate)

        var dataSet = [DataPair]()

        for activeEnergySample in activeEnergies {
            guard
                let sleepAnalysis = sleepAnalyses.last(where: {
                    Calendar.current.isDate($0.endDate, nextDayAfter: activeEnergySample.date)
                }),
                sleepAnalysis.overallHours > 0.5
            else {
                continue
            }

            let pair = DataPair(
                date: activeEnergySample.date,
                a: activeEnergySample.quantity,
                b: sleepAnalysis.overallHours
            )
            dataSet.append(pair)
        }

        let coefficient = correlationCoefficient(dataSet: dataSet)

        return (dataSet, coefficient)
    }

    func exerciseMinutesAndSleepScoreCorrelation() async -> ([DataPair], Double)? {
        let endDate = Date.now
        guard let startDate = Calendar.current.date(byAdding: .month, value: -6, to: endDate) else {
            return nil
        }

        let sleepAnalyses = await HealthManager.shared.fetchSleepAnalysis(startDate: startDate, endDate: endDate)
        let exerciseMinutes = await HealthManager.shared.fetchExerciseMinutes(startDate: startDate, endDate: endDate)

        var dataSet = [DataPair]()

        for sample in exerciseMinutes {
            guard
                let sleepAnalysis = sleepAnalyses.last(where: {
                    Calendar.current.isDate($0.endDate, nextDayAfter: sample.date)
                }),
                sleepAnalysis.overallScoreDouble > 0.5
            else {
                continue
            }

            let pair = DataPair(
                date: sample.date,
                a: sample.quantity,
                b: sleepAnalysis.overallScoreDouble
            )
            dataSet.append(pair)
        }

        let coefficient = correlationCoefficient(dataSet: dataSet)

        return (dataSet, coefficient)
    }
}

private extension CorrelationEngine {

    func correlationCoefficient(dataSet: [DataPair]) -> Double {
        let covariance = covariance(dataSet, of: \.a, and: \.b, from: .population)

        let standardDevA = standardDeviation(of: dataSet, variable: \.a, from: .population)
        let standardDevB = standardDeviation(of: dataSet, variable: \.b, from: .population)

        return covariance / (standardDevA * standardDevB)
    }
}
