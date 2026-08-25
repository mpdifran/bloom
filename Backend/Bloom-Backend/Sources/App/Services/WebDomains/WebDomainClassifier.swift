//
//  WebDomainClassifier.swift
//  Bloom-Backend
//

import Foundation
import Vapor
import Fluent
import BloomModel
@preconcurrency import OpenAIKit

/// Assigns verdicts to domains that have been cited but never judged.
///
/// Runs on a schedule rather than in the response path. A citation is shown as soon as it passes
/// the deterministic checks and the seeded blocklist; classification catches up behind it and
/// decides whether the domain is shown *next* time. Holding a reply while a model judges a domain
/// would trade a real cost for a small one.
struct WebDomainClassifier: Sendable {

  let openAIService: OpenAIService
  let logger: Logger

  /// Small enough to keep a batch's output short and the model attentive, large enough that a busy
  /// day clears in a few runs.
  static let batchSize = 50

  /// Blocking on a nano model's judgement is only defensible where the category is unambiguous.
  private static let autoBlockThreshold = 0.8
  private static let allowThreshold = 0.7

  private static let autoBlockable: Set<WebDomainReputation.Category> = [
    .adult, .gambling, .illegal, .malwareOrSpam,
  ]
}

extension WebDomainClassifier {

  /// Classifies the next batch of pending domains. Returns how many were judged.
  @discardableResult
  func classifyNextBatch(db: any Database) async throws -> Int {
    let pending = try await WebDomainReputation.query(on: db)
      .filter(\.$verdict == .pending)
      .filter(\.$manualOverride == false)
      // Most-cited first: the domains users actually keep hitting are worth judging soonest.
      .sort(\.$observationCount, .descending)
      .limit(Self.batchSize)
      .all()

    guard pending.isNotEmpty else { return 0 }

    let described = pending.map { record -> String in
      if let title = record.siteName, title.isNotEmpty {
        return "\(record.id ?? "") (seen as: \(title))"
      }
      return record.id ?? ""
    }

    let classifications = try await classify(domains: described)
    guard classifications.isNotEmpty else { return 0 }

    let byDomain = Dictionary(classifications.map { ($0.domain.lowercased(), $0) }) { first, _ in first }
    var judged = 0

    for record in pending {
      guard let domain = record.id, let result = byDomain[domain.lowercased()] else {
        // The model skipped this one. Left pending, so the next run tries again rather than
        // silently treating no answer as approval.
        continue
      }

      apply(result, to: record)
      try await record.save(on: db)
      judged += 1
    }

    logger.info("Classified \(judged) of \(pending.count) pending domains")
    return judged
  }

  /// Maps a classification onto a verdict.
  ///
  /// Deliberately asymmetric. Adult, gambling, illegal and malware are lexically obvious and safe
  /// to act on automatically. Editorial quality is not: a small model asked whether a site pushes
  /// unevidenced health claims will flag legitimate supplement retailers and mainstream wellness
  /// sections, so that answer only ever routes to a human.
  func apply(_ result: WebDomainClassification, to record: WebDomainReputation) {
    record.category = result.category
    record.confidence = result.confidence
    record.reason = result.reason.truncated(to: 200)
    record.source = .classifier
    record.lastClassifiedAt = Date()

    if let siteName = result.siteName, siteName.isNotEmpty {
      record.siteName = siteName.truncated(to: 60)
    }

    let decision = Self.decide(result, domain: record.id)
    record.verdict = decision.verdict
    if decision.manualOverride {
      record.manualOverride = true
    }
  }

  /// The verdict half of `apply`, kept free of the record so the mapping can be tested on its own.
  static func decide(
    _ result: WebDomainClassification,
    domain: String?
  ) -> (verdict: WebDomainReputation.Verdict, manualOverride: Bool) {
    // A domain on the never-block list cannot be demoted by a classifier, whatever it decides.
    if let domain, WebDomainService.neverBlocked.contains(domain) {
      return (.allowed, true)
    }

    switch result.category {
    case _ where autoBlockable.contains(result.category) && result.confidence >= autoBlockThreshold:
      return (.blocked, false)
    case .lowQualityHealth:
      return (.needsReview, false)
    case .safe where result.confidence >= allowThreshold:
      return (.allowed, false)
    default:
      return (.needsReview, false)
    }
  }

  private func classify(domains: [String]) async throws -> [WebDomainClassification] {
    let model = ModelID.GPT5.gpt5Nano

    let response = try await openAIService.openAI.responses.createResponse(
      input: [
        .message(
          .init(
            role: .user,
            content: [.text(.init(text: domains.joined(separator: "\n")))]
          )
        )
      ],
      model: model,
      instructions: .Prompt.webDomainClassifier,
      // Reasoning bills at the output rate and dominates the cost of a batch. Judging whether a
      // domain is a restaurant or a porn site is recall, not deduction - the model has nothing to
      // work out that it does not already know from the name.
      reasoning: Response.Reasoning(effort: .minimal, summary: nil),
      text: OpenAIKit.Text(format: Format(type: .jsonSchema(.webDomainClassification))),
      truncation: .auto
    )

    // Platform overhead, not a user's spend - deliberately not recorded against anyone's budget.
    logger.debug(
      "Domain classification used \(response.usage?.inputTokens ?? 0) in / \(response.usage?.outputTokens ?? 0) out"
    )

    guard let batch = try response.parse(WebDomainClassificationBatch.self) else {
      logger.warning("Domain classification returned nothing parseable")
      return []
    }

    return batch.classifications
  }
}
