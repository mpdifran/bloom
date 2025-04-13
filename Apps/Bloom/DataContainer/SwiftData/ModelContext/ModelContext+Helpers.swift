//
//  ModelContext+Helpers.swift
//  DataContainer
//
//  Created by Mark DiFranco on 2024-09-23.
//

import Foundation
import SwiftData
import BloomFoundation
internal import AppFoundations

public extension ModelContext {

  func savingTransaction(block: () throws -> Void) throws {
    try transaction {
      try block()
      try save()
    }
  }
}

public extension ModelContext {

  func existingModel<T>(for objectID: PersistentIdentifier) throws -> T? where T: PersistentModel {
    if let registered: T = registeredModel(for: objectID) {
      return registered
    }

    let fetchDescriptor = FetchDescriptor<T>(
      predicate: #Predicate {
        $0.persistentModelID == objectID
      })

    return try fetch(fetchDescriptor).first
  }

  func deleteByID<T>(_ model: T) throws where T: PersistentModel {
    guard let localModel: T = try existingModel(for: model.persistentModelID) else { return }

    delete(localModel)
  }

  func deleteAll<T>(_ modelType: T.Type) throws where T: PersistentModel {
    let fetchDescriptor = FetchDescriptor<T>()
    let models = try fetch(fetchDescriptor)
    for model in models {
      delete(model)
    }
  }
}
