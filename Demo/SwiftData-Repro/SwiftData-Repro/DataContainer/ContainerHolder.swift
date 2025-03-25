//
//  ContainerHolder.swift
//  SwiftData-Repro
//
//  Created by Zach Radford on 2025-03-24.
//

import Foundation
import SwiftData

final class ContainerHolder: Sendable {
  static let shared = ContainerHolder()

  public let container: ModelContainer

  private init() {
    let schema = Schema(versionedSchema: currentSchema)
    let modelConfiguration = ModelConfiguration(
      schema: schema
    )

    do {
      self.container = try ModelContainer(
        for: schema,
        migrationPlan: DefaultMigrationPlan.self,
        configurations: modelConfiguration
      )
    } catch {
      fatalError("Could not set up model container: \(modelConfiguration.url.absoluteString)\n\nError: \(error.localizedDescription)")
    }
  }
}
