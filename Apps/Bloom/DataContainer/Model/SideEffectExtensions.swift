//
//  SideEffectExtensions.swift
//  DataContainer
//
//  Created by Assistant on 2025-08-09.
//

import Foundation

// MARK: - Helper Extensions for ReminderSideEffect
extension ReminderSideEffect {
  public func decodeConfiguration<T: SideEffectConfiguration>(as type: T.Type) -> T? {
    try? JSONDecoder.dataContainer.decode(type, from: configuration)
  }
  
  public func encodeConfiguration<T: SideEffectConfiguration>(_ config: T) throws {
    configuration = try JSONEncoder.dataContainer.encode(config)
  }
}

// MARK: - Helper Extensions for ReminderCompletionRecord
extension ReminderCompletionRecord {
  public func decodeSideEffectResults() -> [SideEffectExecutionResult]? {
    guard let data = sideEffectResults else { return nil }
    return try? JSONDecoder.dataContainer.decode([SideEffectExecutionResult].self, from: data)
  }
  
  public func encodeSideEffectResults(_ results: [SideEffectExecutionResult]) throws {
    sideEffectResults = try JSONEncoder.dataContainer.encode(results)
  }
}