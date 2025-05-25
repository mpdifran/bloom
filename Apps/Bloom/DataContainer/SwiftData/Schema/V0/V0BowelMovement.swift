//
//  BowelMovement.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-26.
//

import SwiftUI
import SwiftData

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV0 {
  @Model
  public final class BowelMovement: IdentifiableByDate {
    public var date: Date = Date.now
    public var bristolStoolType: Int = 0
    public var rawDuration: Int = 1

    public init(
      date: Date = .now,
      bristolStoolType: Int = 0,
      duration: Duration = .between5And10Min
    ) {
      self.date = date
      self.bristolStoolType = bristolStoolType
      self.rawDuration = duration.rawValue
    }

    public enum Duration: Int, CaseIterable, Identifiable, Sendable {
      public var id: Self { self }

      case lessThan5Min = 0
      case between5And10Min = 1
      case moreThan10Min = 2

      public var name: String {
        switch self {
        case .lessThan5Min:
          "< 5 min"
        case .between5And10Min:
          "5 - 10 min"
        case .moreThan10Min:
          "> 10 min"
        }
      }

      public var scoreModifier: Double {
        switch self {
        case .lessThan5Min:
          0.9
        case .between5And10Min:
          1
        case .moreThan10Min:
          0.75
        }
      }
    }
  }
}


