//
//  SharedModelActor.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-19.
//

import Foundation
import SwiftData

public protocol SharedModelActor {

    init(modelContainer: ModelContainer)

    static func standard() -> Self
}

extension SharedModelActor {

    public static func standard() -> Self {
        .init(modelContainer: ContainerHolder.shared.container)
    }
}
