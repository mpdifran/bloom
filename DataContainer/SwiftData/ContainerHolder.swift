//
//  ContainerHolder.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-29.
//

import Foundation
import SwiftData
import TelemetryDeck

public class ContainerHolder {
    public static let shared = ContainerHolder()

    public let container: ModelContainer

    private init() {
        let schema = Schema(versionedSchema: SchemaV1.self)
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
}
