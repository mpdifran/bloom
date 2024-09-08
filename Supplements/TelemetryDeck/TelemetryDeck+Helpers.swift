//
//  TelemetryDeck+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-07.
//

import Foundation
import TelemetryDeck

extension TelemetryDeck {

    static func viewScreen(_ screenName: String) {
        signal("View Screen", parameters: ["Screen Name" : screenName])
    }
}
