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

extension HealthManager {
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
}

final class HealthManager: ObservableObject {
    static let shared = HealthManager()

    @Published var authStatus: HKAuthorizationRequestStatus = .unknown

    @Published var sleepAnalysis7Days: [SleepAnalysis]?
    @Published var sleepAnalysis30Days: [SleepAnalysis]?
    @Published var sleepAnalysisPrevious30Days: [SleepAnalysis]?

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

    @AppStorage("HealthManager.targetWeightDifference", store: .group) var targetWeightDifference: Double = 0
    @AppStorage("HealthManager.isPregnant") var isPregnant = false
    @AppStorage("HealthManager.isBreastfeeding") var isBreastfeeding = false

    let healthStore = HKHealthStore()
    private let throttler = Throttler(timeInterval: 600)

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
        Task {
            try? await checkAccess()
        }
    }

    let bodyMeasurementTypes = [
        HKCharacteristicType(.dateOfBirth),
        HKCharacteristicType(.biologicalSex)
    ]

    let activityTypes = [
        HKObjectType.activitySummaryType(),
        HKQuantityType(.appleExerciseTime),
        HKQuantityType(.stepCount),
        HKQuantityType(.basalEnergyBurned),
        HKQuantityType(.activeEnergyBurned),
        HKObjectType.workoutType(),
        HKQuantityType(.distanceWalkingRunning)
    ]

    let heartTypes = [
        HKQuantityType(.heartRateVariabilitySDNN),
        HKQuantityType(.restingHeartRate),
        HKQuantityType(.vo2Max),
        HKQuantityType(.heartRate),
        HKQuantityType(.bloodPressureSystolic),
        HKQuantityType(.bloodPressureDiastolic),
        HKQuantityType(.heartRateRecoveryOneMinute),
    ]

    let writeHeartTypes = [
        HKQuantityType(.bloodPressureSystolic),
        HKQuantityType(.bloodPressureDiastolic)
    ]

    let sleepTypes = [
        HKCategoryType(.sleepAnalysis),
        HKQuantityType(.environmentalAudioExposure),
        HKQuantityType(.respiratoryRate),
        HKQuantityType(.appleSleepingWristTemperature),
    ]

    let nutritionTypes = [
        HKQuantityType(.dietaryEnergyConsumed),
//        HKQuantityType(.dietaryBiotin),
        HKQuantityType(.dietaryCaffeine),
        HKQuantityType(.dietaryCalcium),
        HKQuantityType(.dietaryCarbohydrates),
//        HKQuantityType(.dietaryChloride),
        HKQuantityType(.dietaryCholesterol),
//        HKQuantityType(.dietaryChromium),
//        HKQuantityType(.dietaryCopper),
        HKQuantityType(.dietaryFatMonounsaturated),
        HKQuantityType(.dietaryFatPolyunsaturated),
        HKQuantityType(.dietaryFatSaturated),
        HKQuantityType(.dietaryFatTotal),
        HKQuantityType(.dietaryFiber),
//        HKQuantityType(.dietaryFolate),
//        HKQuantityType(.dietaryIodine),
        HKQuantityType(.dietaryIron),
        HKQuantityType(.dietaryMagnesium),
//        HKQuantityType(.dietaryManganese),
//        HKQuantityType(.dietaryMolybdenum),
//        HKQuantityType(.dietaryNiacin),
//        HKQuantityType(.dietaryPantothenicAcid),
//        HKQuantityType(.dietaryPhosphorus),
        HKQuantityType(.dietaryPotassium),
        HKQuantityType(.dietaryProtein),
//        HKQuantityType(.dietaryRiboflavin),
//        HKQuantityType(.dietarySelenium),
        HKQuantityType(.dietarySodium),
        HKQuantityType(.dietarySugar),
//        HKQuantityType(.dietaryThiamin),
        HKQuantityType(.dietaryVitaminA),
        HKQuantityType(.dietaryVitaminB12),
        HKQuantityType(.dietaryVitaminB6),
        HKQuantityType(.dietaryVitaminC),
        HKQuantityType(.dietaryVitaminD),
        HKQuantityType(.dietaryVitaminE),
//        HKQuantityType(.dietaryVitaminK),
        HKQuantityType(.dietaryWater),
        HKQuantityType(.dietaryZinc)
    ]

    let writeNutritionTypes = [
        HKQuantityType(.dietaryWater)
    ]

    let menstrualTypes = [
        HKCategoryType(.menstrualFlow)
    ]

    let writeMenstrualTypes = [
        HKCategoryType(.menstrualFlow)
    ]

    let otherTypes = [
        HKQuantityType(.timeInDaylight),
        HKCategoryType(.mindfulSession),
        HKCategoryType(.appleWalkingSteadinessEvent),
        HKQuantityType(.sixMinuteWalkTestDistance),
        HKQuantityType(.walkingDoubleSupportPercentage),
        HKQuantityType(.bodyFatPercentage),
        HKQuantityType(.bodyMass)
    ]

    let writeOtherTypes = [
        HKQuantityType(.bodyMass)
    ]
}

extension HealthManager {

    var isAuthorized: Bool {
        authStatus == .unnecessary
    }

    func writeTypes() -> Set<HKSampleType> {
        var set = Set<HKSampleType>()

        writeNutritionTypes.forEach { set.insert($0) }
        writeHeartTypes.forEach { set.insert($0) }
        writeMenstrualTypes.forEach { set.insert($0) }
        writeOtherTypes.forEach { set.insert($0) }

        return set
    }

    func readTypes() -> Set<HKObjectType> {
        var set = Set<HKObjectType>()

        bodyMeasurementTypes.forEach { set.insert($0) }
        activityTypes.forEach { set.insert($0) }
        heartTypes.forEach { set.insert($0) }
        sleepTypes.forEach { set.insert($0) }
        nutritionTypes.forEach { set.insert($0) }
        menstrualTypes.forEach { set.insert($0) }
        otherTypes.forEach { set.insert($0) }

        return set
    }

    func checkAccess() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.getRequestStatusForAuthorization(toShare: writeTypes(), read: readTypes()) { authStatus, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                DispatchQueue.main.async {
                    self.authStatus = authStatus
                }
                continuation.resume()
            }
        }
    }

    func checkAccess(readTypes: [HKObjectType] = [], writeTypes: [HKSampleType] = []) async throws -> HKAuthorizationRequestStatus {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKAuthorizationRequestStatus, Error>) in
            healthStore.getRequestStatusForAuthorization(toShare: Set(writeTypes), read: Set(readTypes)) { authStatus, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: authStatus)
                }
            }
        }
    }

    func requestAccessIfNeeded() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        try? await checkAccess()
        if authStatus == .shouldRequest {
            do {
                try await healthStore.requestAuthorization(toShare: [], read: readTypes())
            } catch {
                print(error)
            }
        }
        try? await checkAccess()
    }
}

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

// MARK: Fetching Data

extension HealthManager {

    func fetchTotalSum(for quantityType: HKQuantityTypeIdentifier, dateRange: DateRange) async -> HKQuantity? {
        try? await healthStore.fetchQuantity(for: quantityType, dateRange: dateRange, option: .cumulativeSum)
    }

    func fetchCollatedQuantity(
        for quantityType: HKQuantityTypeIdentifier,
        unit: HKUnit,
        interval: DateComponents = DateComponents(day: 1),
        options: HKStatisticsOptions = [.cumulativeSum],
        dateRange: DateRange
    ) async -> [DateQuantitySample] {
        (try? await healthStore.fetchCollatedQuantity(
            quantityTypeID: quantityType,
            unit: unit,
            interval: interval,
            options: options,
            dateRange: dateRange
        )) ?? []
    }

    func fetchAverage(
        for quantityType: HKQuantityTypeIdentifier,
        unit: HKUnit,
        divisor: Double? = nil,
        dateRange: DateRange
    ) async -> HKQuantity {
        let totalSum = await fetchTotalSum(for: quantityType, dateRange: dateRange)
        let resolvedDivisor = divisor ?? Double(dateRange.numberOfDaysInclusive)
        let average = (totalSum?.doubleValue(for: unit) ?? 0) / resolvedDivisor

        return HKQuantity(unit: unit, doubleValue: average)
    }

    func fetchNutritionalDailyAverage(
        for quantityType: HKQuantityTypeIdentifier,
        unit: HKUnit,
        dateRange: DateRange
    ) async -> HKQuantity {
        let quantities = (try? await healthStore.fetchCollatedQuantity(
            quantityTypeID: quantityType,
            unit: unit,
            dateRange: dateRange
        )) ?? []
        let average = quantities.map({ $0.quantity.doubleValue(for: unit) }).average(keyPath: \.self)

        return HKQuantity(unit: unit, doubleValue: average)
    }

    func fetchWorkouts(activityType: HKWorkoutActivityType? = nil, dateRange: DateRange) async -> [HKWorkout] {
        (try? await healthStore.fetchWorkouts(activityType: activityType, dateRange: dateRange)) ?? []
    }

    func fetchWorkouts(activityTypes: [HKWorkoutActivityType] = [], dateRange: DateRange) async -> [HKWorkout] {
        (try? await healthStore.fetchWorkouts(activityTypes: activityTypes, dateRange: dateRange)) ?? []
    }

    func fetchCollatedWorkouts(
        activityType: HKWorkoutActivityType,
        interval: DateComponents = DateComponents(day: 1),
        dateRange: DateRange
    ) async -> [DateCollatedWorkouts] {
        await fetchCollatedWorkouts(activityTypes: [activityType], interval: interval, dateRange: dateRange)
    }

    func fetchCollatedWorkouts(
        activityTypes: [HKWorkoutActivityType] = [],
        interval: DateComponents = DateComponents(day: 1),
        dateRange: DateRange
    ) async -> [DateCollatedWorkouts] {
        (try? await healthStore.fetchCollatedWorkouts(
            activityTypes: activityTypes,
            interval: interval,
            dateRange: dateRange
        )) ?? []
    }

    func fetchTotalMeditationMinutes(dateRange: DateRange) async -> HKQuantity {
        let samples = (try? await healthStore.fetchSamples(for: HKCategoryType(.mindfulSession), dateRange: dateRange)) ?? []

        let meditationMinutes = samples.reduce(0) { (total, sample) -> Double in
            total + sample.timeInterval / 60
        }
        return HKQuantity(unit: .minute(), doubleValue: meditationMinutes)
    }

    func fetchCollatedMeditationMinutes(
        interval: DateComponents = DateComponents(day: 1),
        dateRange: DateRange
    ) async -> [DateQuantitySample] {
        let samples = (try? await healthStore.fetchSamples(for: HKCategoryType(.mindfulSession), dateRange: dateRange)) ?? []

        var collatedDates = [Date : Double]()

        for sample in samples {
            if let existingDate = collatedDates.keys.first(where: { date in
                let dateComponents = Calendar.current.dateComponents(
                    interval.calendarComponents,
                    from: date,
                    to: sample.startDate
                )
                return dateComponents < interval
            }) {
                collatedDates[existingDate, default: 0] += (sample.timeInterval / 60)
            } else {
                let referenceDate = Calendar.current.startOfDay(for: sample.startDate)
                collatedDates[referenceDate, default: 0] += (sample.timeInterval / 60)
            }
        }

        return collatedDates.map { (key: Date, value: Double) in
            DateQuantitySample(date: key, quantity: .init(unit: .minute(), doubleValue: value))
        }.sorted(keyPath: \.date)
    }

    func fetchMenstrualFlowSamples(dateRange: DateRange) async -> [MenstrualCycle] {
        let samples = (try? await healthStore.fetchSamples(for: HKCategoryType(.menstrualFlow), dateRange: dateRange)) ?? []
        let categorySamples = samples as? [HKCategorySample] ?? []

        return groupMenstrualCycles(from: categorySamples)
    }

    func fetchDietaryNutritionPercentage(
        quantityTypeID: HKQuantityTypeIdentifier,
        caloriesPerGram: Double,
        dateRange: DateRange
    ) async -> Double {
        do {
            let quantity = try await healthStore.fetchQuantity(
                for: quantityTypeID,
                dateRange: dateRange,
                option: .cumulativeSum
            )

            let dietaryEnergy = try await healthStore.fetchQuantity(
                for: .dietaryEnergyConsumed,
                dateRange: dateRange,
                option: .cumulativeSum
            )

            return (quantity.doubleValue(for: .gram()) * caloriesPerGram) / dietaryEnergy.doubleValue(for: .largeCalorie())
        } catch {
            print(error)
        }
        return 0
    }

    func fetchWorkoutHeartRateReports(dateRange: DateRange) async -> [WorkoutHeartRateReport] {
        guard let targetHeartRateZones = await heartRateZones() else { return [] }

        let workouts = (try? await healthStore.fetchWorkouts(dateRange: dateRange)) ?? []
        var reports = [WorkoutHeartRateReport]()

        for workout in workouts {
            guard let heartRateSamples = try? await healthStore.fetchSamples(
                for: HKQuantityType(.heartRate),
                dateRange: workout.dateRange
            ) as? [HKQuantitySample] else {
                continue
            }

            guard heartRateSamples.isNotEmpty else { continue }

            reports.append(
                WorkoutHeartRateReport(
                    workout: workout,
                    heartRateSamples: heartRateSamples,
                    heartRateZones: targetHeartRateZones
                )
            )
        }

        return reports
    }

    func fetchCollatedWorkoutHeartRateReports(
        interval: DateComponents = DateComponents(day: 1),
        dateRange: DateRange
    ) async -> [DateCollatedWorkoutHeartRateReport] {
        guard let targetHeartRateZones = await heartRateZones() else { return [] }

        let collatedWorkouts = await fetchCollatedWorkouts(interval: interval, dateRange: dateRange)

        var collatedReports = [DateCollatedWorkoutHeartRateReport]()

        for collatedWorkout in collatedWorkouts {
            var reports = [WorkoutHeartRateReport]()

            for workout in collatedWorkout.workouts {
                guard let heartRateSamples = try? await healthStore.fetchSamples(
                    for: HKQuantityType(.heartRate),
                    dateRange: workout.dateRange
                ) as? [HKQuantitySample] else {
                    continue
                }

                reports.append(
                    WorkoutHeartRateReport(
                        workout: workout,
                        heartRateSamples: heartRateSamples,
                        heartRateZones: targetHeartRateZones
                    )
                )
            }

            let collatedReport = DateCollatedWorkoutHeartRateReport(date: collatedWorkout.date, reports: reports)
            collatedReports.append(collatedReport)
        }

        return collatedReports
    }
}

// MARK: Writing Data

extension HealthManager {

    func write(sample: HKObject) async throws {
        try await healthStore.save(sample)
    }

    func write(samples: [HKObject]) async throws {
        try await healthStore.save(samples)
    }
}

// MARK: Vitals

extension HealthManager {

    func fetchActivityLevelSummary() async -> ActivityLevelSummary {
        let thisMonth = await fetchActivityLevelSummaryDetails(dateRange: .trailingMonthsFromNow(1))
        let lastMonth = await fetchActivityLevelSummaryDetails(dateRange: .trailingMonthsFromMonthsFromNow(monthsFromNow: 1, numberOfMonths: 1))

        return ActivityLevelSummary(details: thisMonth, lastMonthDetails: lastMonth)
    }

    func fetchActivityLevelSummaryDetails(dateRange: DateRange) async -> ActivityLevelSummary.Details {
        let unit = HKUnit.largeCalorie()
        let basal = (try? await healthStore.fetchCollatedQuantity(
            quantityTypeID: .basalEnergyBurned,
            unit: unit,
            dateRange: dateRange
        )) ?? []

        let active = (try? await healthStore.fetchCollatedQuantity(
            quantityTypeID: .activeEnergyBurned,
            unit: unit,
            dateRange: dateRange
        )) ?? []

        let ratios = calculateRatios(basalEnergy: basal, activeEnergy: active)

        return ActivityLevelSummary.Details(
            averageBasalEnergyBurned: basal.map({ $0.quantity.doubleValue(for: unit) }).average(keyPath: \.self),
            averageActiveEnergyBurned: active.map({ $0.quantity.doubleValue(for: unit) }).average(keyPath: \.self),
            energyRatioSamples: ratios
        )
    }

    func calculateRatios(basalEnergy: [DateQuantitySample], activeEnergy: [DateQuantitySample]) -> [DateValueSample] {
        var samples = [DateValueSample]()
        for basalSample in basalEnergy {
            guard let activeSample = activeEnergy.first(where: { Calendar.current.isDate($0.date, inSameDayAs: basalSample.date) }) else {
                continue
            }

            let unit = HKUnit.largeCalorie()
            let sum = activeSample.quantity.doubleValue(for: unit) + basalSample.quantity.doubleValue(for: unit)
            let ratio = sum / basalSample.quantity.doubleValue(for: unit)

            samples.append(.init(date: basalSample.date, value: ratio))
        }
        return samples
    }

    func fetchStressMonthlySummary() async -> StressMonthlySummary? {
        let thisMonth = await fetchStressMonthlySummaryDetails(dateRange: .trailingMonthsFromNow(1))
        let lastMonth = await fetchStressMonthlySummaryDetails(dateRange: .trailingMonthsFromMonthsFromNow(monthsFromNow: 1, numberOfMonths: 1))

        return StressMonthlySummary(details: thisMonth, lastMonthDetails: lastMonth)
    }

    func fetchStressMonthlySummaryDetails(dateRange: DateRange) async -> StressMonthlySummary.Details {
        let hrvAverage = (try? await healthStore.fetchQuantity(
            for: .heartRateVariabilitySDNN,
            dateRange: dateRange
        ))
        let hrvVariance = (try? await healthStore.fetchSamples(
            for: HKQuantityType(.heartRateVariabilitySDNN),
            dateRange: dateRange
        ))?.compactMap({ $0 as? HKQuantitySample })
            .map({ $0.quantity.doubleValue(for: .secondUnit(with: .milli)) })
            .variance(keyPath: \.self)

        let rhrAverage = (try? await healthStore.fetchQuantity(
            for: .restingHeartRate,
            dateRange: dateRange
        ))

        let systolicAverage = (try? await healthStore.fetchQuantity(
            for: .bloodPressureSystolic,
            dateRange: dateRange
        ))
        let diastolicAverage = (try? await healthStore.fetchQuantity(
            for: .bloodPressureDiastolic,
            dateRange: dateRange
        ))

        return StressMonthlySummary.Details(
            avgHeartRateVariability: hrvAverage?.doubleValue(for: .secondUnit(with: .milli)),
            varHeartRateVariability: hrvVariance,
            restingHeartRate: rhrAverage?.doubleValue(for: .bpm()),
            bloodPressureSystolic: systolicAverage?.doubleValue(for: .millimeterOfMercury()),
            bloodPressureDiastolic: diastolicAverage?.doubleValue(for: .millimeterOfMercury())
        )
    }

    func fetchCardioFitnessSummary() async -> CardioFitnessMonthlySummary {
        let thisMonth = await HealthManager.shared.fetchVO2Max()
        let hrr = await HealthManager.shared.fetchHeartRateRecovery()
        let lastMonth = await HealthManager.shared.fetchVO2Max(numPastMonths: 1)
        let hrrLastMonth = await HealthManager.shared.fetchHeartRateRecovery(numPastMonths: 1)

        return CardioFitnessMonthlySummary(
            averageVO2Max: thisMonth?.0,
            averageHeartRateRecovery: hrr?.0,
            lastMonthAverageVO2Max: lastMonth?.0,
            lastMonthAverageHeartRateRecovery: hrrLastMonth?.0
        )
    }

    func fetchBodyCompositionSummary() async -> BodyCompositionMonthlySummary {
        let thisMonth = await fetchBodyCompositionSummaryDetails(dateRange: .trailingMonthsFromNow(1))
        let lastMonth = await fetchBodyCompositionSummaryDetails(
            dateRange: .trailingMonthsFromMonthsFromNow(
                monthsFromNow: 1,
                numberOfMonths: 1
            )
        )
        return BodyCompositionMonthlySummary(details: thisMonth, lastMonthDetails: lastMonth)
    }

    func fetchBodyCompositionSummaryDetails(dateRange: DateRange) async -> BodyCompositionMonthlySummary.Details {
        let bodyFatPercentage = try? await healthStore.fetchQuantity(for: .bodyFatPercentage, dateRange: dateRange)
        let bodyMass = try? await healthStore.fetchQuantity(for: .bodyMass, dateRange: dateRange)

        return BodyCompositionMonthlySummary.Details(
            bodyFatPercentage: bodyFatPercentage,
            averageBodyMass: bodyMass
        )
    }

    func fetchExerciseEffectivenessSummary() async -> ExerciseEffectivenessMonthlySummary? {
        guard let targetHeartRateZones = await heartRateZones() else { return nil }

        let thisMonth = await fetchExerciseEffectivenessDetails(
            heartRateZones: targetHeartRateZones,
            dateRange: .trailingMonthsFromNow(1)
        )
        let lastMonth = await fetchExerciseEffectivenessDetails(
            heartRateZones: targetHeartRateZones,
            dateRange: .trailingMonthsFromMonthsFromNow(monthsFromNow: 1, numberOfMonths: 1)
        )

        return ExerciseEffectivenessMonthlySummary(
            details: thisMonth,
            lastMonthDetails: lastMonth
        )
    }

    func fetchExerciseEffectivenessDetails(
        heartRateZones: HeartRateZones,
        dateRange: DateRange
    ) async -> ExerciseEffectivenessMonthlySummary.Details {
        let workoutReports = await fetchWorkoutHeartRateReports(dateRange: dateRange)
        return ExerciseEffectivenessMonthlySummary.Details(
            heartRateZones: heartRateZones,
            workoutReports: workoutReports
        )
    }

    func fetchSleepVitalSummary() -> SleepVitalsMonthlySummary {
        let thisMonth = fetchSleepVitalSummaryDetails(sleepAnalyses: sleepAnalysis30Days ?? [])
        let lastMonth = fetchSleepVitalSummaryDetails(sleepAnalyses: sleepAnalysisPrevious30Days ?? [])

        return SleepVitalsMonthlySummary(
            details: thisMonth,
            lastMonthDetails: lastMonth
        )
    }

    func fetchSleepVitalSummaryDetails(sleepAnalyses: [SleepAnalysis]) -> SleepVitalsMonthlySummary.Details {

        if sleepAnalyses.isEmpty {
            return SleepVitalsMonthlySummary.Details(
                averageREMSleepPercent: nil,
                averageCoreSleepPercent: nil,
                averageDeepSleepPercent: nil,
                averageAwakeSleepPercent: nil,
                averageSleepLength: nil,
                averageSleepScore: nil
            )
        }

        return SleepVitalsMonthlySummary.Details(
            averageREMSleepPercent: sleepAnalyses.average(keyPath: \.remSleepPercent),
            averageCoreSleepPercent: sleepAnalyses.average(keyPath: \.coreSleepPercent),
            averageDeepSleepPercent: sleepAnalyses.average(keyPath: \.deepSleepPercent),
            averageAwakeSleepPercent: sleepAnalyses.average(keyPath: \.awakeSleepPercent),
            averageSleepLength: sleepAnalyses.average(keyPath: \.overallMinutes),
            averageSleepScore: sleepAnalyses.average(keyPath: \.overallScoreDouble)
        )
    }

    func fetchMenstrualSummary() async -> MenstrualSummary {
        let cycles = await fetchMenstrualFlowSamples(dateRange: .trailingMonthsFromNow(7))
        return MenstrualSummary(menstrualCycles: cycles)
    }
}

// MARK: Grouping Algorithms

extension HealthManager {

    func groupMenstrualCycles(from samples: [HKCategorySample]) -> [MenstrualCycle] {
        var cycles = [MenstrualCycle]()
        var currentCycleSamples = [HKCategorySample]()

        for sample in samples {
            if let lastSample = currentCycleSamples.last {
                let timeGap = sample.startDate.timeIntervalSince(lastSample.endDate)

                // If the gap is larger than the threshold
                if timeGap > .maxMenstruationTimeGap {
                    // Close out the current cycle and start a new one
                    let beginningOfCycleStartDate = currentCycleSamples.first(where: { $0.menstrualFlowCategory.marksBeginningOfCycle })?.startDate
                    let cycleStartDate = beginningOfCycleStartDate ?? currentCycleSamples.first?.startDate

                    if let cycleStartDate = cycleStartDate {
                        let cycle = MenstrualCycle(
                            startDate: cycleStartDate,
                            samples: currentCycleSamples
                        )
                        cycles.append(cycle)
                    }

                    currentCycleSamples = [sample]
                } else {
                    currentCycleSamples.append(sample)
                }
            } else {
                // First sample in a new cycle
                currentCycleSamples.append(sample)
            }
        }

        // Append the last cycle
        let beginningOfCycleStartDate = currentCycleSamples.first(where: { $0.menstrualFlowCategory.marksBeginningOfCycle })?.startDate
        let cycleStartDate = beginningOfCycleStartDate ?? currentCycleSamples.first?.startDate

        if let cycleStartDate = cycleStartDate, !currentCycleSamples.isEmpty {
            let cycle = MenstrualCycle(startDate: cycleStartDate, samples: currentCycleSamples)
            cycles.append(cycle)
        }

        return cycles
    }
}

// MARK: Deprecated

extension HealthManager {

    @available(*, deprecated, message: "Use fetchTotalSum instead")
    func fetchThisWeekSumQuantity(for quantityType: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
        let endDate = Date.now
        guard let startDate = Calendar.current.startOfWeek(for: endDate) else { return 0 }

        do {
            return try await healthStore.fetchQuantity(
                for: quantityType,
                start: startDate,
                end: endDate,
                option: .cumulativeSum
            ).doubleValue(for: unit)
        } catch {
            print(error)
        }
        return 0
    }

    @available(*, deprecated, message: "Use fetchTotalSum instead")
    func fetchWeeklyAverage(for quantityType: HKQuantityTypeIdentifier, unit: HKUnit, numWeeks: Int) async -> Double {
        guard
            let endDate = Calendar.current.startOfWeek(for: .now),
            let startDate = Calendar.current.date(byAdding: .weekOfYear, value: -numWeeks, to: endDate)
        else {
            return 0
        }

        do {
            let result = try await healthStore.fetchQuantity(
                for: quantityType,
                start: startDate,
                end: endDate,
                option: .cumulativeSum
            )

            return result.doubleValue(for: unit) / Double(numWeeks)
        } catch {
            print(error)
        }
        return 0
    }

    func fetchExerciseMinutes() async -> (Double, Int)? {
        do {
            return try await healthStore.fetchQuantity(
                for: .appleExerciseTime,
                pastMonths: 1,
                option: .cumulativeSum,
                unit: .minute()
            )
        } catch {
            print(error)
        }
        return nil
    }

    func fetchExerciseMinutes(startDate: Date, endDate: Date) async -> [DateQuantitySampleLegacy] {
        do {
            return try await healthStore.fetchCollectionQuantity(
                quantityTypeID: .appleExerciseTime,
                unit: .minute(),
                startDate: startDate,
                endDate: endDate
            )
        } catch {
            print(error)
        }
        return []
    }

    func fetchAverageSteps() async -> (Double, Int)? {
        do {
            return try await healthStore.fetchQuantity(
                for: .stepCount,
                pastMonths: 1,
                option: .cumulativeSum,
                unit: .count()
            )
        } catch {
            print(error)
        }
        return nil
    }

    func fetchHRV() async -> (Double, Int)? {
        do {
            return try await healthStore.fetchQuantity(
                for: .heartRateVariabilitySDNN,
                pastMonths: 1,
                unit: .secondUnit(with: .milli)
            )
        } catch {
            print(error)
        }
        return nil
    }

    func fetchRestingHeartRate(period: Int = 7) async -> [DateQuantitySampleLegacy] {
        do {
            let samples = try await healthStore.fetchSamples(for: .restingHeartRate, previousDays: period)

            return samples.compactMap { sample in
                sample as? HKQuantitySample
            }.map { sample in
                let value = sample.quantity.doubleValue(for: .bpm())
                return DateQuantitySampleLegacy(
                    date: sample.startDate,
                    quantity: value,
                    unit: "bpm"
                )
            }
        } catch {
            print(error)
        }
        return []
    }

    func fetchAverageRestingHeartRate(endDate: Date, period: Int = 7) async -> Double? {
        do {
            guard let startDate = Calendar.current.date(byAdding: .day, value: -period, to: endDate) else {
                return 0
            }

            return try await healthStore.fetchQuantity(
                for: .restingHeartRate,
                start: startDate,
                end: endDate,
                unit: .bpm()
            ).0
        } catch {
            print(error)
        }
        return nil
    }

    func fetchVO2Max(numPastMonths: Int = 0) async -> (Double, Int)? {
        do {
            guard let endDate = Calendar.current.date(byAdding: .month, value: -numPastMonths, to: .now),
                  let startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate)
            else {
                return nil
            }

            return try await healthStore.fetchQuantity(
                for: .vo2Max,
                start: startDate,
                end: endDate,
                option: .discreteAverage,
                unit: .vo2Max()
            )
        } catch {
            print(error)
        }
        return nil
    }

    func fetchHeartRateRecovery(numPastMonths: Int = 0) async -> (Double, Int)? {
        do {
            guard let endDate = Calendar.current.date(byAdding: .month, value: -numPastMonths, to: .now),
                  let startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate)
            else {
                return nil
            }

            return try await healthStore.fetchQuantity(
                for: .heartRateRecoveryOneMinute,
                start: startDate,
                end: endDate,
                option: .discreteAverage,
                unit: .bpm()
            )
        } catch {
            print(error)
        }
        return nil
    }

    func fetchVO2Max(numPastDays: Int) async -> [DateAverageQuantitySample] {
        let endDate = Date.now
        guard let startDate = Calendar.current.date(byAdding: .day, value: -numPastDays, to: endDate) else { return [] }

        return await fetchVO2Max(startDate: startDate, endDate: endDate)
    }

    func fetchVO2Max(startDate: Date, endDate: Date) async -> [DateAverageQuantitySample] {
        do {
            return try await healthStore.fetchAverageStatistics(
                quantityTypeID: .vo2Max,
                unit: .vo2Max(),
                startDate: startDate,
                endDate: endDate
            )
        } catch {
            print(error)
        }
        return []
    }

    func fetchAverageTimeInDaylight() async -> (Double, Int)? {
        do {
            return try await healthStore.fetchQuantity(
                for: .timeInDaylight,
                pastMonths: 1,
                option: .cumulativeSum,
                unit: .minute()
            )
        } catch {
            print(error)
        }
        return nil
    }

    func fetchTimeInDaylight(periodDays: Int = 14) async -> [DateQuantitySampleLegacy] {
        let endDate = Date.now
        guard let startDate = Calendar.current.date(byAdding: .day, value: -periodDays, to: endDate) else {
            return []
        }

        return await fetchTimeInDaylight(startDate: startDate, endDate: endDate)
    }

    func fetchTimeInDaylight(startDate: Date, endDate: Date) async -> [DateQuantitySampleLegacy] {
        do {
            return try await healthStore.fetchCollectionQuantity(
                quantityTypeID: .timeInDaylight,
                unit: .minute(),
                startDate: startDate,
                endDate: endDate
            )
        } catch {
            print(error)
        }
        return []
    }

    func fetchBasalEnergy(numPastMonths: Int = 0) async -> [DateQuantitySampleLegacy] {
        guard let endDate = Calendar.current.date(byAdding: .month, value: -numPastMonths, to: .now),
              let startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate)
        else {
            return []
        }

        return (
            try? await healthStore.fetchCollectionQuantity(
                quantityTypeID: .basalEnergyBurned,
                unit: .largeCalorie(),
                interval: .init(day: 1),
                startDate: startDate,
                endDate: endDate
            )
        ) ?? []
    }

    func fetchActiveEnergy(numPastMonths: Int = 0) async -> [DateQuantitySampleLegacy] {
        guard let endDate = Calendar.current.date(byAdding: .month, value: -numPastMonths, to: .now),
              let startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate)
        else {
            return []
        }

        return (
            try? await healthStore.fetchCollectionQuantity(
                quantityTypeID: .activeEnergyBurned,
                unit: .largeCalorie(),
                interval: .init(day: 1),
                startDate: startDate,
                endDate: endDate
            )
        ) ?? []
    }

    func fetchActiveEnergy(startDate: Date, endDate: Date) async -> [DateQuantitySampleLegacy] {
        do {
            return try await healthStore.fetchCollectionQuantity(
                quantityTypeID: .activeEnergyBurned,
                unit: .largeCalorie(),
                startDate: startDate,
                endDate: endDate
            )
        } catch {
            print(error)
        }
        return []
    }

    func calculateRatios(basalEnergy: [DateQuantitySampleLegacy], activeEnergy: [DateQuantitySampleLegacy]) -> [DateQuantitySampleLegacy] {
        var samples = [DateQuantitySampleLegacy]()

        for basalSample in basalEnergy {
            guard let activeSample = activeEnergy.first(where: { Calendar.current.isDate($0.date, inSameDayAs: basalSample.date) }) else {
                continue
            }

            let ratio = (activeSample.quantity + basalSample.quantity) / basalSample.quantity

            samples.append(
                .init(
                    date: basalSample.date,
                    quantity: ratio,
                    unit: ""
                )
            )
        }

        return samples
    }

    func fetchNetEnergy(numPrevDays: Int = 7) async -> [DateQuantitySampleLegacy] {
        let endDate = Date.now

        guard let startDate = Calendar.current.date(byAdding: .day, value: -numPrevDays, to: endDate) else { return [] }

        let basal = try? await healthStore.fetchCollectionQuantity(
            quantityTypeID: .basalEnergyBurned,
            unit: .largeCalorie(),
            startDate: startDate,
            endDate: endDate
        )

        let active = try? await healthStore.fetchCollectionQuantity(
            quantityTypeID: .activeEnergyBurned,
            unit: .largeCalorie(),
            startDate: startDate,
            endDate: endDate
        )

        let dietary = try? await healthStore.fetchCollectionQuantity(
            quantityTypeID: .dietaryEnergyConsumed,
            unit: .largeCalorie(),
            startDate: startDate,
            endDate: endDate
        )

        var samples = [DateQuantitySampleLegacy]()

        for basalSample in basal ?? [] {
            guard 
                let activeEnergy = active?.first(where: { Calendar.current.isDate($0.date, inSameDayAs: basalSample.date) })?.quantity,
                let dietaryEnergy = dietary?.first(where: { Calendar.current.isDate($0.date, inSameDayAs: basalSample.date) })?.quantity
            else {
                continue
            }

            let netEnergy = dietaryEnergy - basalSample.quantity - activeEnergy

            samples.append(.init(date: basalSample.date, quantity: netEnergy, unit: HKUnit.largeCalorie().unitString))
        }

        return samples
    }

    func fetchWorkoutSummaryLastTwoWeeks() async -> [WorkoutSummary] {
        do {
            let endDate = Date.now
            guard let startDate = Calendar.current.date(byAdding: .day, value: -14, to: endDate) else {
                return []
            }

            return try await healthStore.fetchWorkoutSummaries(startDate: startDate, endDate: endDate)
        } catch {
            print(error)
        }
        return []
    }

    @available(*, deprecated, message: "User DateRange method instead")
    func fetchWorkoutSummaries(activityType: HKWorkoutActivityType? = nil, numWeeks: Int) async -> [WorkoutSummary] {
        guard
            let endDate = Calendar.current.startOfWeek(for: .now),
            let startDate = Calendar.current.date(byAdding: .day, value: -numWeeks, to: endDate)
        else { return [] }

        return await fetchWorkoutSummaries(startDate: startDate, endDate: endDate, activityType: activityType)
    }

    @available(*, deprecated, message: "User DateRange method instead")
    func fetchWorkoutSummaries(
        startDate: Date,
        endDate: Date,
        activityType: HKWorkoutActivityType? = nil
    ) async -> [WorkoutSummary] {
        do {
            return try await healthStore.fetchWorkoutSummaries(
                startDate: startDate,
                endDate: endDate,
                activityType: activityType
            )
        } catch {
            print(error)
        }
        return []
    }

    @available(*, deprecated, message: "User DateRange method instead")
    func fetchWorkoutSummariesThisWeek(activityType: HKWorkoutActivityType? = nil) async -> [WorkoutSummary] {
        do {
            let endDate = Date.now
            guard let startDate = Calendar.current.startOfWeek(for: endDate) else { return [] }

            return try await healthStore.fetchWorkoutSummaries(
                startDate: startDate,
                endDate: endDate,
                activityType: activityType
            )
        } catch {
            print(error)
        }
        return []
    }

    func fetchWorkoutSummation(pastDays: Int) async -> [WorkoutSummation] {
        let endDate = Date()

        guard let startDate = Calendar.current.date(byAdding: .day, value: -pastDays, to: endDate) else { return [] }

        return (try? await healthStore.fetchWorkoutSummation(startDate: startDate, endDate: endDate)) ?? []
    }

    func fetchBodyFatPercentageSamples() async -> [DateAverageQuantitySample] {
        let endDate = Date()

        guard let startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate) else { return [] }

        do {
            return try await healthStore.fetchAverageStatistics(
                quantityTypeID: .bodyFatPercentage,
                unit: .percent(),
                interval: .init(day: 1),
                startDate: startDate,
                endDate: endDate
            )
        } catch { }
        return []
    }

    func fetchAverageBodyFatPercentage(numPastMonths: Int = 0) async -> (Double, Int)? {
        do {
            guard let endDate = Calendar.current.date(byAdding: .month, value: -numPastMonths, to: .now),
                  let startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate)
            else {
                return nil
            }

            return try await healthStore.fetchQuantity(
                for: .bodyFatPercentage,
                start: startDate,
                end: endDate,
                option: .discreteAverage,
                unit: .percent()
            )
        } catch {
            print(error)
        }
        return nil
    }

    func fetchMonthlyMobilitySummary() async -> MobilityMonthlySummary? {
        do {
            let endDate = Date.now

            guard let midDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate),
                  let startDate = Calendar.current.date(byAdding: .month, value: -1, to: midDate)
            else {
                return nil
            }

            let doubleSupportTime = try await healthStore.fetchQuantity(
                for: .walkingDoubleSupportPercentage,
                start: midDate,
                end: endDate,
                option: .discreteAverage,
                unit: .percent()
            )

            let sixMinuteWalkDistance = try await healthStore.fetchQuantity(
                for: .sixMinuteWalkTestDistance,
                start: midDate,
                end: endDate,
                option: .discreteAverage,
                unit: .meter()
            )

            let walkingSteadiness = try await healthStore.fetchSamples(
                for: HKCategoryType(.appleWalkingSteadinessEvent),
                start: midDate,
                end: endDate
            ).compactMap { sample in
                (sample as? HKCategorySample)?.walkingSteadinessCategory
            }

            let lastMonthDoubleSupportTime = try await healthStore.fetchQuantity(
                for: .walkingDoubleSupportPercentage,
                start: startDate,
                end: midDate,
                option: .discreteAverage,
                unit: .percent()
            )

            let lastMonthSixMinuteWalkDistance = try await healthStore.fetchQuantity(
                for: .sixMinuteWalkTestDistance,
                start: startDate,
                end: midDate,
                option: .discreteAverage,
                unit: .meter()
            )

            let lastMonthWalkingSteadiness = try await healthStore.fetchSamples(
                for: HKCategoryType(.appleWalkingSteadinessEvent),
                start: startDate,
                end: midDate
            ).compactMap { sample in
                (sample as? HKCategorySample)?.walkingSteadinessCategory
            }

            return MobilityMonthlySummary(
                doubleSupportTimePercent: doubleSupportTime.0,
                sixMinuteWalkDistance: sixMinuteWalkDistance.0,
                walkingSteadiness: walkingSteadiness,
                lastMonthDoubleSupportTimePercent: lastMonthDoubleSupportTime.0,
                lastMonthSixMinuteWalkDistance: lastMonthSixMinuteWalkDistance.0,
                lastMonthWalkingSteadiness: lastMonthWalkingSteadiness
            )
        } catch {
            print(error)
        }
        return nil
    }

    func fetchNutritionalDailyQuantities(
        quantityTypeID: HKQuantityTypeIdentifier,
        unit: HKUnit,
        numPrevDays: Int
    ) async -> [DateQuantitySampleLegacy] {
        let endDate = Date.now

        guard let startDate = Calendar.current.date(byAdding: .day, value: -numPrevDays, to: endDate) else { return [] }

        return (try? await healthStore.fetchCollectionQuantity(
            quantityTypeID: quantityTypeID,
            unit: unit,
            startDate: startDate,
            endDate: endDate
        )) ?? []
    }

    @available(*, deprecated, message: "Update to use a DateRange method instead.")
    func fetchNutritionDailyAverageThisWeek(quantityTypeID: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
        do {
            let endDate = Date.now
            guard let startDate = Calendar.current.startOfWeek(for: endDate) else { return 0 }

            return try await healthStore.fetchNutritionalDailyAverage(
                for: quantityTypeID,
                startDate: startDate,
                endDate: endDate,
                unit: unit
            ).doubleValue(for: unit)
        } catch {
            print(error)
        }
        return 0
    }

    func fetchNutritionMonthlySummary() async -> NutritionMonthlySummary? {
        let endDate = Date.now

        guard let midDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate),
              let startDate = Calendar.current.date(byAdding: .month, value: -1, to: midDate)
        else {
            return nil
        }

        let thisMonth = await fetchNutritionMonthlySummaryDetails(startDate: midDate, endDate: endDate)
        let lastMonth = await fetchNutritionMonthlySummaryDetails(startDate: startDate, endDate: midDate)

        return NutritionMonthlySummary(
            details: thisMonth,
            lastMonthDetails: lastMonth
        )
    }

    func fetchNutritionMonthlySummaryDetails(startDate: Date, endDate: Date) async -> NutritionMonthlySummary.Details {
        let basalEnergyBurned = try? await healthStore.fetchQuantity(
            for: .basalEnergyBurned,
            start: startDate,
            end: endDate,
            option: .cumulativeSum,
            unit: .largeCalorie()
        )

        let activeEnergyBurned = try? await healthStore.fetchQuantity(
            for: .activeEnergyBurned,
            start: startDate,
            end: endDate,
            option: .cumulativeSum,
            unit: .largeCalorie()
        )

        let dietaryEnergy = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryEnergyConsumed,
            startDate: startDate,
            endDate: endDate,
            unit: .largeCalorie()
        )

        let protein = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryProtein,
            startDate: startDate,
            endDate: endDate,
            unit: .gram()
        )

        let carbohydrates = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryCarbohydrates,
            startDate: startDate,
            endDate: endDate,
            unit: .gram()
        )

        let fat = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryFatTotal,
            startDate: startDate,
            endDate: endDate,
            unit: .gram()
        )

        let fiber = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryFiber,
            startDate: startDate,
            endDate: endDate,
            unit: .gram()
        )

        let sugar = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietarySugar,
            startDate: startDate,
            endDate: endDate,
            unit: .gram()
        )

        let caffeine = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryCaffeine,
            startDate: startDate,
            endDate: endDate,
            unit: .gramUnit(with: .milli)
        )

        let vitaminA = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryVitaminA,
            startDate: startDate,
            endDate: endDate,
            unit: .gramUnit(with: .micro)
        )

        let vitaminC = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryVitaminC,
            startDate: startDate,
            endDate: endDate,
            unit: .gramUnit(with: .milli)
        )

        let vitaminD = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryVitaminD,
            startDate: startDate,
            endDate: endDate,
            unit: .gramUnit(with: .micro)
        )

        let vitaminE = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryVitaminE,
            startDate: startDate,
            endDate: endDate,
            unit: .gramUnit(with: .milli)
        )

        let vitaminB6 = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryVitaminB6,
            startDate: startDate,
            endDate: endDate,
            unit: .gramUnit(with: .milli)
        )

        let vitaminB12 = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryVitaminB12,
            startDate: startDate,
            endDate: endDate,
            unit: .gramUnit(with: .micro)
        )

        let calcium = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryCalcium,
            startDate: startDate,
            endDate: endDate,
            unit: .gramUnit(with: .milli)
        )

        let iron = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryIron,
            startDate: startDate,
            endDate: endDate,
            unit: .gramUnit(with: .milli)
        )

        let magnesium = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryMagnesium,
            startDate: startDate,
            endDate: endDate,
            unit: .gramUnit(with: .milli)
        )

        let potassium = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryPotassium,
            startDate: startDate,
            endDate: endDate,
            unit: .gramUnit(with: .milli)
        )

        let sodium = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietarySodium,
            startDate: startDate,
            endDate: endDate,
            unit: .gramUnit(with: .milli)
        )

        let zinc = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryZinc,
            startDate: startDate,
            endDate: endDate,
            unit: .gramUnit(with: .milli)
        )

        let water = try? await healthStore.fetchNutritionalDailyAverage(
            for: .dietaryWater,
            startDate: startDate,
            endDate: endDate,
            unit: .literUnit(with: .milli)
        )

        return .init(
            basalEnergyBurned: basalEnergyBurned.map { HKQuantity(unit: .largeCalorie(), doubleValue: $0.0) },
            activeEnergyBurned: activeEnergyBurned.map { HKQuantity(unit: .largeCalorie(), doubleValue: $0.0) },
            dietaryEnergy: dietaryEnergy,
            averageProtein: protein,
            averageCarbohydrates: carbohydrates,
            averageFat: fat,
            averageFiber: fiber,
            averageSugar: sugar,
            averageCaffeine: caffeine,
            averageVitaminA: vitaminA,
            averageVitaminB6: vitaminB6,
            averageVitaminB12: vitaminB12,
            averageVitaminC: vitaminC,
            averageVitaminD: vitaminD,
            averageVitaminE: vitaminE,
            averageCalcium: calcium,
            averageIron: iron,
            averageMagnesium: magnesium,
            averagePotassium: potassium,
            averageSodium: sodium,
            averageZinc: zinc,
            averageWater: water
        )
    }

    func fetchAverageMeditationMinutes(previousDays: Int = 7) async -> (Double, Int)? {
        do {
            let meditationType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
            let samples = try await healthStore.fetchSamples(for: meditationType, previousDays: previousDays)

            let meditationMinutes = samples.reduce(0) { (total, sample) -> Double in
                total + sample.endDate.timeIntervalSince(sample.startDate) / 60
            }

            return (meditationMinutes / Double(previousDays), previousDays)
        } catch {
            print(error)
        }
        return nil
    }

    @available(*, deprecated, message: "Use DateRange method instead")
    func fetchWeeklyAverageMeditationMinutes(numWeeks: Int) async -> Double {
        do {
            guard
                let endDate = Calendar.current.startOfWeek(for: .now),
                let startDate = Calendar.current.date(byAdding: .day, value: -numWeeks, to: endDate)
            else { return 0 }

            let meditationType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
            let samples = try await healthStore.fetchSamples(
                for: meditationType,
                start: startDate,
                end: endDate
            )

            let meditationMinutes = samples.reduce(0) { (total, sample) -> Double in
                total + sample.timeInterval / 60
            }

            return meditationMinutes / Double(numWeeks)
        } catch {
            print(error)
        }
        return 0
    }

    @available(*, deprecated, message: "Use DateRange method instead")
    func fetchAverageMeditationMinutesThisWeek() async -> Double {
        do {
            let endDate = Date.now
            guard let startDate = Calendar.current.startOfWeek(for: endDate) else { return 0 }

            let meditationType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
            let samples = try await healthStore.fetchSamples(
                for: meditationType,
                start: startDate,
                end: endDate
            )

            let meditationMinutes = samples.reduce(0) { (total, sample) -> Double in
                total + sample.timeInterval / 60
            }

            return meditationMinutes
        } catch {
            print(error)
        }
        return 0
    }

    func fetchMeditationMinutes(periodDays: Int = 14) async -> [DateQuantitySampleLegacy] {
        do {
            let endDate = Date.now
            guard let startDate = Calendar.current.date(byAdding: .day, value: -periodDays, to: endDate) else {
                return []
            }

            let meditationType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!

            let samples = try await healthStore.fetchSamples(for: meditationType, start: startDate, end: endDate)

            var quantitySamples = [DateQuantitySampleLegacy]()

            for sample in samples {
                if
                    let lastSample = quantitySamples.last, 
                    Calendar.current.isDate(lastSample.date, equalTo: sample.endDate, toGranularity: .day) 
                {
                    quantitySamples[quantitySamples.count - 1].quantity += sample.timeInterval / 60
                    continue
                }

                let startOfDay = Calendar.current.startOfDay(for: sample.endDate)
                let newSample = DateQuantitySampleLegacy(
                    date: startOfDay,
                    quantity: sample.timeInterval / 60,
                    unit: "minute"
                )
                quantitySamples.append(newSample)
            }

            return quantitySamples
        } catch {
            print(error)
        }
        return []
    }

    func fetchHeartRateVariability(periodDays: Int = 14) async -> [DateQuantitySampleLegacy] {
        do {
            let samples = try await healthStore.fetchSamples(for: .heartRateVariabilitySDNN, previousDays: periodDays)

            return samples.compactMap { sample in
                sample as? HKQuantitySample
            }.map { sample in
                let value = sample.quantity.doubleValue(for: .secondUnit(with: .milli))
                return DateQuantitySampleLegacy(
                    date: sample.startDate,
                    quantity: value,
                    unit: "milliseconds"
                )
            }
        } catch {
            print(error)
        }
        return []
    }

    func fetchDailyAverageHeartRateVariability(periodDays: Int = 7) async -> [DateAverageQuantitySample] {
        let endDate = Date.now
        guard let startDate = Calendar.current.date(byAdding: .day, value: -periodDays, to: endDate) else {
            return []
        }

        return (try? await healthStore.fetchAverageStatistics(
            quantityTypeID: .heartRateVariabilitySDNN,
            unit: .secondUnit(with: .milli),
            interval: .init(day: 1),
            startDate: startDate,
            endDate: endDate
        )) ?? []
    }
}

// MARK: - Sleep

extension HealthManager {

    func observeSleepData() {
        sleepBackgroundDeliveryHandle = healthStore.enableBackgroundDelivery(
            objectType: HKCategoryType(.sleepAnalysis),
            frequency: .immediate
        )

        sleepObserverQueryHandle = healthStore.observeChanges(
            sampleType: HKCategoryType(.sleepAnalysis),
            startDate: Calendar.current.date(byAdding: .month, value: -2, to: .now) ?? .now
        ) { [weak self, healthStore] in
            let thisMonthSamples = try await healthStore.fetchSamples(
                for: HKCategoryType(.sleepAnalysis),
                dateRange: .trailingMonthsFromNowSleepStartDate(1)
            )
            let lastMonthSamples = try await healthStore.fetchSamples(
                for: HKCategoryType(.sleepAnalysis),
                dateRange: .trailingMonthsFromMonthsFromNowSleepStartDate(monthsFromNow: 1, numberOfMonths: 1)
            )

            let lastPreviousSleepAnalysis = self?.sleepAnalysis30Days?.last

            let thisMonthSleepAnalysis = await self?.processSleepAnalysis(samples: thisMonthSamples) ?? []
            let lastMonthSleepAnalysis = await self?.processSleepAnalysis(samples: lastMonthSamples) ?? []

            let newPreviousSleepAnalysis = thisMonthSleepAnalysis.last

            if (newPreviousSleepAnalysis?.endDate ?? .distantPast) > (lastPreviousSleepAnalysis?.endDate ?? .distantPast) && lastPreviousSleepAnalysis != nil {
                // We've triggered from new data, not from app launch
                await ReportCoordinator.shared.didDetectWakeUp(sleepAnalysis: newPreviousSleepAnalysis)
            }

            await MainActor.run { [weak self] in
                self?.sleepAnalysis7Days = thisMonthSleepAnalysis.suffix(7)
                self?.sleepAnalysis30Days = thisMonthSleepAnalysis
                self?.sleepAnalysisPrevious30Days = lastMonthSleepAnalysis
            }
        }
    }

    func fetchSleepAnalysis(startDate: Date, endDate: Date) async -> [SleepAnalysis] {
        do {
            let samples = try await fetchSleepSamples(startDate: startDate, endDate: endDate)
            return await processSleepAnalysis(samples: samples)
        } catch {
            print(error)
        }
        return []
    }

    func fetchSleepSamples(startDate: Date, endDate: Date) async throws -> [HKSample] {
        try await healthStore.fetchSamples(
            for: HKCategoryType(.sleepAnalysis),
            start: startDate,
            end: endDate
        )
    }

    func processSleepAnalysis(samples: [HKSample]) async -> [SleepAnalysis] {
        let samples = samples as? [HKCategorySample] ?? []

        var groupedSamples = [[HKCategorySample]]()
        var currentGroup: [HKCategorySample] = []

        for sample in samples {
            if let lastSample = currentGroup.last {
                let interval = sample.startDate.timeIntervalSince(lastSample.endDate)
                if interval <= .maxSleepGroupTimeDistance {
                    currentGroup.append(sample)
                } else {
                    groupedSamples.append(currentGroup)
                    currentGroup = [sample]
                }
            } else {
                currentGroup.append(sample)
            }
        }
        if !currentGroup.isEmpty {
            groupedSamples.append(currentGroup)
        }

        var sleepAnalysis = [SleepAnalysis]()
        for sampleGroup in groupedSamples {
            var deepSleepTime: Double = 0
            var coreSleepTime: Double = 0
            var remSleepTime: Double = 0
            var awakeSleepTime: Double = 0

            for sample in sampleGroup {
                switch sample.sleepCategory {
                case .asleepUnspecified, .asleep:
                    break
                case .awake:
                    awakeSleepTime += sample.timeInterval
                case .asleepCore:
                    coreSleepTime += sample.timeInterval
                case .asleepDeep:
                    deepSleepTime += sample.timeInterval
                case .asleepREM:
                    remSleepTime += sample.timeInterval
                case .inBed, .none:
                    break
                @unknown default:
                    break
                }
            }

            let startDate = sampleGroup.reduce(Date.distantFuture) { partialResult, sample in
                switch sample.sleepCategory {
                case .awake, .inBed, .none:
                    return partialResult // We don't want to count these as the start and end of sleep.
                default:
                    break
                }

                if sample.startDate < partialResult {
                    return sample.startDate
                }
                return partialResult
            }

            let endDate = sampleGroup.reduce(Date.distantPast) { partialResult, sample in
                switch sample.sleepCategory {
                case .awake, .inBed, .none:
                    return partialResult // We don't want to count these as the start and end of sleep.
                default:
                    break
                }

                if sample.endDate > partialResult {
                    return sample.endDate
                }
                return partialResult
            }

            guard startDate < endDate else { continue }

            let timePeriod: Int = 10 // minutes

            // Sound levels
            var soundLevelDataPoints = [SleepAnalysis.SoundLevelDataPoint]()
            do {
                let samples = try await healthStore.fetchAverageStatistics(
                    quantityTypeID: .environmentalAudioExposure,
                    unit: .decibelAWeightedSoundPressureLevel(),
                    interval: DateComponents(minute: timePeriod),
                    startDate: startDate,
                    endDate: endDate
                )

                for sample in samples {
                    let dataPoint = SleepAnalysis.SoundLevelDataPoint(
                        decibelAWeightedSoundPressureLevelAverage: sample.averageQuantity,
                        startDate: sample.date,
                        timeRangeSeconds: TimeInterval(timePeriod * 60)
                    )
                    soundLevelDataPoints.append(dataPoint)
                }
            } catch {
                print(error)
            }

            // Heart rate
            var heartRateDataPoints = [SleepAnalysis.HeartRateDataPoint]()
            do {
                let samples = try await healthStore.fetchAverageStatistics(
                    quantityTypeID: .heartRate,
                    unit: .bpm(),
                    interval: DateComponents(minute: timePeriod),
                    startDate: startDate,
                    endDate: endDate
                )

                for sample in samples {
                    let dataPoint = SleepAnalysis.HeartRateDataPoint(
                        averageHeartRate: sample.averageQuantity,
                        startDate: sample.date,
                        timeRangeSeconds: TimeInterval(timePeriod * 60)
                    )
                    heartRateDataPoints.append(dataPoint)
                }
            } catch {
                print(error)
            }

            // Respiratory Rate
            var respiratoryRateDataPoints = [SleepAnalysis.RespiratoryRateDataPoint]()
            do {
                let samples = try await healthStore.fetchAverageStatistics(
                    quantityTypeID: .respiratoryRate,
                    unit: .breathsPerMinute(),
                    interval: .init(minute: timePeriod),
                    startDate: startDate,
                    endDate: endDate
                )

                for sample in samples {
                    let dataPoint = SleepAnalysis.RespiratoryRateDataPoint(
                        averageRespiratoryRate: sample.averageQuantity,
                        startDate: sample.date,
                        timeRangeSeconds: TimeInterval(timePeriod * 60)
                    )
                    respiratoryRateDataPoints.append(dataPoint)
                }
            } catch {
                print(error)
            }

            // Wrist Temperature
            var wristTemperatureDataPoints = [SleepAnalysis.WristTemperatureDataPoint]()
            do {
                let samples = try await healthStore.fetchAverageStatistics(
                    quantityTypeID: .appleSleepingWristTemperature,
                    unit: .degreeFahrenheit(),
                    interval: .init(minute: timePeriod),
                    startDate: startDate,
                    endDate: endDate
                )

                for sample in samples {
                    let dataPoint = SleepAnalysis.WristTemperatureDataPoint(
                        averageWristTemperature: sample.averageQuantity,
                        startDate: sample.date,
                        timeRangeSeconds: TimeInterval(timePeriod * 60)
                    )
                    wristTemperatureDataPoints.append(dataPoint)
                }
            } catch {
                print(error)
            }

            let averageRestingHeartRate = await fetchAverageRestingHeartRate(endDate: startDate)

            let analysis = SleepAnalysis(
                startDate: startDate,
                endDate: endDate,
                deepSleepMinutes: deepSleepTime / 60,
                coreSleepMinutes: coreSleepTime / 60,
                remSleepMinutes: remSleepTime / 60,
                awakeSleepMinutes: awakeSleepTime / 60,
                averageRestingHeartRate: averageRestingHeartRate,
                environmentalSoundLevels: soundLevelDataPoints,
                heartRate: heartRateDataPoints,
                respiratoryRate: respiratoryRateDataPoints,
                wristTemperature: wristTemperatureDataPoints
            )
            sleepAnalysis.append(analysis)
        }

        return sleepAnalysis
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
}

// MARK: Nutitional Intake

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
