//
//  ProfileViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-21.
//

import Foundation

final class ProfileViewModel: ObservableObject {
    static let shared = ProfileViewModel()

    @Published var name = "" {
        didSet {
            UserDefaults.standard.setValue(name, forKey: "name")
        }
    }
    @Published var userFacts = [String]() {
        didSet {
            UserDefaults.standard.setValue(userFacts, forKey: "learnedUserFacts")
        }
    }
    @Published var userGoals = [String]() {
        didSet {
            UserDefaults.standard.setValue(userGoals, forKey: "selectedGoals")
        }
    }
    @Published var userSupplements = [String]() {
        didSet {
            UserDefaults.standard.setValue(userSupplements, forKey: "selectedSupplements")
        }
    }

    @Published var allSupplements = [String]()
    @Published var allGoals = [String]()

    private init() {
        if let name = UserDefaults.standard.value(forKey: "name") as? String {
            self.name = name
        }
        if let userFacts = UserDefaults.standard.value(forKey: "learnedUserFacts") as? [String] {
            self.userFacts = userFacts
        }
        if let userGoals = UserDefaults.standard.value(forKey: "selectedGoals") as? [String] {
            self.userGoals = userGoals
        }
        if let userSupplements = UserDefaults.standard.value(forKey: "selectedSupplements") as? [String] {
            self.userSupplements = userSupplements
        }
    }
}

extension ProfileViewModel {

    func loadSupplements() async throws {
        guard allSupplements.isEmpty else { return }

        let supplements = try await NetworkRequester.shared.fetchSupplements()

        let sortedSupplements = supplements.sorted(by: { $0 < $1 })

        await MainActor.run {
            self.allSupplements = sortedSupplements
        }
    }

    func loadGoals() async throws {
        guard allGoals.isEmpty else { return }

        let goals = try await NetworkRequester.shared.fetchGoals()

        await MainActor.run {
            self.allGoals = goals
        }
    }
}
