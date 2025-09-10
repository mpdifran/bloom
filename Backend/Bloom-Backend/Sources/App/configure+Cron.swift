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
    _ = try self.cron.schedule("0 */4 * * *") { [unowned self] in
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
    
    self.logger.info("Configured cron jobs: duplicate-detection (every 4 hours)")
  }
}
