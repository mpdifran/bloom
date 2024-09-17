//
//  BowelMovement+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-17.
//

import SwiftUI
import DataContainer

extension BowelMovement {

    public var bristolStoolTypeColor: Color {
        switch bristolStoolType {
        case 7: .vitalSevere
        case 1, 6: .vitalWarning
        case 2, 5: .vitalGood
        case 3, 4: .vitalGreat
        default: .clear
        }
    }
}
