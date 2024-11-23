//
//  ContainerHolder.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-29.
//

import Foundation
import SwiftData
internal import TelemetryDeck

public final class ContainerHolder: Sendable {
    public static let shared = ContainerHolder()

    // It's only modified by the tests.
    private(set) public var container: ModelContainer

    private init() {
        let schema = Schema(versionedSchema: SchemaV3.self)
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier("group.supplements")
        )

        do {
            self.container = try ModelContainer(
                for: schema,
                migrationPlan: DefaultMigrationPlan.self,
                configurations: modelConfiguration
            )
        } catch {
            TelemetryDeck.errorOccurred(
                id: "ContainerHolder.containerSetup",
                category: .appState,
                message: error.localizedDescription
            )
            fatalError("Could not set up model container: \(modelConfiguration.url.absoluteString)\n\nError: \(error.localizedDescription)")
        }
    }

    public func createContext() -> ModelContext {
        ModelContext(container)
    }

    public func editAndSave(_ block: (ModelContext) throws -> Void) throws {
        let context = ModelContext(container)
        try block(context)
        try context.save()
    }
}

public extension ContainerHolder {

    func setupForTests() {
        let schema = Schema(versionedSchema: SchemaV2.self)
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        self.container = try! ModelContainer(
            for: schema,
            migrationPlan: DefaultMigrationPlan.self,
            configurations: modelConfiguration
        )
    }
}
