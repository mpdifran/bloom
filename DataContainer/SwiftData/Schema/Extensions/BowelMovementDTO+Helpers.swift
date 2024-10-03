//
//  BowelMovementDTO+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-03.
//

import Foundation
import HealthKit

public extension BowelMovementDTO {

    var isValidBristolStoolType: Bool {
        bristolStoolType >= 1 && bristolStoolType <= 7
    }
}
