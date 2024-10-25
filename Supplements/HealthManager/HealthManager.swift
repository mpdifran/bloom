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

struct HealthTargetDetails {
    let targetWeight: Double
    let goal: HealthGoal
    let weightLossSpeed: WeightLossSpeed
}

enum HealthGoal: String {
    case none
    case gainWeight
    case maintainWeight
    case loseWeight
}

extension HealthGoal {
    var isWeightRelated: Bool {
        switch self {
        case .gainWeight, .maintainWeight, .loseWeight:
            true
        default:
            false
        }
    }
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

@MainActor
final class HealthManager: ObservableObject {
    static let shared = HealthManager()

    @AppStorage("HealthManager.name", store: .group) var name: String = ""
    @AppStorage("HealthManager.isFemale", store: .group) var isFemale = false

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
            targetWeight: targetWeight,
            goal: healthGoal,
            weightLossSpeed: weightLossSpeed
        )
    }

    @AppStorage("HealthManager.targetWeight", store: .group) var targetWeight: Double = 0
    @AppStorage("HealthManager.isPregnant", store: .group) var isPregnant = false
    @AppStorage("HealthManager.isBreastfeeding", store: .group) var isBreastfeeding = false

    let healthStore = HKHealthStore()

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
        if let activityLevelRaw = UserDefaults.group.string(forKey: "HealthManager.userReportedActivityLevel") {
            self.userReportedActivityLevel = ActivityLevelSummary.ActivityLevel(rawValue: activityLevelRaw)
        }
    }
}

// MARK: Age and Sex

extension HealthManager {

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
        case .none:
            return false
        }
    }
}
