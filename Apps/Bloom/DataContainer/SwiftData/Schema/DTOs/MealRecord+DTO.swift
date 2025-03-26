//
//  MealRecord+DTO.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-26.
//

import Foundation
import SwiftData

public struct MealRecordDTO: Sendable, Equatable {
  public let persistentID: PersistentIdentifier
  public let id: String
  public let name: String
  public let imageData: Data?
  public let items: [MealItemRecordDTO]
}

public extension MealRecord {

  func asDTO() -> MealRecordDTO {
    MealRecordDTO(
      persistentID: persistentModelID,
      id: id,
      name: name,
      imageData: imageData,
      items: items?.map({ $0.asDTO() }) ?? []
    )
  }
}
