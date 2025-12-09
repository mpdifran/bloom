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
          return "Steps, workouts, training load, and exercise data. Used to provide personalized activity insights and answer your activity-related questions."
      case .bodyMetrics:
          return "Body composition, weight, resting heart rate, vO2 Max, and HRV. Used to help Bud understand changes in your physiology and answer related questions."
      case .mentalWellness:
          return "Stress levels and mindfulness activity. Used to help Bud answer questions about stress patterns and provide personalized insights."
      case .sleep:
          return "Sleep duration, quality, and stages. Used to help Bud answer questions about your sleep patterns and provide personalized insights."
      case .nutrition:
          return "Meals, calories, macros, and water intake. Used to help Bud answer questions about your nutrition and provide personalized insights."
      case .digestiveHealth:
          return "Bowel movements and patterns. Used to help Bud answer questions about digestive health and provide personalized insights."
      case .menstrualHealth:
          return "Cycle tracking and related data. Used to help Bud answer questions about menstrual health and provide personalized insights."
      case .demographics:
          return "Age, biological sex, height, and your focus. Used to help Bud personalize responses and tailor insights to you."
      case .goals:
          return "Your health goals and progress. Used to help Bud contextualize your questions and generate personalized suggestions."
      case .location:
          return "Your coarse location (city, state, country). Used to help Bud understand environmental context and provide location-aware insights, without knowing your exact position."
      case .weather:
          return "Weather conditions for your location, but not your location itself. Used to help Bud understand external factors that may affect your health."
      case .calendarEvents:
          return "Events from your selected calendars. Used to help Bud understand your schedule context and answer related questions."
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
