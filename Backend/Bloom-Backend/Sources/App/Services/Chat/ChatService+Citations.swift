//
//  ChatService+Citations.swift
//  Bloom-Backend
//

import Foundation
import Vapor
import Fluent
import BloomModel
import OpenAIKit

extension ChatService {

  /// Groups a response's citations by the message partition each one supports.
  ///
  /// The model reports a citation as a range into its *whole* output. By the time anything is sent
  /// that text has been split on ```` ```json ```` fences into separate messages, so those offsets
  /// point at nothing the client will ever see. Resolving that here - rather than shipping raw
  /// offsets - keeps index arithmetic on the server where it can be tested, and means the client
  /// only ever receives sources already attached to the right message.
  ///
  /// - Returns: partition index to the sources belonging to it. Partitions with no citations are
  ///   absent rather than present-and-empty.
  func sources(
    forCitations citations: [OpenAIKit.Response.Annotation.URLCitation],
    in text: String,
    partitions: [StreamJSONBuffer.CompletedPartitions],
    db: any Database
  ) async -> [Int: [SocketMessage.SourceRef]] {
    guard citations.isNotEmpty else { return [:] }

    let ranges = Self.textPartitionRanges(in: text, partitions: partitions)

    // Two different indices per citation, for two different jobs.
    //
    // The partition decides which *message* a source belongs to, since each text partition is sent
    // as its own message. The paragraph decides where inside that message the chip is drawn - all
    // of them at the bottom reads as a bibliography rather than a citation.
    var partitionForCitation = [Int: Int]()
    var paragraphForCitation = [Int: Int]()

    for (offset, citation) in citations.enumerated() {
      guard let block = ranges.first(where: { $0.range.contains(citation.startIndex) })
        // An annotation that resolves to nothing - a range past the end, or text trimmed away -
        // still belongs somewhere. The last block beats dropping a citation we must show.
        ?? ranges.last
      else { continue }

      partitionForCitation[offset] = block.partitionIndex
      paragraphForCitation[offset] = Self.paragraphIndex(
        forUTF16Offset: citation.startIndex,
        in: block
      )
    }

    let service = WebDomainService(logger: logger)
    let located = await service.sourceRefs(
      from: citations,
      blockIndexForCitation: paragraphForCitation,
      db: db
    )
    let refs = located.map(\.ref)

    // Record what was cited, then fetch any icons we don't have. Detached: neither should hold up
    // a chat message, and a slow favicon server must never be able to stall a reply.
    let hosts: [String] = refs.map { $0.host }
    if hosts.isNotEmpty {
      let fetcher = FaviconFetcher(
        httpClient: application.http.client.shared,
        imageStorage: application.imageStorage,
        logger: logger
      )
      Task.detached {
        await service.observe(hosts: hosts, db: db)
        for host in Set(hosts) {
          await fetcher.fetchIfNeeded(host: host, db: db)
        }
      }
    }

    // Grouped by partition so each message carries its own sources; the paragraph index rides
    // along inside each source.
    return Dictionary(grouping: located) { partitionForCitation[$0.citationOffset] ?? 0 }
      .mapValues { $0.map(\.ref) }
  }
}

// MARK: - Offset resolution

extension ChatService {

  struct PartitionRange: Sendable {
    let partitionIndex: Int
    /// UTF-16 offsets, matching what the API reports.
    let range: Range<Int>
    /// The block's text, kept so a citation can be resolved to a paragraph within it.
    let content: String
  }

  /// Locates each text partition within the original output.
  ///
  /// Partitions are verbatim substrings of the source, in order, so a single forward scan is
  /// enough - and using the previous match as the next search floor stops a short repeated
  /// paragraph matching the wrong occurrence.
  static func textPartitionRanges(
    in text: String,
    partitions: [StreamJSONBuffer.CompletedPartitions]
  ) -> [PartitionRange] {
    var located = [PartitionRange]()
    var cursor = text.startIndex

    for partition in partitions {
      guard case .text(let index, let content) = partition, content.isNotEmpty else { continue }
      guard cursor < text.endIndex,
            let found = text.range(of: content, range: cursor..<text.endIndex) else { continue }

      located.append(
        PartitionRange(
          partitionIndex: index,
          range: found.lowerBound.utf16Offset(in: text)..<found.upperBound.utf16Offset(in: text),
          content: content
        )
      )
      cursor = found.upperBound
    }

    return located
  }

  /// Which paragraph of a block a citation falls in.
  ///
  /// Paragraphs are separated by a blank line, which is how the model formats prose and lists. This
  /// is the granularity the chips are drawn at: fine enough that a citation sits beside the claim
  /// it supports, coarse enough to need no text layout work on the client.
  static func paragraphIndex(forUTF16Offset offset: Int, in block: PartitionRange) -> Int {
    let relative = offset - block.range.lowerBound
    guard relative > 0 else { return 0 }

    var consumed = 0
    for (index, paragraph) in block.content.components(separatedBy: "\n\n").enumerated() {
      // +2 for the blank line that separated it, which is not part of the paragraph itself.
      consumed += paragraph.utf16.count + 2
      if relative < consumed { return index }
    }

    // Past the end: the model sometimes annotates a range that runs to the close of the block.
    return max(block.content.components(separatedBy: "\n\n").count - 1, 0)
  }

  /// The partition a UTF-16 offset falls inside, if any.
  ///
  /// Offsets are UTF-16 code units because that is what the API reports; comparing them against
  /// `Character` counts would drift on anything outside the basic plane, which for a health app
  /// answering in five languages is not hypothetical.
  static func partitionIndex(containing utf16Offset: Int, in ranges: [PartitionRange]) -> Int? {
    ranges.first { $0.range.contains(utf16Offset) }?.partitionIndex
  }
}
