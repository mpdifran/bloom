//
//  FocusAreaModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-04-18.
//

import SwiftUI

struct FocusAreaModel: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let color: Color
    let information: String
    let primary: [FocusAreaSupplementModel]
    let secondary: [FocusAreaSupplementModel]
    let promising: [FocusAreaSupplementModel]
    let unproven: [FocusAreaSupplementModel]
    let inadvisable: [FocusAreaSupplementModel]
}

struct FocusAreaSupplementModel: Identifiable {
    let id = UUID()
    let supplement: SupplementModel
    let context: String
}
