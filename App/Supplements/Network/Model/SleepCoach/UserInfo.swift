//
//  UserInfo.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-02.
//

import Foundation

struct UserInfo: Codable {
    let name: String?
    let age: Int?
    let sex: String?
    let location: LocationModel?
}
