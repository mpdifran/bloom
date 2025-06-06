import Foundation
import SwiftData

extension SchemaV19 {
  @Model
  public final class UserFact: Hashable, Identifiable {
    public var id = UUID().uuidString
    public var createdDate: Date = Date()
    public var modifiedDate: Date = Date()
    
    public var fact: String = ""
    public var dateAdded: Date = Date()
    public var revisitDate: Date = Date()
    
    public init(
      id: String = UUID().uuidString,
      fact: String = "",
      dateAdded: Date = Date(),
      revisitDate: Date = Date()
    ) {
      self.id = id
      self.fact = fact
      self.dateAdded = dateAdded
      self.revisitDate = revisitDate
    }
  }
}