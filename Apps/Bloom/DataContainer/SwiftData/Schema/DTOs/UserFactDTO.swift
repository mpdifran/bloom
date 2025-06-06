import Foundation
import SwiftData

public struct UserFactDTO: Sendable, Equatable, Identifiable {
  public let persistentModelID: PersistentIdentifier?
  public let id: String
  public let createdDate: Date
  public let modifiedDate: Date
  public let fact: String
  public let dateAdded: Date
  public let revisitDate: Date
  
  public init(
    persistentModelID: PersistentIdentifier? = nil,
    id: String,
    createdDate: Date,
    modifiedDate: Date,
    fact: String,
    dateAdded: Date,
    revisitDate: Date
  ) {
    self.persistentModelID = persistentModelID
    self.id = id
    self.createdDate = createdDate
    self.modifiedDate = modifiedDate
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
      createdDate: createdDate,
      modifiedDate: modifiedDate,
      fact: fact,
      dateAdded: dateAdded,
      revisitDate: revisitDate
    )
  }
}