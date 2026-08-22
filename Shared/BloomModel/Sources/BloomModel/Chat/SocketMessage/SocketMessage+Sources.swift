//
//  SocketMessage+Sources.swift
//  bloom-model
//

import Foundation

public extension SocketMessage {
  /// A web page the assistant drew on, attached to the message it supports.
  ///
  /// OpenAI requires that web results shown to a user carry a visible, clickable citation, so
  /// anything the assistant says off the back of a search has to arrive with these.
  struct SourceRef: Codable, Hashable, Sendable, Identifiable {
    /// Stable within a message, so the client can diff without reaching for the URL.
    public let id: String
    public let url: String
    /// Lowercased host with `www.` stripped - the key everything server-side is keyed on.
    public let host: String
    /// What to show on the chip: "Tripadvisor" rather than "tripadvisor.ca".
    public let siteName: String
    /// The page title, shown in the sources sheet. Truncated server-side; the same payload goes
    /// out over APNs when the socket is down, and that has a size ceiling.
    public let title: String?
    public let publishedDate: Date?
    /// Served from Bloom's own storage, so rendering a citation doesn't tell a third party what
    /// the user asked about. Nil when the site has no usable icon.
    public let faviconURL: String?
    /// Which block of the message this supports, indexed over the text blocks the message was
    /// split into. Resolved on the server: the model reports offsets into its full output, which
    /// no longer line up once the text is partitioned for sending.
    public let blockIndex: Int?

    public init(
      id: String,
      url: String,
      host: String,
      siteName: String,
      title: String? = nil,
      publishedDate: Date? = nil,
      faviconURL: String? = nil,
      blockIndex: Int? = nil
    ) {
      self.id = id
      self.url = url
      self.host = host
      self.siteName = siteName
      self.title = title
      self.publishedDate = publishedDate
      self.faviconURL = faviconURL
      self.blockIndex = blockIndex
    }
  }
}
