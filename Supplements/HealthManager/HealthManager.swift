//
//  HealthManager.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-08.
//

import SwiftUI
import HealthKit
import AppFoundations
import SwiftData
import BloomFoundation

extension TimeInterval {
    static let maxSleepGroupTimeDistance: TimeInterval = 7200 // 2 hours
    static let maxMenstruationTimeGap: TimeInterval = TimeInterval(60 * 60 * 24 * 2) // 2 days
}

struct HealthTargetDetails {
    let goal: HealthGoal
    let weightLossSpeed: WeightLossSpeed
}

enum HealthGoal: String {
    case none
    case gainWeight
    case maintainWeight
    case loseWeight
}

enum WeightLossSpeed: String, CaseIterable, Identifiable {
    var id: Self { self }

    case slow
    case moderate
    case fast
    
    var name: String {
        rawValue.capitalized
    }

    var weightLossDescription: String {
        switch self {
        case .slow:
            "About 0.5 lbs a week."
        case .moderate:
            "About 1 lb a week."
        case .fast:
            "About 2 lbs a week."
        }
    }
}


final class HealthManager: ObservableObject {
    static let shared = HealthManager()

    @Published var sleepAnalysis7Days: [SleepAnalysis]?
    @Published var sleepAnalysis30Days: [SleepAnalysis]?

    @AppStorage("HealthManager.isFemale") var isFemale = false
    @Published var birthday = Date.now {
        didSet { UserDefaults.group.set(birthday, forKey: "HealthManager.birthday") }
    }
    @Published var healthGoal: HealthGoal = .none {
        didSet { UserDefaults.group.set(healthGoal.rawValue, forKey: "HealthManager.healthGoal") }
    }
    @Published var weightLossSpeed: WeightLossSpeed = .moderate {
        didSet { UserDefaults.group.set(weightLossSpeed.rawValue, forKey: "HealthManager.weightLossSpeed") }
    }
    @Published var userReportedActivityLevel: ActivityLevelSummary.ActivityLevel? {
        didSet { UserDefaults.group.set(userReportedActivityLevel?.rawValue, forKey: "HealthManager.userReportedActivityLevel") }
    }

    var healthTargetDetails: HealthTargetDetails {
        HealthTargetDetails(
            goal: healthGoal,
            weightLossSpeed: weightLossSpeed
        )
    }

    @AppStorage("HealthManager.targetWeight", store: .group) var targetWeight: Double = 0
    @AppStorage("HealthManager.isPregnant") var isPregnant = false
    @AppStorage("HealthManager.isBreastfeeding") var isBreastfeeding = false

    let healthStore = HKHealthStore()
    private let throttler = Throttler(timeInterval: 600)

    private var backgroundDeliveryReferenceCounts = [HKObjectType : Int]() {
        didSet {
            print("Health Background Delivery Ref Counts: \(backgroundDeliveryReferenceCounts)")
        }
    }

    private var sleepObserverQueryHandle: HKObserverQueryHandle?
    private var sleepBackgroundDeliveryHandle: HKBackgroundDeliveryHandle?

    private init() {
        if let birthday = UserDefaults.group.object(forKey: "HealthManager.birthday") as? Date {
            self.birthday = birthday
        }
        if let healthGoalRaw = UserDefaults.group.string(forKey: "HealthManager.healthGoal") {
            self.healthGoal = HealthGoal(rawValue: healthGoalRaw) ?? .none
        }
        if let weightLossSpeedRaw = UserDefaults.group.string(forKey: "HealthManager.weightLossSpeed") {
            self.weightLossSpeed = WeightLossSpeed(rawValue: weightLossSpeedRaw) ?? .moderate
        }
        if let activityLevelRaw = UserDefaults.group.string(forKey: "HealthManager.activityLevel") {
            self.userReportedActivityLevel = ActivityLevelSummary.ActivityLevel(rawValue: activityLevelRaw)
        }
    }
}

// MARK: Age and Sex

extension HealthManager {

    func attemptToReadAgeAndSex() {
        do {
            let birthdayComponents = try healthStore.dateOfBirthComponents()

            if let date = Calendar.current.date(from: birthdayComponents) {
                self.birthday = date
            }
        } catch { }

        do {
            let sex = try healthStore.biologicalSex().biologicalSex

            if sex == .female {
                isFemale = true
            }
        } catch {}
    }

    func age() -> Int {
        if let age = healthStore.age() {
            return age
        }
        return Calendar.current.dateComponents([.year], from: birthday, to: .now).year ?? 0
    }

    func sex() -> HKBiologicalSex {
        if let sex = healthStore.sex() {
            return sex
        }
        return isFemale ? .female : .male
    }

    func sexName() -> String {
        switch sex() {
        case .notSet:
            "Not Set"
        case .female:
            "Female"
        case .male:
            "Male"
        case .other:
            "Other"
        @unknown default:
            "Unknown"
        }
    }
}

// MARK: Health Goals

extension HealthManager {

    func hasMetWeightGoal(for bodyMass: HKQuantity) -> Bool {
        let weight = bodyMass.doubleValue(for: .pound())

        switch healthGoal {
        case .loseWeight:
            return weight < targetWeight
        case .gainWeight:
            return weight > targetWeight
        case .maintainWeight:
            return false
//            return weight.isWithinRange(of: targetWeight, precision: 0.05)
        case .none:
            return false
        }
    }
}

// MARK: Observing Data

extension HealthManager {

    func enableBackgroundDelivery(
        objectType: HKObjectType,
        frequency: HKUpdateFrequency = .immediate
    ) -> HKBackgroundDeliveryHandle {
        enableBackgroundDelivery(objectTypes: [objectType], frequency: frequency)
    }

    func enableBackgroundDelivery(
        objectTypes: [HKObjectType],
        frequency: HKUpdateFrequency = .immediate
    ) -> HKBackgroundDeliveryHandle {

        for objectType in objectTypes {
            print("Health Background Delivery Ref Counts: Enabling delivery for \(objectType).")
            // TODO: We should check the existing frequency and make sure we update it only if it's more often.
            healthStore.enableBackgroundDelivery(objectType: objectType, frequency: frequency)
            backgroundDeliveryReferenceCounts[objectType, default: 0] += 1
        }

        return HKBackgroundDeliveryHandle(objectTypes: objectTypes) { [weak self] in
            guard let self else { return }

            for objectType in objectTypes {
                var refCount = self.backgroundDeliveryReferenceCounts[objectType, default: 0]

                refCount -= 1

                if refCount <= 0 {
                    print("Health Background Delivery Ref Counts: Disabling delivery for \(objectType).")
                    healthStore.disableBackgroundDelivery(for: objectType) { success, error in
                        if let error {
                            print(error)
                        }
                    }
                }

                self.backgroundDeliveryReferenceCounts[objectType] = max(refCount, 0)
            }
        }
    }
}

// MARK: - Heart Rate

extension HealthManager {

    func goalRestingHeartRateForUser() -> (Double, Double) {
        let age = healthStore.age()
        let sexObject = try? healthStore.biologicalSex()

        if let age {
            switch (age, sexObject?.biologicalSex) {

            case (18...25, .male):
                return (60, 70)
            case (26...35, .male), (18...25, .female):
                return (70, 75)
            case (36...45, .male), (26...35, .female):
                return (75, 80)
            case (46...55, .male), (36...45, .female):
                return (80, 85)
            case (56...65, .male), (46...55, .female):
                return (85, 90)
            case (66..., .male), (56...65, .female):
                return (90, 95)
            case (66..., .female):
                return (95, 100)
            default:
                break
            }
        }

        switch sexObject?.biologicalSex {
        case .female:
            return (65, 105)
        default:
            return (60, 100)
        }
    }

    func goalVO2MaxForUser() -> (Double, Double, Double)? {
        guard
            let age = healthStore.age(),
            let sexObject = try? healthStore.biologicalSex()
        else { return nil }

        switch sexObject.biologicalSex {
        case .male:
            switch age {
            case 20...29: return (57.0, 48.0, 38.0)
            case 30...39: return (52.0, 43.0, 34.0)
            case 40...49: return (47.0, 38.0, 31.0)
            case 50...59: return (41.0, 33.0, 26.0)
            case 60...: return (36.0, 28.0, 18.0)
            default: return nil
            }
        case .female:
            switch age {
            case 20...29: return (47.0, 38.0, 29.0)
            case 30...39: return (38.0, 30.0, 24.0)
            case 40...49: return (34.0, 27.0, 21.0)
            case 50...59: return (29.0, 23.0, 19.0)
            case 60...: return (25.0, 20.0, 15.0)
            default: return nil
            }
        default:
            return nil
        }
    }

    /// - note: https://www.mayoclinic.org/healthy-lifestyle/fitness/in-depth/exercise-intensity/art-20046887
    func heartRateZones() async -> HeartRateZones? {
        guard let age = healthStore.age() else { return nil }

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
    func goalBodyFatPercentage() -> (Double, Double, Double, Double, Double)? {
        guard let sexObject = try? healthStore.biologicalSex() else { return nil }

        switch sexObject.biologicalSex {
        case .female:
            return (0.14, 0.21, 0.25, 0.32, 0.50)
        case .male:
            return (0.06, 0.14, 0.18, 0.25, 0.43)
        default:
            return nil
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

    func bloodPressureStressScore(systolic: Double , diastolic: Double) -> Double {
        let systolicScore: Double
        if systolic <= 90 {
            systolicScore = systolic.scaledPercent(lower: 90, upper: 70)
        } else if systolic <= 120 {
            systolicScore = 0
        } else {
            systolicScore = (1 - systolic.scaledPercent(lower: 180, upper: 120)) * -1
        }

        let diastolicScore: Double
        if diastolic <= 60 {
            diastolicScore = diastolic.scaledPercent(lower: 60, upper: 40)
        } else if diastolic <= 80 {
            diastolicScore = 0
        } else {
            diastolicScore = (1 - diastolic.scaledPercent(lower: 110, upper: 80)) * -1
        }

        return [systolicScore, diastolicScore].average(keyPath: \.self)
    }
}

// MARK: - Nutitional Intake

extension HealthManager {

    /// unit: micrograms (mcg)
    /// - note: https://ods.od.nih.gov/factsheets/Biotin-HealthProfessional/
    func adequateDailyIntakeForBiotin() -> HKQuantity? {
        guard let age = healthStore.age() else { return nil }

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
    func recommendedMaxDailyCaffeine() -> HKQuantity? {
        guard let age = healthStore.age() else { return nil }

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
        guard let age = healthStore.age() else { return nil }

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

    /// unit: mg/dL
    /// - note: https://www.healthline.com/health/high-cholesterol/levels-by-age
    func recommendedDailyMaxCholesterol() -> HKQuantity? {
        guard let age = healthStore.age() else { return nil }

        if age < 20 {
            return HKQuantity(unit: .mgPerDL(), doubleValue: 170)
        } else {
            return HKQuantity(unit: .mgPerDL(), doubleValue: 200)
        }
    }

    /// unit: mcg
    /// - note: https://ods.od.nih.gov/factsheets/chromium-Consumer/
    func adequateDailyIntakeForChromium() -> HKQuantity? {
        guard let age = healthStore.age() else { return nil }

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
            if healthStore.sex() == .male {
                return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 25)
            }
            return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 21)
        } else if age < 19 {
            if healthStore.sex() == .male {
                return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 35)
            }
            return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 24)
        } else if age < 51 {
            if healthStore.sex() == .male {
                return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 35)
            }
            return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 25)
        } else {
            if healthStore.sex() == .male {
                return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 30)
            }
            return HKQuantity(unit: .gramUnit(with: .micro), doubleValue: 20)
        }
    }

    /// unit: mcg
    /// - note: https://ods.od.nih.gov/factsheets/Copper-Consumer/
    func recommendedDailyIntakeForCopper() -> HKQuantityRange? {
        guard let age = healthStore.age() else { return nil }

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
    func recommendedDailyIntakeForFolate() -> HKQuantityRange? {
        guard let age = healthStore.age() else { return nil }

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
    func adequateDailyIntakeForProtein() -> HKQuantity? {
        guard let age = healthStore.age() else { return nil }

        if healthStore.sex() == .female {
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
    func recommendedMaxDailyIntakeForSugar() -> HKQuantity? {
        guard let age = healthStore.age() else { return nil }

        if age < 19 {
            return HKQuantity(unit: .gram(), doubleValue: 25)
        }
        if healthStore.sex() == .female {
            return HKQuantity(unit: .gram(), doubleValue: 25)
        }
        return HKQuantity(unit: .gram(), doubleValue: 38)
    }

    /// unit: g
    /// - note: https://www.healthline.com/health/food-nutrition/how-much-fiber-per-day
    func recommendedMinDailyIntakeForFiber() -> HKQuantity? {
        guard let age = healthStore.age() else { return nil }

        if age < 19 {
            return HKQuantity(unit: .gram(), doubleValue: 14)
        } else if age < 51 {
            if healthStore.sex() == .female {
                return HKQuantity(unit: .gram(), doubleValue: 25)
            }
            return HKQuantity(unit: .gram(), doubleValue: 31)
        } else {
            if healthStore.sex() == .female {
                return HKQuantity(unit: .gram(), doubleValue: 22)
            }
            return HKQuantity(unit: .gram(), doubleValue: 28)
        }
    }

    /// unit: mcg
    /// - note: https://www.canada.ca/en/health-canada/services/food-nutrition/healthy-eating/dietary-reference-intakes/tables/reference-values-vitamins.html
    func recommendedDailyIntakeForVitaminA() -> HKQuantityRange? {
        guard let age = healthStore.age() else { return nil }

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
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .micro), range: 700...2800)
            }
            return HKQuantityRange(unit: .gramUnit(with: .micro), range: 900...2800)
        } else {
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .micro), range: 700...3000)
            }
            return HKQuantityRange(unit: .gramUnit(with: .micro), range: 900...3000)
        }
    }

    /// unit: mg
    /// - note: https://www.canada.ca/en/health-canada/services/food-nutrition/healthy-eating/dietary-reference-intakes/tables/reference-values-vitamins.html#tbl2
    func recommendedDailyIntakeForVitaminB6() -> HKQuantityRange? {
        guard let age = healthStore.age() else { return nil }

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
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1.2...80)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1.3...80)
        } else if age < 51 {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1.3...100)
        } else {
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1.5...100)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1.7...100)
        }
    }

    /// unit: mcg
    /// - note: https://www.canada.ca/en/health-canada/services/food-nutrition/healthy-eating/dietary-reference-intakes/tables/reference-values-vitamins.html
    func recommendedMinDailyIntakeForVitaminB12() -> HKQuantity? {
        guard let age = healthStore.age() else { return nil }

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
    func recommendedDailyIntakeForVitaminC() -> HKQuantityRange? {
        guard let age = healthStore.age() else { return nil }

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
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 65...1800)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 75...1800)
        } else {
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 75...2000)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 90...2000)
        }
    }

    /// unit: mcg
    /// - note: https://www.canada.ca/en/health-canada/services/food-nutrition/healthy-eating/dietary-reference-intakes/tables/reference-values-vitamins.html
    func recommendedDailyIntakeForVitaminD() -> HKQuantityRange? {
        guard let age = healthStore.age() else { return nil }

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
    func recommendedDailyIntakeForVitaminE() -> HKQuantityRange? {
        guard let age = healthStore.age() else { return nil }

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
    func recommendedIntakeForCalcium() -> HKQuantityRange? {
        guard let age = healthStore.age() else { return nil }

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
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1200...2000)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1000...2000)
        } else {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 1200...2000)
        }
    }

    /// unit: mg
    /// - note: https://ods.od.nih.gov/factsheets/Iron-HealthProfessional/
    func recommendedDailyIntakeForIron() -> HKQuantityRange? {
        guard let age = healthStore.age() else { return nil }

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
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 15...45)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 11...45)
        } else if age < 51 {
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 18...45)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 8...45)
        } else {
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 8...45)
        }
    }

    /// Magnesium from supplements specifically should be limited. Magnesium found in food is ok, and there's not really a UL for it.
    /// unit: mg
    /// - note: https://ods.od.nih.gov/factsheets/magnesium-healthprofessional/
    func recommendedDailyIntakeForMagnesium() -> HKQuantityRange? {
        guard let age = healthStore.age() else { return nil }

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
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 360...710)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 410...760)
        } else {
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 320...670)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 420...770)
        }
    }

    /// There is no recommended UL, so we're just picking an arbitrary number. There is no risk to this since any amount of Potassium is safe.
    /// unit: mg
    /// - note: https://ods.od.nih.gov/factsheets/Potassium-HealthProfessional/
    func recommendedDailyIntakeForPotassium() -> HKQuantityRange? {
        guard let age = healthStore.age() else { return nil }

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
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2300...10000)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2500...10000)
        } else if age < 19 {
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2300...10000)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 3000...10000)
        } else if age < 51 {
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2600...10000)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 3400...10000)
        } else {
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 2600...10000)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 3400...10000)
        }
    }

    /// unit: mg
    /// - note: https://www.verywellhealth.com/how-much-sodium-per-day-7971716#toc-for-overall-health-how-much-sodium-to-get-per-day
    func recommendedDailyIntakeForSodium() -> HKQuantityRange? {
        guard let age = healthStore.age() else { return nil }

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
    func recommendedDailyIntakeForZinc() -> HKQuantityRange? {
        guard let age = healthStore.age() else { return nil }

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
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 9...34)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 11...34)
        } else {
            if healthStore.sex() == .female {
                return HKQuantityRange(unit: .gramUnit(with: .milli), range: 8...40)
            }
            return HKQuantityRange(unit: .gramUnit(with: .milli), range: 11...40)
        }
    }
}
