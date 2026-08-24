import BloomModel
import Foundation

// MARK: - Web Domain Reputation

/// A domain the assistant has drawn on, as the admin tool sees it.
public struct AdminWebDomainModel: Codable, Sendable, Identifiable {
  public var id: String { domain }

  public let domain: String
  /// `pending`, `allowed`, `blocked` or `needsReview`.
  public let verdict: String
  public let category: String?
  public let confidence: Double?
  /// The classifier's rationale, or a human's note. What makes a block explicable later.
  public let reason: String?
  /// `seed`, `observed`, `classifier` or `manual`.
  public let source: String
  /// Set once a human has ruled, after which the classifier leaves it alone.
  public let manualOverride: Bool
  /// How often this domain has been read or cited. Drives review order and which domains are worth
  /// one of the hundred request-time filter slots.
  public let observationCount: Int
  public let siteName: String?
  public let lastSeenAt: Date?
  public let lastClassifiedAt: Date?

  public init(
    domain: String,
    verdict: String,
    category: String? = nil,
    confidence: Double? = nil,
    reason: String? = nil,
    source: String,
    manualOverride: Bool,
    observationCount: Int,
    siteName: String? = nil,
    lastSeenAt: Date? = nil,
    lastClassifiedAt: Date? = nil
  ) {
    self.domain = domain
    self.verdict = verdict
    self.category = category
    self.confidence = confidence
    self.reason = reason
    self.source = source
    self.manualOverride = manualOverride
    self.observationCount = observationCount
    self.siteName = siteName
    self.lastSeenAt = lastSeenAt
    self.lastClassifiedAt = lastClassifiedAt
  }
}

public struct AdminWebDomainListResponse: Codable, Sendable {
  public let domains: [AdminWebDomainModel]

  public init(domains: [AdminWebDomainModel]) {
    self.domains = domains
  }
}

public struct AdminWebDomainStatsResponse: Codable, Sendable {
  /// Keyed by verdict. The quickest read on whether classification is keeping pace with what users
  /// are citing - a growing `pending` count means it is not.
  public let countsByVerdict: [String: Int]

  public init(countsByVerdict: [String: Int]) {
    self.countsByVerdict = countsByVerdict
  }
}

public struct AdminSetWebDomainVerdictRequest: Codable, Sendable {
  public let verdict: String
  public let reason: String?

  public init(verdict: String, reason: String? = nil) {
    self.verdict = verdict
    self.reason = reason
  }
}
