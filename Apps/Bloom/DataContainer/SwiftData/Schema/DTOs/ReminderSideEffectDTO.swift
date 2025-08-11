import Foundation
import SwiftData

public struct ReminderSideEffectDTO: Sendable, Equatable, Identifiable {
  public let persistentModelID: PersistentIdentifier?
  public let id: String
  public let typeRawValue: String
  public let configuration: Data
  public let foodItemID: String?
  
  public init(
    persistentModelID: PersistentIdentifier? = nil,
    id: String,
    typeRawValue: String,
    configuration: Data,
    foodItemID: String? = nil
  ) {
    self.persistentModelID = persistentModelID
    self.id = id
    self.typeRawValue = typeRawValue
    self.configuration = configuration
    self.foodItemID = foodItemID
  }
}

extension ReminderSideEffect {
  public func asDTO() -> ReminderSideEffectDTO {
    ReminderSideEffectDTO(
      persistentModelID: persistentModelID,
      id: id,
      typeRawValue: typeRawValue,
      configuration: configuration,
      foodItemID: foodItemID
    )
  }
}

extension ReminderSideEffectDTO {
  public var type: SideEffectType? {
    SideEffectType(rawValue: typeRawValue)
  }
  
  public func decodeConfiguration<T: SideEffectConfiguration>(as type: T.Type) -> T? {
    try? JSONDecoder.dataContainer.decode(type, from: configuration)
  }
}
