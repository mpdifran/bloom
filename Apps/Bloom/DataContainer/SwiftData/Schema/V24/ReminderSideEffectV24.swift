import Foundation
import SwiftData

extension SchemaV24 {
  @Model
  public final class ReminderSideEffect: Hashable, Identifiable {
    public var id = UUID().uuidString
    
    public var typeRawValue: String = ""
    public var configuration: Data = Data()

    public var reminder: Reminder?
    
    // For food logging side effects - just store the ID
    public var foodItemID: String?
    
    public init(
      id: String = UUID().uuidString,
      type: SideEffectType,
      configuration: Data,
      reminder: Reminder? = nil
    ) {
      self.id = id
      self.typeRawValue = type.rawValue
      self.configuration = configuration
      self.reminder = reminder
    }
  }
}

extension SchemaV24.ReminderSideEffect {
  public var type: SideEffectType {
    get {
      SideEffectType(rawValue: typeRawValue) ?? .logFood
    }
    set {
      typeRawValue = newValue.rawValue
    }
  }
}
