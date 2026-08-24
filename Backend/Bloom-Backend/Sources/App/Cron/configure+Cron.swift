//
//  configure+Cron.swift
//  Bloom-Backend
//
//  Created by Assistant on 2025-07-27.
//

import Vapor
import VaporCron

extension Application {
  func configureCronJobs() throws {
    // Duplicate detection job - runs every 4 hours at minute 0
    try cron.schedule("0 */4 * * *") { [weak self] in
      guard let self else { return }

      self.logger.info("Starting duplicate detection cron job")
      
      let duplicateService = DuplicateDetectionService(
        db: self.db,
        logger: self.logger
      )
      
      Task {
        do {
          try await duplicateService.processNextBatch()
          self.logger.info("Duplicate detection cron job completed successfully")
        } catch {
          self.logger.error("Duplicate detection cron job failed: \(error)")
        }
      }
    }
    
    // Magic Scanner S3 cleanup - runs daily at 2 AM
    try cron.schedule("0 2 * * *") { [weak self] in
      guard let self else { return }

      self.logger.info("Starting Magic Scanner S3 cleanup job")

      Task {
        do {
          let cutoffDate = Date().addingTimeInterval(-48 * 3600) // 48 hours ago
          let deletedCount = try await self.imageStorage.deleteOldImages(
            olderThan: cutoffDate,
            path: .magicScanner
          )
          self.logger.info("Magic Scanner S3 cleanup completed: deleted \(deletedCount) images")
        } catch {
          self.logger.error("Magic Scanner S3 cleanup failed: \(error)")
        }
      }
    }

    // Web domain classification - every 10 minutes, only while search is on.
    //
    // Domains are cited long before they are judged: a citation shows as soon as it clears the
    // deterministic checks and the seeded blocklist, and this decides whether it shows next time.
    // Deliberately behind the response rather than inside it - holding a reply while a model
    // judges a domain trades a real cost for a small one.
    if webSearchEnabled {
      try cron.schedule("*/10 * * * *") { [weak self] in
        guard let self else { return }

        Task {
          do {
            let classifier = WebDomainClassifier(
              openAIService: self.openAIService,
              logger: self.logger
            )
            let judged = try await classifier.classifyNextBatch(db: self.db)
            if judged > 0 {
              self.logger.info("Domain classification judged \(judged) domains")
            }
          } catch {
            self.logger.error("Domain classification failed: \(error)")
          }
        }
      }

      // Request-time blocklist refresh - every 15 minutes.
      //
      // Only the hundred domains OpenAI will accept. The full list stays in Postgres; putting it
      // in Redis would consume a third of a 25 MB instance running `noeviction`, where filling up
      // means writes start failing and chat streaming state goes with them.
      try cron.schedule("*/15 * * * *") { [weak self] in
        guard let self else { return }

        Task {
          let blocklist = WebDomainBlocklist(logger: self.logger)
          let domains = await blocklist.rebuild(db: self.db, redis: self.redis)
          self.logger.debug("Refreshed the request-time blocklist with \(domains.count) domains")
        }
      }
    }

    // Blocklist seed refresh - weekly, Sunday 3 AM. The public list gains entries constantly, and
    // a seed that only ran once at launch decays.
    if webSearchEnabled {
      try cron.schedule("0 3 * * 0") { [weak self] in
        guard let self else { return }

        Task {
          self.logger.info("Refreshing the seeded domain blocklist")
          // Re-imports on conflict-do-nothing, so anything already judged - especially by hand -
          // keeps its verdict.
          do {
            try await SeedWebDomainBlocklistCommand.importDefaultList(app: self, logger: self.logger)
          } catch {
            self.logger.error("Blocklist seed refresh failed: \(error)")
          }
        }
      }
    }

    let webSearchJobs = webSearchEnabled ? ", web-domain-classification (every 10 min), blocklist-refresh (every 15 min), blocklist-seed (weekly)" : ""
    self.logger.info("Configured cron jobs: duplicate-detection (every 4 hours), magic-scanner-cleanup (daily at 2 AM UTC)\(webSearchJobs)")
  }
}
