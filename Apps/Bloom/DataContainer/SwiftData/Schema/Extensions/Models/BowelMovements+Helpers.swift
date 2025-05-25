//
//  BowelMovements+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-17.
//

import Foundation

public extension BowelMovement {

    var duration: Duration {
        Duration(rawValue: rawDuration) ?? .between5And10Min
    }

    var isValidBristolStoolType: Bool {
        bristolStoolType >= 1 && bristolStoolType <= 7
    }
}
