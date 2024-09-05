//
//  UserID.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-05.
//

import Foundation

enum UserID {
    static var value: String {
        if let value = UserDefaults.group.string(forKey: "UserID") {
            return value
        }
        let newValue = UUID().uuidString
        UserDefaults.group.set(newValue, forKey: "UserID")
        return newValue
    }
}
