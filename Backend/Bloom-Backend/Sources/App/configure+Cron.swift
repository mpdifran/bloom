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
    // Schedule morning report notifications every 5 minutes
    try cron.schedule("*/5 * * * *") { [weak self] in
      guard let self = self else { return }
      
      Task {
        do {
          self.logger.info("Running morning report notification job")
          try await self.notificationService.sendMorningReportNotifications(db: self.db)
        } catch {
          self.logger.error("Failed to run morning report notification job: \(error)")
        }
      }
    }
    
    logger.info("Configured cron jobs")
  }
}
