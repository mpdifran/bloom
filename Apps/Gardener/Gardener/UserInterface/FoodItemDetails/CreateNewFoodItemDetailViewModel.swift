//
//  CreateNewFoodItemDetailViewModel.swift
//  Gardener
//
//  Created by Haocen Jiang on 2025-01-23.
//

import AdminBloomModel
import BloomModel
import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class CreateNewFoodItemDetailViewModel: FoodItemDetailViewModel {
  init() {
    super.init(
      foodItem: AdminFoodItemRecord(id: FoodItemIdentifier(UUID().uuidString)),
      foodStore: UnverifiedFoodStore.shared
    )
  }
  
  override func save() async {
    // TODO
  }
  
  override func delete() async {
    // TODO
  }
}
