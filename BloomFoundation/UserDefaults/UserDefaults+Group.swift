//
//  UserDefaults+Group.swift
//  BloomFoundation
//
//  Created by Mark DiFranco on 2024-06-01.
//

import Foundation

public extension UserDefaults {
    static let group: UserDefaults = UserDefaults(suiteName: "group.supplements")!
}
