//
//  UserModelTests.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2026-09-29.
//

@testable import App
import BloomModel
import Testing

@Suite("UserModel")
struct UserModelTests {

  /// Sign-in builds the response from a user it may have just created, so every field it reads
  /// has to be safe on a fresh `User(id:)`. An unset `@Field` is a fatalError that takes the
  /// dyno down mid-request.
  @Test("A newly created user has no migrated Apple identifier yet")
  func freshUserMigrationFieldsAreNil() {
    let user = User(id: UserIdentifier("001234.abcdef"))

    #expect(user.newAppleID == nil)
    #expect(user.transferSub == nil)
    #expect(user.migratedEmail == nil)
  }
}
