//
//  DirectiveListViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-21.
//

import Foundation
import OpenAPIClient

@MainActor
final class DirectiveListViewModel: ObservableObject {
    static let shared = DirectiveListViewModel()

    @Published var directives = [UserDirective]()

    private init() { 
        SleepProgramCoordinator.shared.$assistantResponse
            .map { assistantResponse in
                assistantResponse?.directives ?? []
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$directives)
    }
}
