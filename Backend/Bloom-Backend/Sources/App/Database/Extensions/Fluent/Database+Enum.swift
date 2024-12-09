//
//  Database+Enum.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-12-09.
//

import Foundation
import Vapor
import Fluent

extension Database {
  func `enum`<T: FluentEnum>(_ enumType: T.Type) -> TypedEnumBuilder<T> {
    .init(database: self, enumType: enumType)
  }
}

protocol FluentEnum {
  static var schema: String { get }
  var rawValue: String { get }
}

final class TypedEnumBuilder<T: FluentEnum>: Sendable {

  let database: any Database
  let enumBuilder: EnumBuilder

  convenience init(database: any Database, enumType: T.Type) {
    self.init(database: database, enumBuilder: database.enum(enumType.schema))
  }

  private init(database: any Database, enumBuilder: EnumBuilder) {
    self.database = database
    self.enumBuilder = enumBuilder
  }

  func `case`(_ value: T) -> Self {
    .init(
      database: database,
      enumBuilder: enumBuilder.case(value.rawValue)
    )
  }

  func deleteCase(_ value: T) -> Self {
    .init(
      database: database,
      enumBuilder: enumBuilder.deleteCase(value.rawValue)
    )
  }

  func create() async throws -> DatabaseSchema.DataType {
    try await enumBuilder.create().get()
  }

  func read() async throws -> DatabaseSchema.DataType {
    try await enumBuilder.read().get()
  }

  func update() async throws -> DatabaseSchema.DataType {
    try await enumBuilder.update().get()
  }

  func delete() async throws {
    try await enumBuilder.delete().get()
  }
}
