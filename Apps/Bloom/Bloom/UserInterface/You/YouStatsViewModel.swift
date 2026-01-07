//
//  YouStatsViewModel.swift
//  Bloom
//
//  Created by Assistant on 2024-12-29.
//

import SwiftUI
import CoreHealth

@Observable @MainActor
final class YouStatsViewModel: Sendable {
  static let shared = YouStatsViewModel()

  var activityLevelSummary: ActivityLevelSummary?
  var sleepVitalsSummary: SleepVitalsMonthlySummary?
  var heartHealthSummary: HeartHealthMonthlySummary?
  var bodyCompositionSummary: BodyCompositionMonthlySummary?
  var stressSummary: StressMonthlySummary?
  var nutritionSummary: NutritionMonthlySummary?
  var exerciseEffectivenessSummary: ExerciseEffectivenessMonthlySummary?
  var bowelMovementSummary: BowelMovementMonthlySummary?
  var menstrualSummary: MenstrualSummary?

  // YouStatsCalculator data
  var bedtimeChartData: BedtimeChartData?
  var averageSleepDuration: TimeInterval?
  var averageSleepScore: Double?
  var sleepStageDataPoints: [SleepStageDataPoint]?
  var averageSleepHeartRate: Double?
  var sleepHeartRateChartData: [SleepHeartRateDataPoint]?
  var sleepRespiratoryRateTrend: RespiratoryRateTrend?
  var sleepRespiratoryRateChartData: [RespiratoryRateDataPoint]?
  var wristTempData: WristTempData?
  var weeklyStepsChartData: WeeklyStepsChartData?
  var heartRateReserveChartData: HeartRateReserveChartData?
  var vo2MaxTrendData: VO2MaxTrendData?
  var heartRateRecoveryData: HeartRateRecoveryData?
  var bodyWeightChartData: BodyWeightChartData?
  var hrvChartData: HRVChartData?
  var bloodPressureData: BloodPressureCardData?
  var fiberChartData: FiberChartData?
  var sugarChartData: SugarChartData?
  var zoneMinutesData: ZoneMinutesData?
  var zoneDistributionData: ZoneDistributionData?
  var recentWorkoutsData: RecentWorkoutsData?
  var activeEnergyChartData: ActiveEnergyChartData?
  var sleepDurationChartData: SleepDurationChartData?
  var walkingSpeedChartData: WalkingSpeedChartData?
  var stairClimbSpeedChartData: StairClimbSpeedChartData?

  private var tasks = [Task<Void, Never>]()

  private init() {
    observeData()
  }
}

private extension YouStatsViewModel {

  func observeData() {
    tasks.removeAll(keepingCapacity: true)

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

    // YouStatsCalculator observations
    tasks.append(Task.detached {
      for await bedtimeChartData in await YouStatsCalculator.shared.$bedtimeChartData {
        await MainActor.run {
          self.bedtimeChartData = bedtimeChartData
        }
      }
    })
    tasks.append(Task.detached {
      for await averageSleepDuration in await YouStatsCalculator.shared.$averageSleepDuration {
        await MainActor.run {
          self.averageSleepDuration = averageSleepDuration
        }
      }
    })
    tasks.append(Task.detached {
      for await averageSleepScore in await YouStatsCalculator.shared.$averageSleepScore {
        await MainActor.run {
          self.averageSleepScore = averageSleepScore
        }
      }
    })
    tasks.append(Task.detached {
      for await sleepStageDataPoints in await YouStatsCalculator.shared.$sleepStageDataPoints {
        await MainActor.run {
          self.sleepStageDataPoints = sleepStageDataPoints
        }
      }
    })
    tasks.append(Task.detached {
      for await averageSleepHeartRate in await YouStatsCalculator.shared.$averageSleepHeartRate {
        await MainActor.run {
          self.averageSleepHeartRate = averageSleepHeartRate
        }
      }
    })
    tasks.append(Task.detached {
      for await sleepHeartRateChartData in await YouStatsCalculator.shared.$sleepHeartRateChartData {
        await MainActor.run {
          self.sleepHeartRateChartData = sleepHeartRateChartData
        }
      }
    })
    tasks.append(Task.detached {
      for await sleepRespiratoryRateTrend in await YouStatsCalculator.shared.$sleepRespiratoryRateTrend {
        await MainActor.run {
          self.sleepRespiratoryRateTrend = sleepRespiratoryRateTrend
        }
      }
    })
    tasks.append(Task.detached {
      for await sleepRespiratoryRateChartData in await YouStatsCalculator.shared.$sleepRespiratoryRateChartData {
        await MainActor.run {
          self.sleepRespiratoryRateChartData = sleepRespiratoryRateChartData
        }
      }
    })
    tasks.append(Task.detached {
      for await wristTempData in await YouStatsCalculator.shared.$wristTempData {
        await MainActor.run {
          self.wristTempData = wristTempData
        }
      }
    })
    tasks.append(Task.detached {
      for await weeklyStepsChartData in await YouStatsCalculator.shared.$weeklyStepsChartData {
        await MainActor.run {
          self.weeklyStepsChartData = weeklyStepsChartData
        }
      }
    })
    tasks.append(Task.detached {
      for await heartRateReserveChartData in await YouStatsCalculator.shared.$heartRateReserveChartData {
        await MainActor.run {
          self.heartRateReserveChartData = heartRateReserveChartData
        }
      }
    })
    tasks.append(Task.detached {
      for await vo2MaxTrendData in await YouStatsCalculator.shared.$vo2MaxTrendData {
        await MainActor.run {
          self.vo2MaxTrendData = vo2MaxTrendData
        }
      }
    })
    tasks.append(Task.detached {
      for await heartRateRecoveryData in await YouStatsCalculator.shared.$heartRateRecoveryData {
        await MainActor.run {
          self.heartRateRecoveryData = heartRateRecoveryData
        }
      }
    })
    tasks.append(Task.detached {
      for await bodyWeightChartData in await YouStatsCalculator.shared.$bodyWeightChartData {
        await MainActor.run {
          self.bodyWeightChartData = bodyWeightChartData
        }
      }
    })
    tasks.append(Task.detached {
      for await hrvChartData in await YouStatsCalculator.shared.$hrvChartData {
        await MainActor.run {
          self.hrvChartData = hrvChartData
        }
      }
    })
    tasks.append(Task.detached {
      for await bloodPressureData in await YouStatsCalculator.shared.$bloodPressureData {
        await MainActor.run {
          self.bloodPressureData = bloodPressureData
        }
      }
    })
    tasks.append(Task.detached {
      for await fiberChartData in await YouStatsCalculator.shared.$fiberChartData {
        await MainActor.run {
          self.fiberChartData = fiberChartData
        }
      }
    })
    tasks.append(Task.detached {
      for await sugarChartData in await YouStatsCalculator.shared.$sugarChartData {
        await MainActor.run {
          self.sugarChartData = sugarChartData
        }
      }
    })
    tasks.append(Task.detached {
      for await zoneMinutesData in await YouStatsCalculator.shared.$zoneMinutesData {
        await MainActor.run {
          self.zoneMinutesData = zoneMinutesData
        }
      }
    })
    tasks.append(Task.detached {
      for await zoneDistributionData in await YouStatsCalculator.shared.$zoneDistributionData {
        await MainActor.run {
          self.zoneDistributionData = zoneDistributionData
        }
      }
    })
    tasks.append(Task.detached {
      for await recentWorkoutsData in await YouStatsCalculator.shared.$recentWorkoutsData {
        await MainActor.run {
          self.recentWorkoutsData = recentWorkoutsData
        }
      }
    })
    tasks.append(Task.detached {
      for await activeEnergyChartData in await YouStatsCalculator.shared.$activeEnergyChartData {
        await MainActor.run {
          self.activeEnergyChartData = activeEnergyChartData
        }
      }
    })
    tasks.append(Task.detached {
      for await sleepDurationChartData in await YouStatsCalculator.shared.$sleepDurationChartData {
        await MainActor.run {
          self.sleepDurationChartData = sleepDurationChartData
        }
      }
    })
    tasks.append(Task.detached {
      for await walkingSpeedChartData in await YouStatsCalculator.shared.$walkingSpeedChartData {
        await MainActor.run {
          self.walkingSpeedChartData = walkingSpeedChartData
        }
      }
    })
    tasks.append(Task.detached {
      for await stairClimbSpeedChartData in await YouStatsCalculator.shared.$stairClimbSpeedChartData {
        await MainActor.run {
          self.stairClimbSpeedChartData = stairClimbSpeedChartData
        }
      }
    })
  }
}
