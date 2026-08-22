import Foundation
import Combine

/// Settings controlling what health data categories are shared with AI features
@MainActor
public final class AIDataSharingSettings: ObservableObject {
  public static let shared = AIDataSharingSettings()

  /// Set of enabled data categories. Empty set means no data is shared (privacy-first default).
  @Published public var enabledCategories: Set<AIHealthCategory> {
    didSet {
      saveToUserDefaults()
    }
  }

  private init() {
    // Load from UserDefaults (defaults to empty set - no data shared)
    if let data = UserDefaults.standard.data(forKey: Keys.enabledCategories),
       let decoded = try? JSONDecoder().decode(Set<AIHealthCategory>.self, from: data) {
      enabledCategories = decoded
    } else {
      enabledCategories = []
    }
  }
}

public extension AIDataSharingSettings {

  var enabledCategoriesText: String {
    let count = enabledCategories.count

    guard count > 0 else {
      return String(
        localized: "No data selected",
        bundle: Bundle.bloomUI,
        comment: "Shown when no health data categories are shared with AI features"
      )
    }

    return String(
      localized: "\(count) categories selected",
      bundle: Bundle.bloomUI,
      comment: "Number of health data categories shared with AI features. The placeholder is a count; needs a plural rule."
    )
  }
}

private extension AIDataSharingSettings {

  func saveToUserDefaults() {
    if let encoded = try? JSONEncoder().encode(enabledCategories) {
      UserDefaults.standard.set(encoded, forKey: Keys.enabledCategories)
    }
  }

  enum Keys {
    static let enabledCategories = "AIDataSharing.enabledCategories"
  }
}
