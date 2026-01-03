//
//  HealthGoalProvider.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-16.
//

import HealthKit

public final class HealthGoalProvider: Sendable {
  public static let shared = HealthGoalProvider()

  private let healthStore = HKHealthStore()

  private let healthDefaults = HealthDefaults.shared

  private init() { }
}

private extension HealthGoalProvider {
  var isFemale: Bool {
    // TODO: Update to use more appropriate guidelines for .other and .notSet
    healthDefaults.getSexKind() == .female
  }

  var age: Int {
    let birthYear = healthDefaults.getBirthYear()
    guard birthYear > 0 else { return 0 }
    let currentYear = Calendar.current.component(.year, from: .now)
    return currentYear - birthYear
  }
}

// MARK: Heart

public extension HealthGoalProvider {

  func goalRestingHeartRateForUser() -> (Double, Double) {
    switch (age, isFemale) {
    case (18...25, false):
      return (60, 70)
    case (26...35, false), (18...25, true):
      return (70, 75)
    case (36...45, false), (26...35, true):
      return (75, 80)
    case (46...55, false), (36...45, true):
      return (80, 85)
    case (56...65, false), (46...55, true):
      return (85, 90)
    case (66..., false), (56...65, true):
      return (90, 95)
    case (66..., true):
      return (95, 100)
    default:
      break
    }

    if isFemale {
      return (65, 105)
    } else {
      return (60, 100)
    }
  }

  func goalVO2MaxForUser() -> (Double, Double, Double)? {
    if isFemale {
      switch age {
      case 20...29: return (47.0, 38.0, 29.0)
      case 30...39: return (38.0, 30.0, 24.0)
      case 40...49: return (34.0, 27.0, 21.0)
      case 50...59: return (29.0, 23.0, 19.0)
      case 60...: return (25.0, 20.0, 15.0)
      default: return nil
      }
    } else {
      switch age {
      case 20...29: return (57.0, 48.0, 38.0)
      case 30...39: return (52.0, 43.0, 34.0)
      case 40...49: return (47.0, 38.0, 31.0)
      case 50...59: return (41.0, 33.0, 26.0)
      case 60...: return (36.0, 28.0, 18.0)
      default: return nil
      }
    }
  }

  /// - note: https://www.mayoclinic.org/healthy-lifestyle/fitness/in-depth/exercise-intensity/art-20046887
  func heartRateZones() async -> HeartRateZones? {
    let projectedMax = 208 - (Double(age) * 0.7)

    guard let restingHeartRate = try? await healthStore.fetchDailyAverageQuantity(
      for: .restingHeartRate,
      unit: .bpm(),
      dateRange: .trailingMonthsFromNow(6),
      option: .discreteAverage
    ).doubleValue(for: .bpm()).rounded() else {
      return nil
    }

    let heartRateReserve = projectedMax - restingHeartRate

    return HeartRateZones(
      heartRateReserve: heartRateReserve,
      restingHeartRate: restingHeartRate,
      maxHeartRate: projectedMax,
      zone1: (0.5 * heartRateReserve) + restingHeartRate,
      zone2: (0.6 * heartRateReserve) + restingHeartRate,
      zone3: (0.7 * heartRateReserve) + restingHeartRate,
      zone4: (0.8 * heartRateReserve) + restingHeartRate,
      zone5: (0.9 * heartRateReserve) + restingHeartRate
    )
  }

  /// - note: https://www.healthline.com/health/exercise-fitness/ideal-body-fat-percentage
  func goalBodyFatPercentage() -> BodyFatPercentageGoalThresholds {
    if isFemale {
      BodyFatPercentageGoalThresholds(
        maxEssentialFat: 0.14,
        maxAthleteFat: 0.21,
        maxFitFat: 0.25,
        maxHealthyFat: 0.32,
        maxHighFat: 0.50
      )
    } else {
      BodyFatPercentageGoalThresholds(
        maxEssentialFat: 0.06,
        maxAthleteFat: 0.14,
        maxFitFat: 0.18,
        maxHealthyFat: 0.25,
        maxHighFat: 0.43
      )
    }
  }

  func bloodPressureCategory(systolic: Double , diastolic: Double) -> BloodPressureCategory {
    if systolic > 180 || diastolic > 110 {
      return .hypertensiveCrisis
    } else if systolic > 160 || diastolic > 100 {
      return .hypertensionStage2
    } else if systolic > 140 || diastolic > 90 {
      return .hypertensionStage1
    } else if systolic > 120 || diastolic > 80 {
      return .elevated
    } else if systolic > 90 || diastolic > 60 {
      return .normal
    } else {
      return .low
    }
  }
}

// MARK: Nutitional

public extension HealthGoalProvider {

  /// unit: micrograms (mcg)
  /// - note: https://ods.od.nih.gov/factsheets/Biotin-HealthProfessional/
  func adequateDailyIntakeForBiotin() -> HKQuantity {
    if age < 4 {
      return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 8)
    } else if age < 9 {
      return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 12)
    } else if age < 14 {
      return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 20)
    } else if age < 19 {
      return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 25)
    } else {
      return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 30)
    }
  }

  /// unit: milligrams (mg)
  /// - note: https://www.opss.org/article/caffeine-performance
  func recommendedMaxDailyCaffeine() -> HKQuantity {
    if age < 12 {
      return HKQuantity(unit: .gramUnit(with: .milli), doubleValue: 0)
    } else if age < 19 {
      return HKQuantity(unit: .gramUnit(with: .milli), doubleValue: 100)
    } else {
      return HKQuantity(unit: .gramUnit(with: .milli), doubleValue: 400)
    }
  }

  /// unit: percent (%)
  /// - note: https://www.mayoclinic.org/healthy-lifestyle/nutrition-and-healthy-eating/in-depth/carbohydrates/art-20045705
  func recommendedDailyCarbohydratesPercentOfDietaryEnergy() -> ClosedRange<Double> {
    0.45...0.65
  }

  /// unit: grams
  /// - note: https://nutritionsource.hsph.harvard.edu/chloride/
  func adequateDailyIntakeForChloride() -> HKQuantity? {
    if age < 14 {
      return nil
    } else if age < 51 {
      return HKQuantity(unit: .gram(), doubleValue: 2.3)
    } else if age < 71 {
      return HKQuantity(unit: .gram(), doubleValue: 2)
    } else {
      return HKQuantity(unit: .gram(), doubleValue: 1.8)
    }
  }

  /// unit: mg
  /// - note: https://www.heart.org/en/news/2023/08/25/heres-the-latest-on-dietary-cholesterol-and-how-it-fits-in-with-a-healthy-diet
  func recommendedDailyMaxCholesterol() -> HKQuantity? {
    HKQuantity(unit: .gramUnit(with: .milli), doubleValue: 300)
  }

  /// unit: mcg
  /// - note: https://ods.od.nih.gov/factsheets/chromium-Consumer/
  func adequateDailyIntakeForChromium() async -> HKQuantity {
    let isPregnant = await HealthManager.shared.isPregnant
    let isBreastfeeding = await HealthManager.shared.isBreastfeeding

    if isPregnant {
      if age < 19 {
        return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 29)
      }
      return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 30)
    }
    if isBreastfeeding {
      if age < 19 {
        return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 44)
      }
      return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 45)
    }

    if age < 4 {
      return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 11)
    } else if age < 9 {
      return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 15)
    } else if age < 14 {
      if isFemale {
        return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 21)
      } else {
        return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 25)
      }
    } else if age < 19 {
      if isFemale {
        return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 24)
      } else {
        return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 35)
      }
    } else if age < 51 {
      if isFemale {
        return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 25)
      } else {
        return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 35)
      }
    } else {
      if isFemale {
        return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 20)
      } else {
        return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 30)
      }
    }
  }

  /// unit: mcg
  /// - note: https://ods.od.nih.gov/factsheets/Copper-Consumer/
  func recommendedDailyIntakeForCopper() async -> HKQuantityRange {
    let isPregnant = await HealthManager.shared.isPregnant
    let isBreastfeeding = await HealthManager.shared.isBreastfeeding

    if isBreastfeeding {
      return HKQuantityRange(unit: .gramUnit(with: .micro), range: 1300...10000)
    }
    if isPregnant {
      return HKQuantityRange(unit: .gramUnit(with: .micro), range: 1000...10000)
    }

    if age < 4 {
      return HKQuantityRange(unit: .gramUnit(with: .micro), range: 340...1000)
    } else if age < 9 {
      return HKQuantityRange(unit: .gramUnit(with: .micro), range: 440...3000)
    } else if age < 14 {
      return HKQuantityRange(unit: .gramUnit(with: .micro), range: 700...5000)
    } else if age < 19 {
      return HKQuantityRange(unit: .gramUnit(with: .micro), range: 890...8000)
    } else {
      return HKQuantityRange(unit: .gramUnit(with: .micro), range: 900...10000)
    }
  }

  /// unit: %
  /// - note: https://www.healthline.com/nutrition/how-much-fat-to-eat
  func recommendedDailyFatPercentOfDietaryEnergy() -> ClosedRange<Double> {
    0.2...0.35
  }

  /// unit: mcg
  /// - note: https://ods.od.nih.gov/factsheets/Folate-Consumer/
  func recommendedDailyIntakeForFolate() async -> HKQuantityRange {
    let isPregnant = await HealthManager.shared.isPregnant
    let isBreastfeeding = await HealthManager.shared.isBreastfeeding

    if isPregnant {
      return HKQuantityRange(unit: .gramUnit(with: .micro), range: 600...1000)
    }
    if isBreastfeeding {
      return HKQuantityRange(unit: .gramUnit(with: .micro), range: 500...1000)
    }

    if age < 4 {
      return HKQuantityRange(unit: .gramUnit(with: .micro), range: 150...300)
    } else if age < 9 {
      return HKQuantityRange(unit: .gramUnit(with: .micro), range: 200...400)
    } else if age < 14 {
      return HKQuantityRange(unit: .gramUnit(with: .micro), range: 300...600)
    } else if age < 19 {
      return HKQuantityRange(unit: .gramUnit(with: .micro), range: 400...800)
    } else {
      return HKQuantityRange(unit: .gramUnit(with: .micro), range: 400...1000)
    }
  }

  /// unit: %
  /// - note: https://www.medicalnewstoday.com/articles/protein-intake#calculating-requirements
  func recommendedDailyProteinPercentOfDietaryEnergy() -> ClosedRange<Double> {
    0.1...0.35
  }

  /// unit: gram
  /// - note: https://www.medicalnewstoday.com/articles/protein-intake#calculating-requirements
  func adequateDailyIntakeForProtein() -> HKQuantity {
    if isFemale {
      if age < 4 {
        return HKQuantity(unit: .gram(), doubleValue: 13)
      } else if age < 9 {
        return HKQuantity(unit: .gram(), doubleValue: 19)
      } else if age < 14 {
        return HKQuantity(unit: .gram(), doubleValue: 34)
      } else {
        return HKQuantity(unit: .gram(), doubleValue: 46)
      }
    } else {
      if age < 4 {
        return HKQuantity(unit: .gram(), doubleValue: 13)
      } else if age < 9 {
        return HKQuantity(unit: .gram(), doubleValue: 19)
      } else if age < 14 {
        return HKQuantity(unit: .gram(), doubleValue: 34)
      } else if age < 19 {
        return HKQuantity(unit: .gram(), doubleValue: 52)
      } else {
        return HKQuantity(unit: .gram(), doubleValue: 56)
      }
    }
  }

  /// unit: g
  /// - note: https://www.medicalnewstoday.com/articles/324673#recommended-limits
  func recommendedMaxDailyIntakeForSugar() -> HKQuantity {
    if age < 19 {
      return HKQuantity(unit: .gram(), doubleValue: 25)
    }
    if isFemale {
      return HKQuantity(unit: .gram(), doubleValue: 25)
    }
    return HKQuantity(unit: .gram(), doubleValue: 38)
  }

  /// unit: g
  /// - note: https://www.healthline.com/health/food-nutrition/how-much-fiber-per-day
  func recommendedMinDailyIntakeForFiber() -> HKQuantity {
    if age < 19 {
      return HKQuantity(unit: .gram(), doubleValue: 14)
    } else if age < 51 {
      if isFemale {
        return HKQuantity(unit: .gram(), doubleValue: 25)
      } else {
        return HKQuantity(unit: .gram(), doubleValue: 31)
      }
    } else {
      if isFemale {
        return HKQuantity(unit: .gram(), doubleValue: 22)
      } else {
        return HKQuantity(unit: .gram(), doubleValue: 28)
      }
    }
  }

  /// unit: mcg
  /// - note: https://www.canada.ca/en/health-canada/services/food-nutrition/healthy-eating/dietary-reference-intakes/tables/reference-values-vitamins.html
  @MainActor
  func recommendedDailyIntakeForVitaminA() -> HKQuantityRange {
    let isPregnant = HealthManager.shared.isPregnant
    let isBreastfeeding = HealthManager.shared.isBreastfeeding

    if isPregnant {
      if age < 19 {
        return HKQuantityRange(unit: .gramUnit(with: .micro), range: 750...2800)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .micro), range: 770...3000)
      }
    }
    if isBreastfeeding {
      if age < 19 {
        return HKQuantityRange(unit: .gramUnit(with: .micro), range: 1200...2800)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .micro), range: 1300...3000)
      }
    }

    if age < 4 {
      return HKQuantityRange(unit: .gramUnit(with: .micro), range: 300...600)
    } else if age < 9 {
      return HKQuantityRange(unit: .gramUnit(with: .micro), range: 400...900)
    } else if age < 14 {
      return HKQuantityRange(unit: .gramUnit(with: .micro), range: 600...1700)
    } else if age < 19 {
      if isFemale {
        return HKQuantityRange(unit: .gramUnit(with: .micro), range: 700...2800)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .micro), range: 900...2800)
      }
    } else {
      if isFemale {
        return HKQuantityRange(unit: .gramUnit(with: .micro), range: 700...3000)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .micro), range: 900...3000)
      }
    }
  }

  /// unit: mg
  /// - note: https://www.canada.ca/en/health-canada/services/food-nutrition/healthy-eating/dietary-reference-intakes/tables/reference-values-vitamins.html#tbl2
  @MainActor
  func recommendedDailyIntakeForVitaminB6() -> HKQuantityRange {
    let isPregnant = HealthManager.shared.isPregnant
    let isBreastfeeding = HealthManager.shared.isBreastfeeding

    if isPregnant {
      if age < 19 {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1.9...80)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1.9...100)
      }
    }
    if isBreastfeeding {
      if age < 19 {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2...80)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2...100)
      }
    }

    if age < 4 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 0.5...30)
    } else if age < 9 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 0.6...40)
    } else if age < 14 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1...60)
    } else if age < 19 {
      if isFemale {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1.2...80)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1.3...80)
      }
    } else if age < 51 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1.3...100)
    } else {
      if isFemale {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1.5...100)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1.7...100)
      }
    }
  }

  /// unit: mcg
  /// - note: https://www.canada.ca/en/health-canada/services/food-nutrition/healthy-eating/dietary-reference-intakes/tables/reference-values-vitamins.html
  @MainActor
  func recommendedMinDailyIntakeForVitaminB12() -> HKQuantity {
    let isPregnant = HealthManager.shared.isPregnant
    let isBreastfeeding = HealthManager.shared.isBreastfeeding

    if isPregnant {
      return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 2.6)
    }
    if isBreastfeeding {
      return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 2.8)
    }

    if age < 4 {
      return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 0.9)
    } else if age < 9 {
      return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 1.2)
    } else if age < 14 {
      return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 1.8)
    } else {
      return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 2.4)
    }
  }

  /// unit: mg
  /// - note: https://www.canada.ca/en/health-canada/services/food-nutrition/healthy-eating/dietary-reference-intakes/tables/reference-values-vitamins.html#tbl2
  @MainActor
  func recommendedDailyIntakeForVitaminC() -> HKQuantityRange {
    let isPregnant = HealthManager.shared.isPregnant
    let isBreastfeeding = HealthManager.shared.isBreastfeeding

    if isPregnant {
      if age < 19 {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 80...1800)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 85...2000)
      }
    }
    if isBreastfeeding {
      if age < 19 {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 115...1800)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 120...2000)
      }
    }

    if age < 4 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 15...400)
    } else if age < 9 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 25...650)
    } else if age < 14 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 45...1200)
    } else if age < 19 {
      if isFemale {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 65...1800)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 75...1800)
      }
    } else {
      if isFemale {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 75...2000)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 90...2000)
      }
    }
  }

  /// unit: mcg
  /// - note: https://www.canada.ca/en/health-canada/services/food-nutrition/healthy-eating/dietary-reference-intakes/tables/reference-values-vitamins.html
  @MainActor
  func recommendedDailyIntakeForVitaminD() -> HKQuantityRange {
    let isPregnant = HealthManager.shared.isPregnant
    let isBreastfeeding = HealthManager.shared.isBreastfeeding

    if isPregnant || isBreastfeeding {
      return HKQuantityRange(unit: .gramUnit(with: .micro), range: 15...100)
    }

    if age < 4 {
      return HKQuantityRange(unit: .gramUnit(with: .micro), range: 15...63)
    } else if age < 9 {
      return HKQuantityRange(unit: .gramUnit(with: .micro), range: 15...75)
    } else if age < 70 {
      return HKQuantityRange(unit: .gramUnit(with: .micro), range: 15...100)
    } else {
      return HKQuantityRange(unit: .gramUnit(with: .micro), range: 20...100)
    }
  }

  /// unit: mg
  /// - note: https://www.canada.ca/en/health-canada/services/food-nutrition/healthy-eating/dietary-reference-intakes/tables/reference-values-vitamins.html
  @MainActor
  func recommendedDailyIntakeForVitaminE() -> HKQuantityRange {
    let isPregnant = HealthManager.shared.isPregnant
    let isBreastfeeding = HealthManager.shared.isBreastfeeding

    if isPregnant {
      if age < 19 {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 15...800)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 15...1000)
      }
    }
    if isBreastfeeding {
      if age < 19 {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 19...800)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 19...1000)
      }
    }

    if age < 4 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 6...200)
    } else if age < 9 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 7...300)
    } else if age < 14 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 11...600)
    } else if age < 19 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 15...800)
    } else {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 15...1000)
    }
  }

  /// unit: mg
  /// - note: https://ods.od.nih.gov/factsheets/calcium-HealthProfessional/
  @MainActor
  func recommendedIntakeForCalcium() -> HKQuantityRange {
    let isPregnant = HealthManager.shared.isPregnant
    let isBreastfeeding = HealthManager.shared.isBreastfeeding

    if isPregnant || isBreastfeeding {
      if age < 19 {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1300...3000)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1000...2500)
      }
    }

    if age < 4 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 700...2500)
    } else if age < 9 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1000...2500)
    } else if age < 14 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1300...3000)
    } else if age < 19 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1300...3000)
    } else if age < 51 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1000...2500)
    } else if age < 70 {
      if isFemale {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1200...2000)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1000...2000)
      }
    } else {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1200...2000)
    }
  }

  /// unit: mg
  /// - note: https://ods.od.nih.gov/factsheets/Iron-HealthProfessional/
  @MainActor
  func recommendedDailyIntakeForIron() -> HKQuantityRange {
    let isPregnant = HealthManager.shared.isPregnant
    let isBreastfeeding = HealthManager.shared.isBreastfeeding

    if isPregnant {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 27...45)
    }
    if isBreastfeeding {
      if age < 19 {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 10...45)
      }
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 9...45)
    }

    if age < 4 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 7...40)
    } else if age < 9 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 10...40)
    } else if age < 14 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 8...40)
    } else if age < 19 {
      if isFemale {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 15...45)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 11...45)
      }
    } else if age < 51 {
      if isFemale {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 18...45)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 8...45)
      }
    } else {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 8...45)
    }
  }

  /// Magnesium from supplements specifically should be limited. Magnesium found in food is ok, and there's not really a UL for it.
  /// unit: mg
  /// - note: https://ods.od.nih.gov/factsheets/magnesium-healthprofessional/
  @MainActor
  func recommendedDailyIntakeForMagnesium() -> HKQuantityRange {
    let isPregnant = HealthManager.shared.isPregnant
    let isBreastfeeding = HealthManager.shared.isBreastfeeding

    if isPregnant {
      if age < 19 {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 400...750)
      } else if age < 31 {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 350...700)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 360...710)
      }
    }
    if isBreastfeeding {
      if age < 19 {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 360...710)
      } else if age < 31 {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 310...660)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 320...670)
      }
    }

    if age < 4 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 80...145)
    } else if age < 9 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 130...240)
    } else if age < 14 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 240...590)
    } else if age < 19 {
      if isFemale {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 360...710)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 410...760)
      }
    } else {
      if isFemale {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 320...670)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 420...770)
      }
    }
  }

  /// There is no recommended UL, so we're just picking an arbitrary number. There is no risk to this since any amount of Potassium is safe.
  /// unit: mg
  /// - note: https://ods.od.nih.gov/factsheets/Potassium-HealthProfessional/
  @MainActor
  func recommendedDailyIntakeForPotassium() -> HKQuantityRange {
    let isPregnant = HealthManager.shared.isPregnant
    let isBreastfeeding = HealthManager.shared.isBreastfeeding

    if isPregnant {
      if age < 19 {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2600...10000)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2900...10000)
      }
    }
    if isBreastfeeding {
      if age < 19 {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2500...10000)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2800...10000)
      }
    }

    if age < 4 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2000...10000)
    } else if age < 9 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2300...10000)
    } else if age < 14 {
      if isFemale {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2300...10000)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2500...10000)
      }
    } else if age < 19 {
      if isFemale {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2300...10000)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 3000...10000)
      }
    } else if age < 51 {
      if isFemale {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2600...10000)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 3400...10000)
      }
    } else {
      if isFemale {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2600...10000)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 3400...10000)
      }
    }
  }

  /// unit: mg
  /// - note: https://www.verywellhealth.com/how-much-sodium-per-day-7971716#toc-for-overall-health-how-much-sodium-to-get-per-day
  @MainActor
  func recommendedDailyIntakeForSodium() -> HKQuantityRange {
    if age < 4 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 500...1000)
    } else if age < 9 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 500...1200)
    } else if age < 14 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 500...1500)
    } else if age < 51 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 500...2300)
    } else if age < 71 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 500...1300)
    } else {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 500...1200)
    }
  }

  /// unit: mg
  /// - note: https://ods.od.nih.gov/factsheets/zinc-healthprofessional/
  @MainActor
  func recommendedDailyIntakeForZinc() -> HKQuantityRange {
    let isPregnant = HealthManager.shared.isPregnant
    let isBreastfeeding = HealthManager.shared.isBreastfeeding

    if isPregnant {
      if age < 19 {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 12...34)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 11...40)
      }
    }
    if isBreastfeeding {
      if age < 19 {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 13...34)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 12...40)
      }
    }

    if age < 4 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 3...7)
    } else if age < 9 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 5...12)
    } else if age < 14 {
      return HKQuantityRange(unit: .gramUnit(with: .milli), range: 8...23)
    } else if age < 19 {
      if isFemale {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 9...34)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 11...34)
      }
    } else {
      if isFemale {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 8...40)
      } else {
        return HKQuantityRange(unit: .gramUnit(with: .milli), range: 11...40)
      }
    }
  }
}

// MARK: - Biological Age Mappings

public extension HealthGoalProvider {

  /// Data point for linear interpolation mapping
  struct AgeDataPoint: Sendable {
    public let value: Double
    public let age: Double

    public init(value: Double, age: Double) {
      self.value = value
      self.age = age
    }
  }

  /// Data point for age delta mapping (trend/activity metrics)
  struct AgeDeltaDataPoint: Sendable {
    public let value: Double
    public let ageDelta: Double

    public init(value: Double, ageDelta: Double) {
      self.value = value
      self.ageDelta = ageDelta
    }
  }

  // MARK: VO2 Max

  /// VO2 Max to equivalent age mapping (higher VO2 = younger)
  func vo2MaxAgeDataPoints() -> [AgeDataPoint] {
    if isFemale {
      return [
        AgeDataPoint(value: 38.0, age: 25),
        AgeDataPoint(value: 30.0, age: 35),
        AgeDataPoint(value: 27.0, age: 45),
        AgeDataPoint(value: 23.0, age: 55),
        AgeDataPoint(value: 20.0, age: 65)
      ]
    } else {
      return [
        AgeDataPoint(value: 48.0, age: 25),
        AgeDataPoint(value: 43.0, age: 35),
        AgeDataPoint(value: 38.0, age: 45),
        AgeDataPoint(value: 33.0, age: 55),
        AgeDataPoint(value: 28.0, age: 65)
      ]
    }
  }

  // MARK: Resting Heart Rate

  /// RHR to equivalent age mapping (lower RHR = younger)
  func restingHeartRateAgeDataPoints() -> [AgeDataPoint] {
    if isFemale {
      return [
        AgeDataPoint(value: 70, age: 18),
        AgeDataPoint(value: 75, age: 25),
        AgeDataPoint(value: 80, age: 35),
        AgeDataPoint(value: 85, age: 45),
        AgeDataPoint(value: 90, age: 55),
        AgeDataPoint(value: 95, age: 65)
      ]
    } else {
      return [
        AgeDataPoint(value: 60, age: 18),
        AgeDataPoint(value: 70, age: 25),
        AgeDataPoint(value: 75, age: 35),
        AgeDataPoint(value: 80, age: 45),
        AgeDataPoint(value: 85, age: 55),
        AgeDataPoint(value: 90, age: 65)
      ]
    }
  }

  // MARK: Heart Rate Recovery

  /// HRR (1-min bpm drop) to equivalent age mapping (higher HRR = younger)
  func heartRateRecoveryAgeDataPoints() -> [AgeDataPoint] {
    [
      AgeDataPoint(value: 30, age: 20),
      AgeDataPoint(value: 25, age: 30),
      AgeDataPoint(value: 20, age: 40),
      AgeDataPoint(value: 15, age: 50),
      AgeDataPoint(value: 10, age: 60),
      AgeDataPoint(value: 5, age: 65)
    ]
  }

  // MARK: HRV Trend

  /// HRV percent change (7-day vs 30-day) to age delta mapping
  func hrvTrendAgeDeltaDataPoints() -> [AgeDeltaDataPoint] {
    [
      AgeDeltaDataPoint(value: 10, ageDelta: -5),
      AgeDeltaDataPoint(value: 5, ageDelta: -2.5),
      AgeDeltaDataPoint(value: 0, ageDelta: 0),
      AgeDeltaDataPoint(value: -5, ageDelta: 2.5),
      AgeDeltaDataPoint(value: -10, ageDelta: 5)
    ]
  }

  // MARK: Zone Minutes

  /// Weekly zone minutes to age delta mapping (more = younger)
  func zoneMinutesAgeDeltaDataPoints() -> [AgeDeltaDataPoint] {
    [
      AgeDeltaDataPoint(value: 300, ageDelta: -10),
      AgeDeltaDataPoint(value: 225, ageDelta: -7.5),
      AgeDeltaDataPoint(value: 150, ageDelta: -5),
      AgeDeltaDataPoint(value: 75, ageDelta: 0),
      AgeDeltaDataPoint(value: 0, ageDelta: 5)
    ]
  }

  // MARK: Activity Level

  /// Activity ratio to age delta mapping (higher = younger)
  func activityLevelAgeDeltaDataPoints() -> [AgeDeltaDataPoint] {
    [
      AgeDeltaDataPoint(value: 1.725, ageDelta: -5),
      AgeDeltaDataPoint(value: 1.55, ageDelta: -2.5),
      AgeDeltaDataPoint(value: 1.375, ageDelta: 0),
      AgeDeltaDataPoint(value: 1.2, ageDelta: 2.5),
      AgeDeltaDataPoint(value: 1.0, ageDelta: 5)
    ]
  }

  // MARK: Walking Speed

  /// Walking speed (m/s) to equivalent age mapping (faster = younger)
  func walkingSpeedAgeDataPoints() -> [AgeDataPoint] {
    [
      AgeDataPoint(value: 1.4, age: 20),
      AgeDataPoint(value: 1.3, age: 30),
      AgeDataPoint(value: 1.2, age: 45),
      AgeDataPoint(value: 1.0, age: 60),
      AgeDataPoint(value: 0.8, age: 65)
    ]
  }

  // MARK: Stair Climb Speed

  /// Stair climb speed (flights/min) to equivalent age mapping (faster = younger)
  func stairClimbSpeedAgeDataPoints() -> [AgeDataPoint] {
    [
      AgeDataPoint(value: 1.5, age: 20),
      AgeDataPoint(value: 1.2, age: 35),
      AgeDataPoint(value: 1.0, age: 50),
      AgeDataPoint(value: 0.8, age: 60),
      AgeDataPoint(value: 0.6, age: 65)
    ]
  }

  // MARK: Sleep Score

  /// Sleep score (0-100) to age delta mapping (higher = younger)
  func sleepScoreAgeDeltaDataPoints() -> [AgeDeltaDataPoint] {
    [
      AgeDeltaDataPoint(value: 90, ageDelta: -5),
      AgeDeltaDataPoint(value: 80, ageDelta: -2.5),
      AgeDeltaDataPoint(value: 70, ageDelta: 0),
      AgeDeltaDataPoint(value: 60, ageDelta: 2.5),
      AgeDeltaDataPoint(value: 50, ageDelta: 5)
    ]
  }

  // MARK: Sleep Duration Variability

  /// Sleep duration std dev (hours) to age delta mapping (lower = younger)
  func sleepDurationVariabilityAgeDeltaDataPoints() -> [AgeDeltaDataPoint] {
    [
      AgeDeltaDataPoint(value: 0.5, ageDelta: -2.5),
      AgeDeltaDataPoint(value: 1.0, ageDelta: 0),
      AgeDeltaDataPoint(value: 1.5, ageDelta: 2.5),
      AgeDeltaDataPoint(value: 2.0, ageDelta: 5)
    ]
  }

  // MARK: Bedtime Consistency

  /// Bedtime std dev (minutes) to age delta mapping (lower = younger)
  func bedtimeConsistencyAgeDeltaDataPoints() -> [AgeDeltaDataPoint] {
    [
      AgeDeltaDataPoint(value: 15, ageDelta: -2.5),
      AgeDeltaDataPoint(value: 30, ageDelta: 0),
      AgeDeltaDataPoint(value: 45, ageDelta: 2.5),
      AgeDeltaDataPoint(value: 60, ageDelta: 5)
    ]
  }

  // MARK: Sleep Heart Rate

  /// Sleep heart rate to equivalent age mapping (lower = younger)
  /// Derived from RHR × 0.9
  func sleepHeartRateAgeDataPoints() -> [AgeDataPoint] {
    if isFemale {
      return [
        AgeDataPoint(value: 63, age: 18),
        AgeDataPoint(value: 68, age: 25),
        AgeDataPoint(value: 72, age: 35),
        AgeDataPoint(value: 77, age: 45),
        AgeDataPoint(value: 81, age: 55),
        AgeDataPoint(value: 86, age: 65)
      ]
    } else {
      return [
        AgeDataPoint(value: 54, age: 18),
        AgeDataPoint(value: 63, age: 25),
        AgeDataPoint(value: 68, age: 35),
        AgeDataPoint(value: 72, age: 45),
        AgeDataPoint(value: 77, age: 55),
        AgeDataPoint(value: 81, age: 65)
      ]
    }
  }

  // MARK: Sleep Respiratory Rate

  /// Sleep respiratory rate (breaths/min) to equivalent age mapping (lower = younger)
  func sleepRespiratoryRateAgeDataPoints() -> [AgeDataPoint] {
    [
      AgeDataPoint(value: 12, age: 20),
      AgeDataPoint(value: 14, age: 35),
      AgeDataPoint(value: 16, age: 50),
      AgeDataPoint(value: 18, age: 60),
      AgeDataPoint(value: 20, age: 65)
    ]
  }

  // MARK: Body Fat Percentage

  /// Body fat % to age delta mapping (optimal range = younger)
  func bodyFatPercentageAgeDeltaDataPoints() -> [AgeDeltaDataPoint] {
    if isFemale {
      return [
        AgeDeltaDataPoint(value: 0.17, ageDelta: -5),
        AgeDeltaDataPoint(value: 0.21, ageDelta: -2.5),
        AgeDeltaDataPoint(value: 0.25, ageDelta: 0),
        AgeDeltaDataPoint(value: 0.32, ageDelta: 2.5),
        AgeDeltaDataPoint(value: 0.42, ageDelta: 5)
      ]
    } else {
      return [
        AgeDeltaDataPoint(value: 0.10, ageDelta: -5),
        AgeDeltaDataPoint(value: 0.14, ageDelta: -2.5),
        AgeDeltaDataPoint(value: 0.18, ageDelta: 0),
        AgeDeltaDataPoint(value: 0.25, ageDelta: 2.5),
        AgeDeltaDataPoint(value: 0.35, ageDelta: 5)
      ]
    }
  }

  // MARK: Blood Pressure

  /// Blood pressure category to age delta mapping
  func bloodPressureAgeDelta(for category: BloodPressureCategory) -> Double {
    switch category {
    case .normal:
      return 0
    case .low:
      return 2.5
    case .elevated:
      return 2.5
    case .hypertensionStage1:
      return 5
    case .hypertensionStage2:
      return 7.5
    case .hypertensiveCrisis:
      return 10
    }
  }

  // MARK: Macro Balance

  /// Count of macros in range to age delta mapping
  func macroBalanceAgeDelta(macrosInRange: Int) -> Double {
    switch macrosInRange {
    case 3:
      return -2.5
    case 2:
      return 0
    case 1:
      return 2.5
    default:
      return 5
    }
  }

  // MARK: Sugar Intake

  /// Sugar intake (% of limit) to age delta mapping
  func sugarIntakeAgeDeltaDataPoints() -> [AgeDeltaDataPoint] {
    [
      AgeDeltaDataPoint(value: 50, ageDelta: -2.5),
      AgeDeltaDataPoint(value: 100, ageDelta: 0),
      AgeDeltaDataPoint(value: 150, ageDelta: 2.5),
      AgeDeltaDataPoint(value: 200, ageDelta: 5)
    ]
  }

  // MARK: Bowel Regularity

  /// Bowel movement score to age delta mapping
  func bowelRegularityAgeDelta(score: Double) -> Double {
    if score >= 0.9 {
      return -2.5  // Excellent
    } else if score >= 0.6 {
      return 0     // Good
    } else if score >= 0.4 {
      return 2.5   // Fair
    } else {
      return 5     // Poor
    }
  }
}
