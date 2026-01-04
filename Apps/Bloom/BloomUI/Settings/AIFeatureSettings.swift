import Foundation
import Combine

/// Settings controlling which AI-powered features are enabled
@MainActor
public final class AIFeatureSettings: ObservableObject {
  public static let shared = AIFeatureSettings()

  /// Whether Today Insights feature is enabled
  @Published public var todayInsightsEnabled: Bool {
    didSet {
      UserDefaults.standard.set(todayInsightsEnabled, forKey: Keys.todayInsights)
    }
  }

  /// Whether AI Chat (Bud) is enabled
  @Published public var chatEnabled: Bool {
    didSet {
      UserDefaults.standard.set(chatEnabled, forKey: Keys.chat)
    }
  }

  private init() {
    // Load from UserDefaults (all default to false - opt-in model)
    todayInsightsEnabled = UserDefaults.standard.bool(forKey: Keys.todayInsights)
    chatEnabled = UserDefaults.standard.bool(forKey: Keys.chat)
  }

  private enum Keys {
    static let todayInsights = "AIFeatures.todayInsightsEnabled"
    static let chat = "AIFeatures.chatEnabled"
  }
}
