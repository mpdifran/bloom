//
//  StreamJSONBuffer.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-05-21.
//

import Foundation
import BloomModel

extension StreamJSONBuffer {
  enum FilteredData: Hashable, Sendable {
    case chunk(Int, String)
    case json(Int, String)
    case streamingText
    case collectingJSON
  }
  enum CompletedPartitions: Hashable, Sendable {
    case text(Int, String)
    case json(Int, String)
  }
}

final actor StreamJSONBuffer {
  private var indices = [UserIdentifier : Int]()
  private var prefixBuffers = [UserIdentifier : String]()
  private var buffers =  [UserIdentifier : String]()
  // Track if we've emitted text chunks for the current index
  private var hasEmittedTextForCurrentIndex = [UserIdentifier : Bool]()

  func resetIndex(for userID: UserIdentifier) {
    indices[userID] = nil
    hasEmittedTextForCurrentIndex[userID] = nil
  }

  func filter(_ delta: String, for userID: UserIdentifier) -> [FilteredData] {
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
        let after = String(buffer[closeRange.upperBound...])
        buffers.removeValue(forKey: userID)
        // Get the current index for JSON (which was set when we started collecting)
        let jsonIndex = indices[userID, default: 1]
        // Increment index for next section after JSON
        let nextIndex = jsonIndex + 1
        indices[userID] = nextIndex
        hasEmittedTextForCurrentIndex[userID] = false // Reset for next section
        let trimmedAfter = stripLeadingNewlineIfFirstChunk(after, userID: userID, index: nextIndex)
        if trimmedAfter.isNotEmpty {
          hasEmittedTextForCurrentIndex[userID] = true // Mark that we're emitting text
          return [.json(jsonIndex, jsonString), .streamingText, .chunk(nextIndex, trimmedAfter)]
        } else {
          return [.json(jsonIndex, jsonString), .streamingText]
        }
      } else {
        return []
      }
    }

    // 2. If in prefix detection of an opening fence
    if let prefix = prefixBuffers[userID] {
      let updated = prefix + delta
      // Continue gathering until we have at least the length of fenceOpen
      if updated.contains(fenceOpen) || updated.count >= fenceOpen.count * 2 {
        prefixBuffers.removeValue(forKey: userID)
        if let range = updated.range(of: fenceOpen) {
          let before = String(updated[..<range.lowerBound])
          let after = String(updated[range.upperBound...])
          buffers[userID] = after
          let trimmedBefore = stripLeadingNewlineIfFirstChunk(before, userID: userID, index: currentIndex)
          if trimmedBefore.isNotEmpty {
            // Text before JSON: emit text with current index, increment for JSON
            hasEmittedTextForCurrentIndex[userID] = true
            indices[userID] = currentIndex + 1
            return [.chunk(currentIndex, trimmedBefore), .collectingJSON]
          } else {
            // No text before JSON but check if we've emitted text chunks already
            if hasEmittedTextForCurrentIndex[userID] == true {
              // We've emitted text chunks, so increment for JSON
              indices[userID] = currentIndex + 1
            }
            return [.collectingJSON]
          }
        } else {
          // Not an opening fence after all
          let trimmedUpdated = stripLeadingNewlineIfFirstChunk(updated, userID: userID, index: currentIndex)
          if trimmedUpdated.isNotEmpty {
            return [.chunk(currentIndex, trimmedUpdated)]
          } else {
            return []
          }
        }
      } else {
        // Still potentially completing the fence; buffer silently
        prefixBuffers[userID] = updated
        return []
      }
    }

    // 3. Not buffering and no prefix state
    if let openRange = delta.range(of: fenceOpen) {
      // full marker found in this chunk
      let before = String(delta[..<openRange.lowerBound])
      let after = String(delta[openRange.upperBound...])
      buffers[userID] = after
      let trimmedBefore = stripLeadingNewlineIfFirstChunk(before, userID: userID, index: currentIndex)
      if trimmedBefore.isNotEmpty {
        // Text before JSON: emit text with current index, increment for JSON
        hasEmittedTextForCurrentIndex[userID] = true
        indices[userID] = currentIndex + 1
        return [.chunk(currentIndex, trimmedBefore), .collectingJSON]
      } else {
        // No text before JSON but check if we've emitted text chunks already
        if hasEmittedTextForCurrentIndex[userID] == true {
          // We've emitted text chunks, so increment for JSON
          indices[userID] = currentIndex + 1
        }
        return [.collectingJSON]
      }
    }

    // 4. Partial fence start: detect backticks but not full marker
    if delta.contains(fenceOpen.prefix(1)) {
      // Begin prefix detection
      prefixBuffers[userID] = delta
      return []
    }

    // 5. Normal text
    let trimmedDelta = stripLeadingNewlineIfFirstChunk(delta, userID: userID, index: currentIndex)
    if trimmedDelta.isNotEmpty {
      hasEmittedTextForCurrentIndex[userID] = true
      return [.chunk(currentIndex, trimmedDelta)]
    } else {
      return []
    }
  }

  func processCompletedMessage(_ message: String, for userID: UserIdentifier) -> [CompletedPartitions] {
    var events: [CompletedPartitions] = []
    let fenceOpen = "```json"
    let fenceClose = "```"
    var searchStart = message.startIndex
    var index = 1

    while let openRange = message.range(of: fenceOpen, range: searchStart..<message.endIndex) {
      // Text before the JSON fence
      let textPart = String(message[searchStart..<openRange.lowerBound])
        .trimmingCharacters(in: .whitespacesAndNewlines)
      if !textPart.isEmpty {
        events.append(.text(index, textPart))
        index += 1
      }
      // Look for closing fence after the opening
      let jsonStart = openRange.upperBound
      guard let closeRange = message.range(of: fenceClose, range: jsonStart..<message.endIndex) else {
        // No closing fence; treat the rest as text
        let remainder = String(message[jsonStart..<message.endIndex])
          .trimmingCharacters(in: .whitespacesAndNewlines)
        if !remainder.isEmpty {
          events.append(.text(index, remainder))
        }
        return events
      }
      // JSON content between fences
      let jsonPart = String(message[jsonStart..<closeRange.lowerBound])
      events.append(.json(index, jsonPart))
      index += 1
      // Continue after the closing fence
      searchStart = closeRange.upperBound
    }

    // Any trailing text after last fence
    let trailing = String(message[searchStart..<message.endIndex])
      .trimmingCharacters(in: .whitespacesAndNewlines)
    if !trailing.isEmpty {
      events.append(.text(index, trailing))
    }
    return events
  }
  
  private func stripLeadingNewlineIfFirstChunk(_ text: String, userID: UserIdentifier, index: Int) -> String {
    // Strip leading newline if this is the first chunk for this text section
    if hasEmittedTextForCurrentIndex[userID] != true && text.hasPrefix("\n") {
      return String(text.dropFirst())
    }
    return text
  }
}
