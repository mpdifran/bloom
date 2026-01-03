//
//  BiologicalAgeRecordV30.swift
//  DataContainer
//
//  Created by Mark DiFranco on 2026-01-03.
//

import Foundation
import SwiftData

extension SchemaV30 {

  @Model
  public final class BiologicalAgeRecord: IdentifiableByDate {
    public var date: Date = Date.distantPast
    public var biologicalAge: Double = 0
    public var actualAge: Double = 0

    public init(
      date: Date = .now,
      biologicalAge: Double,
      actualAge: Double
    ) {
      self.date = date
      self.biologicalAge = biologicalAge
      self.actualAge = actualAge
    }
  }
}

public extension BiologicalAgeRecord {

  var ageDelta: Double {
    biologicalAge - actualAge
  }

  var isYounger: Bool {
    biologicalAge < actualAge
  }
}
