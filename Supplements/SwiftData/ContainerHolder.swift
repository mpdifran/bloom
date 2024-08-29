//
//  ContainerHolder.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-29.
//

import Foundation
import SwiftData

final class ContainerHolder {
    static let shared = ContainerHolder()

    let container: ModelContainer

    private init() {
        let schema = Schema(
            [
                BowelMovement.self
            ]
        )

        do {
            self.container = try ModelContainer(for: schema, configurations: .init())
        } catch {
            fatalError("Could not set up model container: \(error)")
        }
    }
}
