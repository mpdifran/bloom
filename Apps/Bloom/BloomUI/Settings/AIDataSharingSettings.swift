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
    if count == 0 {
      return "No data selected"
    } else if count == 1 {
      return "1 category selected"
    } else {
      return "\(count) categories selected"
    }
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
