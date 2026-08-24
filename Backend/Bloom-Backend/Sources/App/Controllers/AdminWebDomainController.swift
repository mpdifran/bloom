//
//  AdminWebDomainController.swift
//  Bloom-Backend
//

import AdminBloomModel
import BloomModel
import Fluent
import Foundation
import Vapor

/// Review queue for domains the classifier would not decide alone.
///
/// Without somewhere to clear it, `needsReview` is a write-only state: those domains have their
/// citations withheld and nothing ever lets them out. Editorial quality in particular is routed
/// here by design rather than auto-blocked, so this is where that judgement actually gets made.
struct AdminWebDomainController { }

extension AdminWebDomainController: RouteCollection {

  func boot(routes: any RoutesBuilder) throws {
    routes.group("v1", "admin") {
      $0.adminAuth {
        $0.group("web-domains") {
          $0.get(use: list)
          $0.get("stats", use: stats)
          $0.post(":domain", "verdict", use: setVerdict)
        }
      }
    }
  }
}

private extension AdminWebDomainController {

  /// Domains awaiting a decision, most-encountered first.
  @Sendable
  func list(_ request: Request) async throws -> AdminWebDomainListResponse {
    let verdict = request.query[String.self, at: "verdict"]
      .flatMap { WebDomainReputation.Verdict(rawValue: $0) } ?? .needsReview
    let limit = min(request.query[Int.self, at: "limit"] ?? 50, 200)

    let records = try await WebDomainReputation.query(on: request.db)
      .filter(\.$verdict == verdict)
      .sort(\.$observationCount, .descending)
      .limit(limit)
      .all()

    return AdminWebDomainListResponse(domains: records.map { $0.asAdminModel() })
  }

  /// How the corpus is distributed, which is the quickest read on whether classification is
  /// keeping up with what users are actually citing.
  @Sendable
  func stats(_ request: Request) async throws -> AdminWebDomainStatsResponse {
    var counts = [String: Int]()
    for verdict in [WebDomainReputation.Verdict.pending, .allowed, .blocked, .needsReview] {
      counts[verdict.rawValue] = try await WebDomainReputation.query(on: request.db)
        .filter(\.$verdict == verdict)
        .count()
    }
    return AdminWebDomainStatsResponse(countsByVerdict: counts)
  }

  /// Records a human verdict, which the classifier will not revisit.
  @Sendable
  func setVerdict(_ request: Request) async throws -> AdminWebDomainModel {
    guard let domain = request.parameters.get("domain") else {
      throw Abort(.badRequest, reason: "Missing domain")
    }
    let body = try request.content.decode(AdminSetWebDomainVerdictRequest.self)
    guard let verdict = WebDomainReputation.Verdict(rawValue: body.verdict) else {
      throw Abort(.badRequest, reason: "Unknown verdict \(body.verdict)")
    }

    let normalized = domain.lowercased()
    let record = try await WebDomainReputation.find(normalized, on: request.db)
      // A domain can be decided before it has ever been cited - blocking something known to be bad
      // rather than waiting for a user to hit it.
      ?? WebDomainReputation(host: normalized, verdict: verdict, source: .manual)

    record.verdict = verdict
    record.source = .manual
    record.manualOverride = true
    if let reason = body.reason { record.reason = reason.truncated(to: 200) }

    try await record.save(on: request.db)

    return record.asAdminModel()
  }
}

private extension WebDomainReputation {
  func asAdminModel() -> AdminWebDomainModel {
    AdminWebDomainModel(
      domain: id ?? "",
      verdict: verdict.rawValue,
      category: category?.rawValue,
      confidence: confidence,
      reason: reason,
      source: source.rawValue,
      manualOverride: manualOverride,
      observationCount: observationCount,
      siteName: siteName,
      lastSeenAt: lastSeenAt,
      lastClassifiedAt: lastClassifiedAt
    )
  }
}
