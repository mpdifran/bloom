//
//  SupplementViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import Foundation

final class SupplementViewModel: ObservableObject {
    static let shared = SupplementViewModel()

    @Published private(set) var supplements = [String]()
    @Published private(set) var selectedSupplements = [String]() {
        didSet {
            UserDefaults.standard.setValue(selectedSupplements, forKey: "selectedSupplements")
        }
    }

    private init() {
        if let existingSupplements = UserDefaults.standard.value(forKey: "selectedSupplements") as? [String] {
            self.selectedSupplements = existingSupplements
        }
    }
}

extension SupplementViewModel {

    func loadSupplements() async throws {
        let supplements = try await NetworkRequester.shared.fetchSupplements()

        await MainActor.run {
            self.supplements = supplements
        }
    }

    func isSupplementSelected(_ supplement: String) -> Bool {
        selectedSupplements.contains(supplement)
    }

    func toggleSelect(supplement: String) {
        if isSupplementSelected(supplement) {
            selectedSupplements.removeAll(where: { $0 == supplement })
        } else {
            selectedSupplements.append(supplement)
        }
    }
}
