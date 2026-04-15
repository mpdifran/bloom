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

    // MailerLite email sync - runs daily at 3 AM ET (7 AM UTC)
    try cron.schedule("0 7 * * *") { [weak self] in
      guard let self else { return }

      self.logger.info("Starting MailerLite email sync job")

      guard let apiKey = self.mailerLiteAPIKey else {
        self.logger.warning("MAILERLITE_API_KEY not configured, skipping email sync")
        return
      }

      let mailerLiteService = MailerLiteService(
        client: self.client,
        db: self.db,
        logger: self.logger,
        apiKey: apiKey
      )

      Task {
        do {
          try await mailerLiteService.syncAllSubscribers()
          self.logger.info("MailerLite email sync job completed successfully")
        } catch {
          self.logger.error("MailerLite email sync job failed: \(error)")
        }
      }
    }

    self.logger.info("Configured cron jobs: duplicate-detection (every 4 hours), magic-scanner-cleanup (daily at 2 AM UTC), mailerlite-sync (daily at 3 AM ET / 7 AM UTC)")
  }
}
