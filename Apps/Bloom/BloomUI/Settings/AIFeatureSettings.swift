import Foundation

/// Settings controlling which AI-powered features are enabled
public struct AIFeatureSettings: Codable, Sendable {
    /// Whether Today Insights feature is enabled
    public var todayInsightsEnabled: Bool

    /// Whether AI Chat (Bud) is enabled
    public var chatEnabled: Bool

    /// Whether Biological Age calculations are enabled
    public var biologicalAgeEnabled: Bool

    public init(
        todayInsightsEnabled: Bool = false,
        chatEnabled: Bool = false,
        biologicalAgeEnabled: Bool = false
    ) {
        self.todayInsightsEnabled = todayInsightsEnabled
        self.chatEnabled = chatEnabled
        self.biologicalAgeEnabled = biologicalAgeEnabled
    }

    /// Default settings with all features disabled (opt-in model)
    public static let `default` = AIFeatureSettings()
}
