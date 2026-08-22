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

    // Which partition each citation lands in, keyed by its position in `citations` so the service
    // can hand back a block index without re-deriving it.
    var partitionForCitation = [Int: Int]()
    for (offset, citation) in citations.enumerated() {
      partitionForCitation[offset] = Self.partitionIndex(containing: citation.startIndex, in: ranges)
        // An annotation that resolves to nothing - a range past the end, or text that was trimmed
        // away - still belongs somewhere. The last block is the best guess and beats dropping a
        // citation we are obliged to show.
        ?? ranges.last?.partitionIndex
    }

    let service = WebDomainService(logger: logger)
    let refs = await service.sourceRefs(
      from: citations,
      blockIndexForCitation: partitionForCitation,
      db: db
    )

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

    return Dictionary(grouping: refs) { $0.blockIndex ?? ranges.last?.partitionIndex ?? 0 }
  }
}

// MARK: - Offset resolution

extension ChatService {

  struct PartitionRange: Sendable {
    let partitionIndex: Int
    /// UTF-16 offsets, matching what the API reports.
    let range: Range<Int>
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
          range: found.lowerBound.utf16Offset(in: text)..<found.upperBound.utf16Offset(in: text)
        )
      )
      cursor = found.upperBound
    }

    return located
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
