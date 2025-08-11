//
//  StableHashGeneratorTests.swift
//  BloomTests
//
//  Created by Mark DiFranco on 2025-08-11.
//

import XCTest
@testable import Bloom

final class StableHashGeneratorTests: XCTestCase {
  
  func testStableHashIsDeterministic() {
    let experimentId = "test_experiment"
    let userId = "user123"
    
    // Same inputs should always produce the same hash
    let hash1 = StableHashGenerator.stableHash(experimentId: experimentId, userId: userId)
    let hash2 = StableHashGenerator.stableHash(experimentId: experimentId, userId: userId)
    
    XCTAssertEqual(hash1, hash2, "Hash should be deterministic for same inputs")
  }
  
  func testStableHashDifferentForDifferentInputs() {
    let experimentId = "test_experiment"
    
    let hash1 = StableHashGenerator.stableHash(experimentId: experimentId, userId: "user1")
    let hash2 = StableHashGenerator.stableHash(experimentId: experimentId, userId: "user2")
    
    XCTAssertNotEqual(hash1, hash2, "Different users should produce different hashes")
  }
  
  func testStableHashDifferentForDifferentExperiments() {
    let userId = "user123"
    
    let hash1 = StableHashGenerator.stableHash(experimentId: "experiment1", userId: userId)
    let hash2 = StableHashGenerator.stableHash(experimentId: "experiment2", userId: userId)
    
    XCTAssertNotEqual(hash1, hash2, "Different experiments should produce different hashes")
  }
  
  func testStableHashDistribution() {
    let experimentId = "distribution_test"
    let numberOfUsers = 1000
    var treatmentCount = 0
    var controlCount = 0
    
    // Generate random user IDs and check distribution
    for i in 0..<numberOfUsers {
      let userId = "user_\(UUID().uuidString)_\(i)"
      let hashValue = StableHashGenerator.stableHash(experimentId: experimentId, userId: userId)
      let normalizedValue = Double(hashValue) / Double(UInt64.max)
      
      // Using 0.5 as threshold (50/50 split)
      if normalizedValue < 0.5 {
        treatmentCount += 1
      } else {
        controlCount += 1
      }
    }
    
    // Calculate the actual split percentage
    let treatmentPercentage = Double(treatmentCount) / Double(numberOfUsers)
    let controlPercentage = Double(controlCount) / Double(numberOfUsers)
    
    print("Treatment: \(treatmentCount) (\(treatmentPercentage * 100)%)")
    print("Control: \(controlCount) (\(controlPercentage * 100)%)")
    
    // Allow for some variance (e.g., 45-55% split is acceptable for 1000 samples)
    // Using binomial distribution, standard deviation = sqrt(n*p*(1-p)) = sqrt(1000*0.5*0.5) ≈ 15.8
    // 3 standard deviations = ~47, so we expect between 453-547 for each group (45.3%-54.7%)
    let acceptableMinPercentage = 0.45
    let acceptableMaxPercentage = 0.55
    
    XCTAssertGreaterThanOrEqual(treatmentPercentage, acceptableMinPercentage,
                                 "Treatment percentage should be at least \(acceptableMinPercentage * 100)%")
    XCTAssertLessThanOrEqual(treatmentPercentage, acceptableMaxPercentage,
                              "Treatment percentage should be at most \(acceptableMaxPercentage * 100)%")
    
    XCTAssertGreaterThanOrEqual(controlPercentage, acceptableMinPercentage,
                                 "Control percentage should be at least \(acceptableMinPercentage * 100)%")
    XCTAssertLessThanOrEqual(controlPercentage, acceptableMaxPercentage,
                              "Control percentage should be at most \(acceptableMaxPercentage * 100)%")
  }
  
  func testStableHashHandlesEmptyStrings() {
    // Should handle empty strings without crashing
    let hash1 = StableHashGenerator.stableHash(experimentId: "", userId: "user")
    let hash2 = StableHashGenerator.stableHash(experimentId: "experiment", userId: "")
    let hash3 = StableHashGenerator.stableHash(experimentId: "", userId: "")
    
    // Just verify they produce values without crashing
    XCTAssertNotNil(hash1)
    XCTAssertNotNil(hash2)
    XCTAssertNotNil(hash3)
  }
  
  func testStableHashHandlesSpecialCharacters() {
    let experimentId = "test_experiment"
    let specialUserId = "user@123#$%^&*()_+-=[]{}|;':\",./<>?"
    
    // Should handle special characters without crashing
    let hash = StableHashGenerator.stableHash(experimentId: experimentId, userId: specialUserId)
    XCTAssertNotNil(hash)
    
    // Should be deterministic even with special characters
    let hash2 = StableHashGenerator.stableHash(experimentId: experimentId, userId: specialUserId)
    XCTAssertEqual(hash, hash2)
  }
  
  func testStableHashHandlesUnicodeCharacters() {
    let experimentId = "test_experiment"
    let unicodeUserId = "用户123👨‍💻🚀"
    
    // Should handle Unicode characters without crashing
    let hash = StableHashGenerator.stableHash(experimentId: experimentId, userId: unicodeUserId)
    XCTAssertNotNil(hash)
    
    // Should be deterministic even with Unicode
    let hash2 = StableHashGenerator.stableHash(experimentId: experimentId, userId: unicodeUserId)
    XCTAssertEqual(hash, hash2)
  }
}