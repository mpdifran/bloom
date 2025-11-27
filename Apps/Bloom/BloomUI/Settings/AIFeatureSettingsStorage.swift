import SwiftUI

@propertyWrapper
public struct AIFeatureSettingsStorage: DynamicProperty {
    @AppStorage private var _storedData: Data
    private let defaultValue: AIFeatureSettings

    public init(wrappedValue: AIFeatureSettings = AIFeatureSettings(), _ key: String, store: UserDefaults = .standard) {
        self.defaultValue = wrappedValue

        // Create default encoded data
        let defaultData = (try? JSONEncoder().encode(wrappedValue)) ?? Data()

        // Initialize AppStorage with the key, default value, and store
        self.__storedData = AppStorage(wrappedValue: defaultData, key, store: store)
    }

    public var wrappedValue: AIFeatureSettings {
        get {
            // Try to decode from stored data, fallback to default
            if let decoded = try? JSONDecoder().decode(AIFeatureSettings.self, from: _storedData) {
                return decoded
            }
            return defaultValue
        }
        nonmutating set {
            // Encode and store
            if let encoded = try? JSONEncoder().encode(newValue) {
                _storedData = encoded
            }
        }
    }

    public var projectedValue: Binding<AIFeatureSettings> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
}
