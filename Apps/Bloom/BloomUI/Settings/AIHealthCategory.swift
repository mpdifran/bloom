import SwiftUI
import SFSafeSymbols
import BloomFoundation

/// Categories of health data that can be shared with AI features
public enum AIHealthCategory: String, Codable, CaseIterable, Sendable {
  // Health Data
  case physicalActivity
  case bodyMetrics
  case mentalWellness
  case sleep
  case nutrition
  case digestiveHealth
  case menstrualHealth

  // Other Data
  case demographics
  case goals
  case location
  case weather
  case calendarEvents

  /// Human-readable display name for the category
  public var displayName: String {
    switch self {
    case .physicalActivity:
      return "Physical Activity"
    case .bodyMetrics:
      return "Body Metrics"
    case .mentalWellness:
      return "Stress and Mindfulness"
    case .sleep:
      return "Sleep"
    case .nutrition:
      return "Nutrition"
    case .digestiveHealth:
      return "Digestive Health"
    case .menstrualHealth:
      return "Menstrual Health"
    case .demographics:
      return "Demographics"
    case .goals:
      return "Goals"
    case .location:
      return "Location"
    case .weather:
      return "Weather"
    case .calendarEvents:
      return "Calendar Events"
    }
  }

  /// SF Symbol icon name for the category
  public var icon: SFSymbol {
    switch self {
    case .physicalActivity:
      return .figureRun
    case .bodyMetrics:
      return .figure
    case .mentalWellness:
      return .brainHeadProfileFill
    case .sleep:
      return .moonZzzFill
    case .nutrition:
      return .forkKnife
    case .digestiveHealth:
      return .toiletFill
    case .menstrualHealth:
      return .circleDottedAndCircle
    case .demographics:
      return .personCircleFill
    case .goals:
      return .target
    case .location:
      return .locationFill
    case .weather:
      return .cloudSun
    case .calendarEvents:
      return .calendar
    }
  }

  public var color: Color {
    switch self {
    case .physicalActivity:
        .mutedGreen
    case .bodyMetrics:
        .mutedYellow
    case .mentalWellness:
        .mutedPurple
    case .sleep:
        .coreSleep
    case .nutrition:
        .mutedGreen
    case .digestiveHealth:
        .brown
    case .menstrualHealth:
        .mutedPink
    case .demographics:
        .mutedIndigo
    case .goals:
        .mutedOrange
    case .location:
        .mutedBlue
    case .weather:
        .mutedLightBlue
    case .calendarEvents:
        .mutedRed
    }
  }

  /// Description of what data this category includes
  public var description: String {
    switch self {
    case .physicalActivity:
      return "Steps, workouts, training load, and exercise data."
    case .bodyMetrics:
      return "Body composition, weight, resting heart rate, vO2 Max, and HRV."
    case .mentalWellness:
      return "Stress levels and mindfulness activity."
    case .sleep:
      return "Sleep duration, quality, and stages."
    case .nutrition:
      return "Meals, calories, macros, and water intake."
    case .digestiveHealth:
      return "Bowel movements and patterns."
    case .menstrualHealth:
      return "Cycle tracking and related data."
    case .demographics:
      return "Age, biological sex, height, and your focus."
    case .goals:
      return "Your health goals and progress."
    case .location:
      return "Your coarse location (city, state, country)."
    case .weather:
      return "Weather conditions for your location."
    case .calendarEvents:
      return "Events from your selected calendars."
    }
  }

  /// Whether this is health data (vs other data like weather/calendar)
  public var isHealthData: Bool {
    switch self {
    case .physicalActivity, .bodyMetrics, .mentalWellness, .sleep,
        .nutrition, .digestiveHealth, .menstrualHealth:
      return true
    case .demographics, .goals, .location, .weather, .calendarEvents:
      return false
    }
  }

  /// All health data categories
  public static var healthCategories: [AIHealthCategory] {
    allCases.filter { $0.isHealthData }
  }

  /// All non-health data categories
  public static var otherCategories: [AIHealthCategory] {
    allCases.filter { !$0.isHealthData }
  }
}
