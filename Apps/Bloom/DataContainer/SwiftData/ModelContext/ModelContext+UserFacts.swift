//
//  ModelContext+UserFacts.swift
//  Bloom
//
//  Created by Assistant on 2025-06-06.
//

import SwiftData

public extension ModelContext {
  
  func fetchAllUserFacts() throws -> [UserFact] {
    let descriptor = FetchDescriptor<UserFact>(
      sortBy: [SortDescriptor(\UserFact.dateAdded, order: .reverse)]
    )
    return try fetch(descriptor)
  }
  
  func fetchUserFact(withID id: String) throws -> UserFact? {
    let descriptor = FetchDescriptor<UserFact>(
      predicate: #Predicate<UserFact> { userFact in
        userFact.id == id
      }
    )
    return try fetch(descriptor).first
  }
  
  func fetchUserFactsToRevisit(beforeDate date: Date = Date()) throws -> [UserFact] {
    let descriptor = FetchDescriptor<UserFact>(
      predicate: #Predicate<UserFact> { userFact in
        userFact.revisitDate <= date
      },
      sortBy: [SortDescriptor(\UserFact.revisitDate, order: .forward)]
    )
    return try fetch(descriptor)
  }
  
  func deleteUserFact(_ userFact: UserFact) {
    delete(userFact)
  }
}