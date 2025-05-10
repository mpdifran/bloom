//
//  Assets+Public.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-01.
//

import SwiftUI

public extension ShapeStyle where Self == Color {
  // Activity Levels
  static var activityLevelHigh: Self { Color("ActivityLevelHigh", bundle: BundleToken.bundle) }
  static var activityLevelIntense: Self   { Color("ActivityLevelIntense", bundle: BundleToken.bundle) }
  static var activityLevelLight: Self     { Color("ActivityLevelLight", bundle: BundleToken.bundle) }
  static var activityLevelModerate: Self  { Color("ActivityLevelModerate", bundle: BundleToken.bundle) }
  static var activityLevelSedentary: Self { Color("ActivityLevelSedentary", bundle: BundleToken.bundle) }

  // Heart Rate Zones
  static var heartRateZone1: Self { Color("HeartRateZone1", bundle: BundleToken.bundle) }
  static var heartRateZone2: Self { Color("HeartRateZone2", bundle: BundleToken.bundle) }
  static var heartRateZone3: Self { Color("HeartRateZone3", bundle: BundleToken.bundle) }
  static var heartRateZone4: Self { Color("HeartRateZone4", bundle: BundleToken.bundle) }
  static var heartRateZone5: Self { Color("HeartRateZone5", bundle: BundleToken.bundle) }

  // Nutrition - Macros
  static var carbohydrates: Self { Color("Carbohydrates", bundle: BundleToken.bundle) }
  static var fat: Self           { Color("Fat", bundle: BundleToken.bundle) }
  static var protein: Self       { Color("Protein", bundle: BundleToken.bundle) }

  // Nutrition - Minerals
  static var calcium: Self   { Color("Calcium", bundle: BundleToken.bundle) }
  static var iron: Self      { Color("Iron", bundle: BundleToken.bundle) }
  static var magnesium: Self { Color("Magnesium", bundle: BundleToken.bundle) }
  static var potassium: Self { Color("Potassium", bundle: BundleToken.bundle) }
  static var sodium: Self    { Color("Sodium", bundle: BundleToken.bundle) }
  static var zinc: Self      { Color("Zinc", bundle: BundleToken.bundle) }

  // Nutrition - Other
  static var caffeine: Self    { Color("Caffeine", bundle: BundleToken.bundle) }
  static var cholesterol: Self { Color("Cholesterol", bundle: BundleToken.bundle) }
  static var fiber: Self       { Color("Fiber", bundle: BundleToken.bundle) }
  static var sugar: Self       { Color("Sugar", bundle: BundleToken.bundle) }

  // Nutrition - Vitamins
  static var vitaminA: Self   { Color("Vitamin A", bundle: BundleToken.bundle) }
  static var vitaminB6: Self  { Color("Vitamin B6", bundle: BundleToken.bundle) }
  static var vitaminB12: Self { Color("Vitamin B12", bundle: BundleToken.bundle) }
  static var vitaminC: Self   { Color("Vitamin C", bundle: BundleToken.bundle) }
  static var vitaminD: Self   { Color("Vitamin D", bundle: BundleToken.bundle) }
  static var vitaminE: Self   { Color("Vitamin E", bundle: BundleToken.bundle) }

  // Sleep
  static var awakeSleep: Self { Color("AwakeSleep", bundle: BundleToken.bundle) }
  static var coreSleep: Self  { Color("CoreSleep", bundle: BundleToken.bundle) }
  static var deepSleep: Self  { Color("DeepSleep", bundle: BundleToken.bundle) }
  static var remSleep: Self   { Color("REMSleep", bundle: BundleToken.bundle) }

  // Vitals Severity
  static var vitalGood: Self    { Color("VitalGood", bundle: BundleToken.bundle) }
  static var vitalGreat: Self   { Color("VitalGreat", bundle: BundleToken.bundle) }
  static var vitalSevere: Self  { Color("VitalSevere", bundle: BundleToken.bundle) }
  static var vitalWarning: Self { Color("VitalWarning", bundle: BundleToken.bundle) }
}
public extension Color {
  // Activity Levels
  static let activityLevelHigh      = Color("ActivityLevelHigh", bundle: BundleToken.bundle)
  static let activityLevelIntense   = Color("ActivityLevelIntense", bundle: BundleToken.bundle)
  static let activityLevelLight     = Color("ActivityLevelLight", bundle: BundleToken.bundle)
  static let activityLevelModerate  = Color("ActivityLevelModerate", bundle: BundleToken.bundle)
  static let activityLevelSedentary = Color("ActivityLevelSedentary", bundle: BundleToken.bundle)

  // Heart Rate Zones
  static let heartRateZone1 = Color("HeartRateZone1", bundle: BundleToken.bundle)
  static let heartRateZone2 = Color("HeartRateZone2", bundle: BundleToken.bundle)
  static let heartRateZone3 = Color("HeartRateZone3", bundle: BundleToken.bundle)
  static let heartRateZone4 = Color("HeartRateZone4", bundle: BundleToken.bundle)
  static let heartRateZone5 = Color("HeartRateZone5", bundle: BundleToken.bundle)

  // Nutrition - Macros
  static let carbohydrates = Color("Carbohydrates", bundle: BundleToken.bundle)
  static let fat           = Color("Fat", bundle: BundleToken.bundle)
  static let protein       = Color("Protein", bundle: BundleToken.bundle)

  // Nutrition - Minerals
  static let calcium   = Color("Calcium", bundle: BundleToken.bundle)
  static let iron      = Color("Iron", bundle: BundleToken.bundle)
  static let magnesium = Color("Magnesium", bundle: BundleToken.bundle)
  static let potassium = Color("Potassium", bundle: BundleToken.bundle)
  static let sodium    = Color("Sodium", bundle: BundleToken.bundle)
  static let zinc      = Color("Zinc", bundle: BundleToken.bundle)

  // Nutrition - Other
  static let caffeine    = Color("Caffeine", bundle: BundleToken.bundle)
  static let cholesterol = Color("Cholesterol", bundle: BundleToken.bundle)
  static let fiber       = Color("Fiber", bundle: BundleToken.bundle)
  static let sugar       = Color("Sugar", bundle: BundleToken.bundle)

  // Nutrition - Vitamins
  static let vitaminA   = Color("Vitamin A", bundle: BundleToken.bundle)
  static let vitaminB6  = Color("Vitamin B6", bundle: BundleToken.bundle)
  static let vitaminB12 = Color("Vitamin B12", bundle: BundleToken.bundle)
  static let vitaminC   = Color("Vitamin C", bundle: BundleToken.bundle)
  static let vitaminD   = Color("Vitamin D", bundle: BundleToken.bundle)
  static let vitaminE   = Color("Vitamin E", bundle: BundleToken.bundle)

  // Sleep
  static let awakeSleep = Color("AwakeSleep", bundle: BundleToken.bundle)
  static let coreSleep  = Color("CoreSleep", bundle: BundleToken.bundle)
  static let deepSleep  = Color("DeepSleep", bundle: BundleToken.bundle)
  static let remSleep   = Color("REMSleep", bundle: BundleToken.bundle)
  
  // Vitals Severity
  static let vitalGood    = Color("VitalGood", bundle: BundleToken.bundle)
  static let vitalGreat   = Color("VitalGreat", bundle: BundleToken.bundle)
  static let vitalSevere  = Color("VitalSevere", bundle: BundleToken.bundle)
  static let vitalWarning = Color("VitalWarning", bundle: BundleToken.bundle)
}

public extension ImageResource {
  // Log Actions
  static let logBloodPressureIcon = ImageResource(name: "LogBloodPressureIcon", bundle: BundleToken.bundle)
  static let logBowelIcon         = ImageResource(name: "LogBowelIcon", bundle: BundleToken.bundle)
  static let logFoodIcon          = ImageResource(name: "LogFoodIcon", bundle: BundleToken.bundle)
  static let logPeriodIcon        = ImageResource(name: "LogPeriodIcon", bundle: BundleToken.bundle)
  static let logWaterIcon         = ImageResource(name: "LogWaterIcon", bundle: BundleToken.bundle)
  static let logWeightIcon        = ImageResource(name: "LogWeightIcon", bundle: BundleToken.bundle)
}

private class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
      return Bundle.module
    #else
      return Bundle(for: BundleToken.self)
    #endif
  }()
}
