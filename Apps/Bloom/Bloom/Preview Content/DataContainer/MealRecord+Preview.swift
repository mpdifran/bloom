//
//  MealRecordDTO+Preview.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-26.
//

import UIKit
@preconcurrency import DataContainer
import BloomModel
import SwiftData

extension MealRecord {
  enum Preview { }
}

extension MealRecord.Preview {
  nonisolated(unsafe) static let crackersAndCheese = MealRecord(
    id: "1234",
    name: "Crackers and Cheese",
    imageData: UIImage(named: "CrackersAndCheese")?.pngData(),
    items: [
      MealItemRecord(
        id: "123",
        numberOfServings: 3,
        foodItem: .Preview.ritzCrackers
      ),
      MealItemRecord(
        id: "456",
        numberOfServings: 2,
        foodItem: .Preview.shreddedCheddar
      )
    ]
  )

  nonisolated(unsafe) static let crackersAndCheeseNoImage = MealRecord(
    id: "1234",
    name: "Crackers and Cheese",
    imageData: nil,
    items: [
      MealItemRecord(
        id: "123",
        numberOfServings: 3,
        foodItem: .Preview.ritzCrackers
      ),
      MealItemRecord(
        id: "456",
        numberOfServings: 2,
        foodItem: .Preview.shreddedCheddar
      )
    ]
  )
}
