import Foundation
import SwiftData

public struct UserFactDTO: Sendable, Equatable, Identifiable {
  public let persistentModelID: PersistentIdentifier?
  public let id: String
  public let fact: String
  public let dateAdded: Date
  public let revisitDate: Date
  
  public init(
    persistentModelID: PersistentIdentifier? = nil,
    id: String,
    fact: String,
    dateAdded: Date,
    revisitDate: Date
  ) {
    self.persistentModelID = persistentModelID
    self.id = id
    self.fact = fact
    self.dateAdded = dateAdded
    self.revisitDate = revisitDate
  }
}

extension SchemaV19.UserFact {
  public func asDTO() -> UserFactDTO {
    UserFactDTO(
      persistentModelID: persistentModelID,
      id: id,
      fact: fact,
      dateAdded: dateAdded,
      revisitDate: revisitDate
    )
  }
}