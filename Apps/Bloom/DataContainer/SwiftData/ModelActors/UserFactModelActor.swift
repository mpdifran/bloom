//
//  UserFactModelActor.swift
//  Bloom
//
//  Created by Assistant on 2025-06-06.
//

import Foundation
import SwiftData

@ModelActor
public final actor UserFactModelActor: SharedModelActor {
  
  private var context: ModelContext { modelExecutor.modelContext }
}

public extension UserFactModelActor {
  
  func fetchAllUserFacts() throws -> [UserFactDTO] {
    let descriptor = FetchDescriptor<UserFact>(
      sortBy: [SortDescriptor(\UserFact.dateAdded, order: .reverse)]
    )
    return try context.fetch(descriptor).map { $0.asDTO() }
  }
  
  func fetchUserFact(withID id: String) throws -> UserFactDTO? {
    let descriptor = FetchDescriptor<UserFact>(
      predicate: #Predicate<UserFact> { userFact in
        userFact.id == id
      }
    )
    let userFacts = try context.fetch(descriptor)
    return userFacts.first?.asDTO()
  }
  
  func fetchUserFactsToRevisit(beforeDate date: Date = Date()) throws -> [UserFactDTO] {
    let descriptor = FetchDescriptor<UserFact>(
      predicate: #Predicate<UserFact> { userFact in
        userFact.revisitDate <= date
      },
      sortBy: [SortDescriptor(\UserFact.revisitDate, order: .forward)]
    )
    return try context.fetch(descriptor).map { $0.asDTO() }
  }
  
  func createUserFact(
    fact: String,
    dateAdded: Date = Date(),
    revisitDate: Date
  ) throws -> UserFactDTO {
    let userFact = UserFact(
      fact: fact,
      dateAdded: dateAdded,
      revisitDate: revisitDate
    )
    context.insert(userFact)
    try context.save()
    return userFact.asDTO()
  }
  
  func updateUserFact(
    withID id: String,
    fact: String? = nil,
    revisitDate: Date? = nil
  ) throws -> UserFactDTO? {
    let descriptor = FetchDescriptor<UserFact>(
      predicate: #Predicate<UserFact> { userFact in
        userFact.id == id
      }
    )
    guard let userFact = try context.fetch(descriptor).first else { return nil }
    
    if let fact = fact {
      userFact.fact = fact
    }
    if let revisitDate = revisitDate {
      userFact.revisitDate = revisitDate
    }
    userFact.modifiedDate = Date()
    
    try context.save()
    return userFact.asDTO()
  }
  
  func deleteUserFact(withID id: String) throws {
    let descriptor = FetchDescriptor<UserFact>(
      predicate: #Predicate<UserFact> { userFact in
        userFact.id == id
      }
    )
    guard let userFact = try context.fetch(descriptor).first else { return }
    
    context.delete(userFact)
    try context.save()
  }
}