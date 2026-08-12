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
  case lifestyle

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
      return String(localized: "Physical Activity", bundle: Bundle.bloomUI)
    case .bodyMetrics:
      return String(localized: "Body Metrics", bundle: Bundle.bloomUI)
    case .mentalWellness:
      return String(localized: "Stress and Mindfulness", bundle: Bundle.bloomUI)
    case .sleep:
      return String(localized: "Sleep", bundle: Bundle.bloomUI)
    case .nutrition:
      return String(localized: "Nutrition", bundle: Bundle.bloomUI)
    case .digestiveHealth:
      return String(localized: "Digestive Health", bundle: Bundle.bloomUI)
    case .menstrualHealth:
      return String(localized: "Menstrual Health", bundle: Bundle.bloomUI)
    case .lifestyle:
      return String(localized: "Lifestyle", bundle: Bundle.bloomUI)
    case .demographics:
      return String(localized: "Demographics", bundle: Bundle.bloomUI)
    case .goals:
      return String(localized: "Goals", bundle: Bundle.bloomUI)
    case .location:
      return String(localized: "Location", bundle: Bundle.bloomUI)
    case .weather:
      return String(localized: "Weather", bundle: Bundle.bloomUI)
    case .calendarEvents:
      return String(localized: "Calendar Events", bundle: Bundle.bloomUI)
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
    case .lifestyle:
      return .leafFill
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
    case .lifestyle:
        .mutedTeal
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
          return String(localized: "Steps, workouts, training load, and exercise data. Used to provide personalized activity insights and answer your activity-related questions.", bundle: Bundle.bloomUI)
      case .bodyMetrics:
          return String(localized: "Body composition, weight, resting heart rate, vO2 Max, and HRV. Used to help Bud understand changes in your physiology and answer related questions.", bundle: Bundle.bloomUI)
      case .mentalWellness:
          return String(localized: "Stress levels and mindfulness activity. Used to help Bud answer questions about stress patterns and provide personalized insights.", bundle: Bundle.bloomUI)
      case .sleep:
          return String(localized: "Sleep duration, quality, and stages. Used to help Bud answer questions about your sleep patterns and provide personalized insights.", bundle: Bundle.bloomUI)
      case .nutrition:
          return String(localized: "Meals, calories, macros, and water intake. Used to help Bud answer questions about your nutrition and provide personalized insights.", bundle: Bundle.bloomUI)
      case .digestiveHealth:
          return String(localized: "Bowel movements and patterns. Used to help Bud answer questions about digestive health and provide personalized insights.", bundle: Bundle.bloomUI)
      case .menstrualHealth:
          return String(localized: "Cycle tracking and related data. Used to help Bud answer questions about menstrual health and provide personalized insights.", bundle: Bundle.bloomUI)
      case .lifestyle:
          return String(localized: "Alcohol consumption and smoking status. Used to help Bud understand lifestyle factors that may affect your health.", bundle: Bundle.bloomUI)
      case .demographics:
          return String(localized: "Age, biological sex, height, and your focus. Used to help Bud personalize responses and tailor insights to you.", bundle: Bundle.bloomUI)
      case .goals:
          return String(localized: "Your health goals and progress. Used to help Bud contextualize your questions and generate personalized suggestions.", bundle: Bundle.bloomUI)
      case .location:
          return String(localized: "Your coarse location (city, state, country). Used to help Bud understand environmental context and provide location-aware insights, without knowing your exact position.", bundle: Bundle.bloomUI)
      case .weather:
          return String(localized: "Weather conditions for your location, but not your location itself. Used to help Bud understand external factors that may affect your health.", bundle: Bundle.bloomUI)
      case .calendarEvents:
          return String(localized: "Events from your selected calendars. Used to help Bud understand your schedule context and answer related questions.", bundle: Bundle.bloomUI)
      }
  }

  /// Whether this is health data (vs other data like weather/calendar)
  public var isHealthData: Bool {
    switch self {
    case .physicalActivity, .bodyMetrics, .mentalWellness, .sleep,
        .nutrition, .digestiveHealth, .menstrualHealth, .lifestyle:
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
