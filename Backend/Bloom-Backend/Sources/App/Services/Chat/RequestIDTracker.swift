//
//  RequestIDTracker.swift
//  Bloom-Backend
//
//  Created by Assistant on 2025-06-05.
//

import Foundation
import BloomModel

actor RequestIDTracker {
  private var currentRequestIDs: [UserIdentifier: String] = [:]
  
  func setCurrentRequestID(_ requestID: String?, for userID: UserIdentifier) {
    if let requestID = requestID {
      currentRequestIDs[userID] = requestID
    } else {
      currentRequestIDs.removeValue(forKey: userID)
    }
  }
  
  func getCurrentRequestID(for userID: UserIdentifier) -> String? {
    currentRequestIDs[userID]
  }
  
  func clearRequestID(for userID: UserIdentifier) {
    currentRequestIDs.removeValue(forKey: userID)
  }
}