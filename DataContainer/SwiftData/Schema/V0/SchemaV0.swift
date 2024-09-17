//
//  SchemaV0.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-16.
//

import Foundation
import SwiftData

public enum SchemaV0: VersionedSchema {
    public static var versionIdentifier = Schema.Version(0, 0, 0)

    public static var models: [any PersistentModel.Type] = [
        SchemaV0.BowelMovement.self
    ]
}
