//
//  BiologicalAgeRecord+DTO.swift
//  DataContainer
//
//  Created by Mark DiFranco on 2026-01-03.
//

import Foundation
import SwiftData

public struct BiologicalAgeRecordDTO: Sendable, Identifiable {
  public let id: PersistentIdentifier
  public let date: Date
  public let biologicalAge: Double
  public let actualAge: Double

  public var ageDelta: Double {
    biologicalAge - actualAge
  }

  public var isYounger: Bool {
    biologicalAge < actualAge
  }
}

public extension BiologicalAgeRecord {

  func asDTO() -> BiologicalAgeRecordDTO {
    BiologicalAgeRecordDTO(
      id: persistentModelID,
      date: date,
      biologicalAge: biologicalAge,
      actualAge: actualAge
    )
  }
}
