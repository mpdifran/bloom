//
//  ActionType.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-10-14.
//

import AppIntents
import Foundation
import SFSafeSymbols
import SwiftUI
import CoreHealth
import BloomFoundation

enum ActionType: String, AppEnum {
  case magicScan
  case barcodeScan
  case logFood
  case logWater
  case logBowelMovement
  case logPeriod
  case logWeight
  case logBloodPressure
  case logVoice

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
    ),
    .logVoice: DisplayRepresentation(
      title: "Open Voice Logger",
      image: DisplayRepresentation.Image(systemName: "microphone.fill")
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
    case .logVoice:
      return "action/voice-logger"
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
    case .logVoice:
      return "Open Voice Logger"
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
    case .logVoice:
      return .microphoneFill
    }
  }

  var color: Color {
    switch self {
    case .logFood:
      return .mutedGreen
    case .logWater:
      return .mutedBlue
    case .logPeriod:
      return .mutedPink
    case .logBowelMovement:
      return .brown
    case .logWeight:
      return .mutedIndigo
    case .logBloodPressure:
      return .mutedRed
    case .barcodeScan:
      return .gray
    case .magicScan:
      return .mutedPurple
    case .logVoice:
      return .orange
    }
  }

  var icon: ImageResource {
    switch self {
    case .logFood:
      return .logFoodIcon
    case .logWater:
      return .logWaterIcon
    case .logPeriod:
      return .logPeriodIcon
    case .logBowelMovement:
      return .logBowelIcon
    case .logWeight:
      return .logWeightIcon
    case .logBloodPressure:
      return .logBloodPressureIcon
    case .barcodeScan:
      return .logFoodIcon // Using food icon as placeholder for barcode
    case .magicScan:
      return .logFoodIcon // Using food icon as placeholder for magic scan
    case .logVoice:
      return .logFoodIcon // Using food icon as placeholder for voice logger
    }
  }
}
