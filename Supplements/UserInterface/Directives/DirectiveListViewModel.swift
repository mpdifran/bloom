//
//  DirectiveListViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-21.
//

import Foundation

@MainActor
final class DirectiveListViewModel: ObservableObject {
    static let shared = DirectiveListViewModel()

    @Published var sleepActivities = [SleepSuggestionModel]()

    private init() { 
        SleepProgramCoordinator.shared.$sleepActivities
            .receive(on: DispatchQueue.main)
            .assign(to: &$sleepActivities)
    }
}
