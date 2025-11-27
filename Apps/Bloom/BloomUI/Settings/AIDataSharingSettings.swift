import Foundation

/// Settings controlling what health data categories are shared with AI features
public struct AIDataSharingSettings: Codable, Sendable {
    /// Set of enabled data categories. Empty set means no data is shared (privacy-first default).
    public var enabledCategories: Set<AIHealthCategory>

    public init(enabledCategories: Set<AIHealthCategory> = []) {
        self.enabledCategories = enabledCategories
    }

    /// Default settings with all categories disabled
    public static let `default` = AIDataSharingSettings()
}
