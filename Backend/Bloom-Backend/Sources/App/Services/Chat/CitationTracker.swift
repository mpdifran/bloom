//
//  CitationTracker.swift
//  Bloom-Backend
//

import Foundation
import BloomModel
import OpenAIKit

/// Collects the web citations a response produces, so they can be attached when the message is sent.
///
/// Citations arrive on their own stream event (`response.output_text.annotation.added`) rather than
/// with the text they belong to, and they arrive *before* `response.output_text.done` for the same
/// item - so by the time a message is assembled, its citation set is complete.
///
/// Keyed by item as well as user: a single response can produce several messages, and a citation
/// belongs to the one it was annotated on.
final actor CitationTracker {

  private var citations = [UserIdentifier: [String: [Response.Annotation.URLCitation]]]()

  /// Records a citation, ignoring one already recorded for the same URL on the same item.
  ///
  /// The model cites the same page more than once when several claims lean on it, and the chip
  /// beside a paragraph should not repeat.
  func record(_ citation: Response.Annotation.URLCitation, itemID: String, for userID: UserIdentifier) {
    var forUser = citations[userID] ?? [:]
    var forItem = forUser[itemID] ?? []

    guard !forItem.contains(where: { $0.url == citation.url }) else { return }

    forItem.append(citation)
    forUser[itemID] = forItem
    citations[userID] = forUser
  }

  /// Citations for an item, in the order the model produced them.
  func citations(forItem itemID: String, userID: UserIdentifier) -> [Response.Annotation.URLCitation] {
    citations[userID]?[itemID] ?? []
  }

  /// Drops everything for a user. Called when a new response starts, so citations from the previous
  /// turn cannot leak into this one.
  func reset(for userID: UserIdentifier) {
    citations[userID] = nil
  }

  func clear(itemID: String, for userID: UserIdentifier) {
    citations[userID]?[itemID] = nil
  }
}
