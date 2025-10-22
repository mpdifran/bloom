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
  case magicScan
  case barcodeScan
  case logFood
  case logWater
  case logBowelMovement
  case logPeriod
  case logWeight
  case logBloodPressure

  nonisolated(unsafe) static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Action Type")

  nonisolated(unsafe) static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
    .magicScan: DisplayRepresentation(
      title: "Open Magic Scanner",
      image: DisplayRepresentation.Image(systemName: "camera.viewfinder")
    ),
    .barcodeScan: DisplayRepresentation(
      title: "Open Barcode Scanner",
      image: DisplayRepresentation.Image(systemName: "barcode.viewfinder")
    ),
    .logFood: DisplayRepresentation(
      title: "Open Food Logger",
      image: DisplayRepresentation.Image(systemName: "fork.knife")
    ),
    .logWater: DisplayRepresentation(
      title: "Open Water Logger",
      image: DisplayRepresentation.Image(systemName: "waterbottle")
    ),
    .logBowelMovement: DisplayRepresentation(
      title: "Open Bowel Movement Logger",
      image: DisplayRepresentation.Image(systemName: "toilet")
    ),
    .logPeriod: DisplayRepresentation(
      title: "Open Period Logger",
      image: DisplayRepresentation.Image(systemName: "drop")
    ),
    .logWeight: DisplayRepresentation(
      title: "Open Weight Logger",
      image: DisplayRepresentation.Image(systemName: "scalemass")
    ),
    .logBloodPressure: DisplayRepresentation(
      title: "Open Blood Pressure Logger",
      image: DisplayRepresentation.Image(systemName: "heart")
    )
  ]

  var urlPath: String {
    switch self {
    case .magicScan:
      return "action/magic-scan"
    case .barcodeScan:
      return "action/barcode-scan"
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
    case .magicScan:
      return "Open Magic Scanner"
    case .barcodeScan:
      return "Open Barcode Scanner"
    case .logFood:
      return "Open Food Logger"
    case .logWater:
      return "Open Water Logger"
    case .logBowelMovement:
      return "Open Bowel Movement Logger"
    case .logPeriod:
      return "Open Period Logger"
    case .logWeight:
      return "Open Weight Logger"
    case .logBloodPressure:
      return "Open Blood Pressure Logger"
    }
  }

  var sfSymbol: SFSymbol {
    switch self {
    case .magicScan:
      return .cameraViewfinder
    case .barcodeScan:
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
