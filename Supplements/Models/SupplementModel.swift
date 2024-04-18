//
//  SupplementModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-04-18.
//

import SwiftUI

struct SupplementModel: Identifiable {
    let id = UUID()
    let name: String
    let image: ImageResource
    let whatIsIt: String
    let benefits: String
    let drawbacks: String
    let dosageInformation: String
}
