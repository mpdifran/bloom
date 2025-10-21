//
//  ActionType.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-10-14.
//

import AppIntents
import Foundation
import SFSafeSymbols

enum ActionType: String, AppEnum {
  case scanFood
  case logFood
  case logWater
  case logBowelMovement
  case logPeriod
  case logWeight
  case logBloodPressure

  nonisolated(unsafe) static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Action Type")

  nonisolated(unsafe) static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
    .scanFood: DisplayRepresentation(
      title: "Scan Food",
      image: DisplayRepresentation.Image(systemName: Self.scanFood.sfSymbol.rawValue)
    ),
    .logFood: DisplayRepresentation(
      title: "Log Food",
      image: DisplayRepresentation.Image(systemName: Self.logFood.sfSymbol.rawValue)
    ),
    .logWater: DisplayRepresentation(
      title: "Log Water",
      image: DisplayRepresentation.Image(systemName: Self.logWater.sfSymbol.rawValue)
    ),
    .logBowelMovement: DisplayRepresentation(
      title: "Log Bowel Movement",
      image: DisplayRepresentation.Image(systemName: Self.logBowelMovement.sfSymbol.rawValue)
    ),
    .logPeriod: DisplayRepresentation(
      title: "Log Period",
      image: DisplayRepresentation.Image(systemName: Self.logPeriod.sfSymbol.rawValue)
    ),
    .logWeight: DisplayRepresentation(
      title: "Log Weight",
      image: DisplayRepresentation.Image(systemName: Self.logWeight.sfSymbol.rawValue)
    ),
    .logBloodPressure: DisplayRepresentation(
      title: "Log Blood Pressure",
      image: DisplayRepresentation.Image(systemName: Self.logBloodPressure.sfSymbol.rawValue)
    )
  ]

  var urlPath: String {
    switch self {
    case .scanFood:
      return "action/food-scanner"
    case .logFood:
      return "action/log-food"
    case .logWater:
      return "action/log-water"
    case .logBowelMovement:
      return "action/log-bowel-movement"
    case .logPeriod:
      return "action/log-period"
    case .logWeight:
      return "action/log-weight"
    case .logBloodPressure:
      return "action/log-blood-pressure"
    }
  }

  var label: String {
    switch self {
    case .scanFood:
      return "Scan Food"
    case .logFood:
      return "Log Food"
    case .logWater:
      return "Log Water"
    case .logBowelMovement:
      return "Log Bowel Movement"
    case .logPeriod:
      return "Log Period"
    case .logWeight:
      return "Log Weight"
    case .logBloodPressure:
      return "Log Blood Pressure"
    }
  }

  var sfSymbol: SFSymbol {
    switch self {
    case .scanFood:
      return .barcodeViewfinder
    case .logFood:
      return .forkKnife
    case .logWater:
      return .waterbottle
    case .logBowelMovement:
      return .toilet
    case .logPeriod:
      return .drop
    case .logWeight:
      return .scalemass
    case .logBloodPressure:
      return .heart
    }
  }
}
