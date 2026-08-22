import Fluent
import SQLKit

extension WebDomainReputation {
  struct Create: AsyncMigration {
    func prepare(on database: any Database) async throws {
      let verdict = try await database.enum(Verdict.self)
        .case(.pending)
        .case(.allowed)
        .case(.blocked)
        .case(.needsReview)
        .create()

      let category = try await database.enum(Category.self)
        .case(.safe)
        .case(.adult)
        .case(.gambling)
        .case(.illegal)
        .case(.malwareOrSpam)
        .case(.lowQualityHealth)
        .case(.unknown)
        .create()

      let source = try await database.enum(Source.self)
        .case(.seed)
        .case(.observed)
        .case(.classifier)
        .case(.manual)
        .create()

      try await database.schema(WebDomainReputation.schema)
        .field("id", .string, .identifier(auto: false))
        .field(.WebDomainReputation.verdict, verdict, .required)
        .field(.WebDomainReputation.category, category)
        .field(.WebDomainReputation.confidence, .double)
        .field(.WebDomainReputation.reason, .string)
        .field(.WebDomainReputation.source, source, .required)
        .field(.WebDomainReputation.manualOverride, .bool, .required, .custom("DEFAULT false"))
        .field(.WebDomainReputation.observationCount, .int, .required, .custom("DEFAULT 0"))
        .field(.WebDomainReputation.siteName, .string)
        .field(.WebDomainReputation.faviconURL, .string)
        .field(.WebDomainReputation.faviconFetchedAt, .datetime)
        .field(.WebDomainReputation.lastClassifiedAt, .datetime)
        .field(.WebDomainReputation.firstSeenAt, .datetime)
        .field(.WebDomainReputation.lastSeenAt, .datetime)
        .create()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(WebDomainReputation.schema).delete()
      try await database.enum(Verdict.self).delete()
      try await database.enum(Category.self).delete()
      try await database.enum(Source.self).delete()
    }
  }

  /// The blocklist is read on every citation, and ranked to pick the 100 domains worth spending
  /// OpenAI's request-time filter on. Both want an index.
  struct AddVerdictIndexes: AsyncMigration {
    func prepare(on database: any Database) async throws {
      guard let sql = database as? any SQLDatabase else { return }

      try await sql.raw("""
        CREATE INDEX IF NOT EXISTS web_domain_reputations_verdict_observations_idx
        ON web_domain_reputations (verdict, observation_count DESC)
        """).run()

      try await sql.raw("""
        CREATE INDEX IF NOT EXISTS web_domain_reputations_verdict_last_seen_idx
        ON web_domain_reputations (verdict, last_seen_at)
        """).run()
    }

    func revert(on database: any Database) async throws {
      guard let sql = database as? any SQLDatabase else { return }

      try await sql.raw("DROP INDEX IF EXISTS web_domain_reputations_verdict_observations_idx").run()
      try await sql.raw("DROP INDEX IF EXISTS web_domain_reputations_verdict_last_seen_idx").run()
    }
  }
}
