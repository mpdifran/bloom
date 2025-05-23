//
//  StreamJSONBuffer.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-05-21.
//

import Foundation
import BloomModel

extension StreamJSONBuffer {
  enum FilteredData {
    case chunk(Int, String)
    case json(Int, String)
  }
  enum CompletedPartitions {
    case text(Int, String)
    case json(Int, String)
  }
}

final actor StreamJSONBuffer {
  private var indices = [UserIdentifier : Int]()
  private var prefixBuffers = [UserIdentifier : String]()
  private var buffers =  [UserIdentifier : String]()
  private var lastPartitionWasJSON = [UserIdentifier : Bool]()

  func resetIndex(for userID: UserIdentifier) {
    indices[userID] = nil
    lastPartitionWasJSON[userID] = nil
  }

  func filter(_ delta: String, for userID: UserIdentifier) -> FilteredData? {
    let currentIndex = indices[userID, default: 1]
    let fenceOpen = "```json"
    let fenceClose = "```"

    // 1. If buffering JSON content already
    if buffers[userID] != nil {
      // Look for closing fence
      buffers[userID, default: ""] += delta
      let buffer = buffers[userID, default: ""]

      if let closeRange = buffer.range(of: fenceClose) {
        let jsonString = String(buffer[..<closeRange.lowerBound])
//        let after = String(buffer[closeRange.upperBound...])
//        buffers[userID, default: ""] = after // Do we need to store after here?
        buffers.removeValue(forKey: userID)
        indices[userID, default: 1] += 1
        print("Detected close range. CurrentIndex: \(currentIndex), index: \(indices[userID, default: 1])")
        return .json(currentIndex, jsonString)
      } else {
        return nil
      }
    }

    // 2. If in prefix detection of an opening fence
    if let prefix = prefixBuffers[userID] {
      let updated = prefix + delta
      // Continue gathering until we have at least the length of fenceOpen
      if updated.count >= fenceOpen.count {
        prefixBuffers.removeValue(forKey: userID)
        if let range = updated.range(of: fenceOpen) {
          let before = String(updated[..<range.lowerBound])
          let after = String(updated[range.upperBound...])
          buffers[userID] = after
          indices[userID, default: 1] += 1
          print("Detected open range. CurrentIndex: \(currentIndex), index: \(indices[userID, default: 1])")
          return .chunk(currentIndex, before)
        } else {
          // Not an opening fence after all
          return .chunk(currentIndex, updated)
        }
      } else {
        // Still potentially completing the fence; buffer silently
        prefixBuffers[userID] = updated
        return nil
      }
    }

    // 3. Not buffering and no prefix state
    if let openRange = delta.range(of: fenceOpen) {
      // full marker found in this chunk
      let before = String(delta[..<openRange.lowerBound])
      let after = String(delta[openRange.upperBound...])
      buffers[userID] = after
      indices[userID, default: 1] += 1
      print("Detected open range. CurrentIndex: \(currentIndex), index: \(indices[userID, default: 1])")
      return .chunk(currentIndex, before)
    }

    // 4. Partial fence start: detect backticks but not full marker
    if delta.contains(fenceOpen.prefix(1)) {
      // Begin prefix detection
      prefixBuffers[userID] = delta
      return nil
    }

    // 5. Normal text
    return .chunk(currentIndex, delta)
  }

  func processCompletedMessage(_ message: String, for userID: UserIdentifier) -> [CompletedPartitions] {
    var events: [CompletedPartitions] = []
    let fenceOpen = "```json"
    let fenceClose = "```"
    var searchStart = message.startIndex
    var index = 0

    while let openRange = message.range(of: fenceOpen, range: searchStart..<message.endIndex) {
      // Text before the JSON fence
      let textPart = String(message[searchStart..<openRange.lowerBound])
      if !textPart.isEmpty {
        index += 1
        events.append(.text(index, textPart))
      }
      // Look for closing fence after the opening
      let jsonStart = openRange.upperBound
      guard let closeRange = message.range(of: fenceClose, range: jsonStart..<message.endIndex) else {
        // No closing fence; treat the rest as text
        let remainder = String(message[jsonStart..<message.endIndex])
        if !remainder.isEmpty {
          index += 1
          events.append(.text(index, remainder))
        }
        return events
      }
      // JSON content between fences
      let jsonPart = String(message[jsonStart..<closeRange.lowerBound])
      index += 1
      events.append(.json(index, jsonPart))
      // Continue after the closing fence
      searchStart = closeRange.upperBound
    }

    // Any trailing text after last fence
    let trailing = String(message[searchStart..<message.endIndex])
    if !trailing.isEmpty {
      index += 1
      events.append(.text(index, trailing))
    }
    return events
  }
}
