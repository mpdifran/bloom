//
//  WebDomainReputation.swift
//  Bloom-Backend
//

import Foundation
import Vapor
import Fluent

/// What we know about a domain the assistant has drawn on, and how to show it.
///
/// Two jobs in one row, because they share a key and are written at the same moment:
///
/// - **Whether a citation may be shown.** Seeded in bulk from a public blocklist, then extended by
///   classification. Blocked domains are filtered out before a citation reaches a user.
/// - **How the citation looks.** The favicon and site name the client renders on a chip.
///
/// Keyed on the full host rather than the registrable domain. Blocking `medium.com` because of one
/// bad post is a worse failure than missing `evil2.example.com`, and the frequency ranking catches
/// repeat offenders anyway. OpenAI's own `blocked_domains` filter matches subdomains, so the
/// request-time gate gets that coverage regardless.
final class WebDomainReputation: Model, @unchecked Sendable {
  static let schema = "web_domain_reputations"

  /// Lowercased host with `www.` stripped. The natural key - there is nothing else to identify a
  /// domain by, and a surrogate id would just need a unique index on this anyway.
  @ID(custom: "id", generatedBy: .user)
  var id: String?

  @Enum(key: .WebDomainReputation.verdict)
  var verdict: Verdict

  @OptionalEnum(key: .WebDomainReputation.category)
  var category: Category?

  @Field(key: .WebDomainReputation.confidence)
  var confidence: Double?

  /// The classifier's short rationale, kept for audit - a blocked domain should be explicable.
  @Field(key: .WebDomainReputation.reason)
  var reason: String?

  @Enum(key: .WebDomainReputation.source)
  var source: Source

  /// A human verdict is never re-litigated by the classifier.
  @Field(key: .WebDomainReputation.manualOverride)
  var manualOverride: Bool

  /// Drives which 100 domains are worth spending the request-time filter on.
  @Field(key: .WebDomainReputation.observationCount)
  var observationCount: Int

  @Field(key: .WebDomainReputation.siteName)
  var siteName: String?

  @Field(key: .WebDomainReputation.faviconURL)
  var faviconURL: String?

  @Field(key: .WebDomainReputation.faviconFetchedAt)
  var faviconFetchedAt: Date?

  @Field(key: .WebDomainReputation.lastClassifiedAt)
  var lastClassifiedAt: Date?

  @Timestamp(key: .WebDomainReputation.firstSeenAt, on: .create)
  var firstSeenAt: Date?

  @Timestamp(key: .WebDomainReputation.lastSeenAt, on: .update)
  var lastSeenAt: Date?

  init() { }

  init(
    host: String,
    verdict: Verdict = .pending,
    category: Category? = nil,
    confidence: Double? = nil,
    reason: String? = nil,
    source: Source = .observed,
    manualOverride: Bool = false,
    observationCount: Int = 1,
    siteName: String? = nil
  ) {
    self.id = host
    self.verdict = verdict
    self.category = category
    self.confidence = confidence
    self.reason = reason
    self.source = source
    self.manualOverride = manualOverride
    self.observationCount = observationCount
    self.siteName = siteName
  }
}

extension WebDomainReputation {
  enum Verdict: String, Codable, FluentEnum {
    static let schema = "web_domain_verdict"

    /// Seen but not yet judged. Citations are still shown - see `WebDomainService`.
    case pending
    case allowed
    case blocked
    /// The classifier was unsure, or judged something it should not decide alone. Held back from
    /// users until a human looks.
    case needsReview
  }

  enum Category: String, Codable, CaseIterable, FluentEnum {
    static let schema = "web_domain_category"

    case safe
    case adult
    case gambling
    case illegal
    case malwareOrSpam
    /// Never auto-blocks. Editorial quality is not something a small model should rule on alone -
    /// it will flag legitimate supplement retailers and mainstream wellness sections.
    case lowQualityHealth
    case unknown
  }

  enum Source: String, Codable, FluentEnum {
    static let schema = "web_domain_source"

    /// Bulk-imported from a public blocklist.
    case seed
    /// First seen in a citation.
    case observed
    case classifier
    case manual
  }
}

extension FieldKey {
  enum WebDomainReputation {
    static let verdict = FieldKey("verdict")
    static let category = FieldKey("category")
    static let confidence = FieldKey("confidence")
    static let reason = FieldKey("reason")
    static let source = FieldKey("source")
    static let manualOverride = FieldKey("manual_override")
    static let observationCount = FieldKey("observation_count")
    static let siteName = FieldKey("site_name")
    static let faviconURL = FieldKey("favicon_url")
    static let faviconFetchedAt = FieldKey("favicon_fetched_at")
    static let lastClassifiedAt = FieldKey("last_classified_at")
    static let firstSeenAt = FieldKey("first_seen_at")
    static let lastSeenAt = FieldKey("last_seen_at")
  }
}
