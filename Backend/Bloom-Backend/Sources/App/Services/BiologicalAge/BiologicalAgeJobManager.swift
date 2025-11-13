//
//  BiologicalAgeJobManager.swift
//  Bloom-Backend
//
//  Created by Claude Code
//

import Foundation
import Vapor
import BloomModel
@preconcurrency import Redis
import Fluent
import APNS
import VaporAPNS
import APNSCore

struct BiologicalAgeJob: Codable, Sendable {
  let userId: UserIdentifier
  let healthContext: String
  let currentAge: Int?
  let lastBiologicalAge: Double?
  var status: String // "pending", "processing", "completed", "failed"
  var resultJson: String?
  var errorMessage: String?
}

final actor BiologicalAgeJobManager {

  init(redis: RedisClient, logger: Logger) {
    self.redis = redis
    self.logger = logger
  }

  private let redis: RedisClient
  private let logger: Logger
  private let encoder = JSONEncoder.bloomModel
  private let decoder = JSONDecoder.bloomModel

  // In-memory fallback storage
  private var fallbackJobs: [String: BiologicalAgeJob] = [:]

  // Redis health tracking
  private var redisIsHealthy = true
  private var lastRedisFailure: Date?
  private let redisRetryInterval: TimeInterval = 30 // Retry Redis after 30 seconds

  // 48 hour TTL for jobs in Redis
  private let jobTTL: Int64 = 172800 // 48 hours in seconds
}

extension BiologicalAgeJobManager {

  // MARK: - Redis Health Management

  private func markRedisUnhealthy(_ error: Error) {
    redisIsHealthy = false
    lastRedisFailure = Date()
    logger.error("Redis operation failed, falling back to in-memory storage: \(error)")
  }

  private func shouldTryRedis() -> Bool {
    guard !redisIsHealthy else { return true }
    guard let lastFailure = lastRedisFailure else { return true }

    // Retry Redis after the retry interval
    return Date().timeIntervalSince(lastFailure) >= redisRetryInterval
  }

  private func testAndRestoreRedisConnection() async -> Bool {
    guard !redisIsHealthy else { return true }
    guard shouldTryRedis() else { return false }

    do {
      // Test Redis connection with a simple ping
      _ = try await redis.ping().get()

      // If ping succeeds, sync data before marking healthy
      logger.info("Redis ping successful, syncing biological age jobs before restoring connection...")
      await syncFallbackDataToRedis()

      // Mark as healthy only after sync completes
      redisIsHealthy = true
      lastRedisFailure = nil
      logger.info("Redis connection restored and synced")

      return true
    } catch {
      markRedisUnhealthy(error)
      return false
    }
  }

  private func markRedisHealthy() {
    if !redisIsHealthy {
      redisIsHealthy = true
      lastRedisFailure = nil
    }
  }

  private func syncFallbackDataToRedis() async {
    logger.info("Syncing fallback biological age jobs to Redis after connection restoration")

    for (userIdValue, job) in fallbackJobs {
      do {
        let key = RedisKey.biologicalAgeJob(userId: userIdValue)
        let jobData = try encoder.encode(job)
        _ = try await redis.set(key, to: jobData).get()
        _ = try await redis.expire(key, after: .seconds(jobTTL)).get()
      } catch {
        logger.error("Failed to sync biological age job for user \(userIdValue): \(error)")
      }
    }

    logger.info("Completed syncing fallback biological age jobs to Redis")
  }
}

extension BiologicalAgeJobManager {

  // MARK: - Public Interface

  /// Creates a new biological age calculation job
  func createJob(
    userId: UserIdentifier,
    healthContext: String,
    currentAge: Int?,
    lastBiologicalAge: Double?
  ) async throws {
    let job = BiologicalAgeJob(
      userId: userId,
      healthContext: healthContext,
      currentAge: currentAge,
      lastBiologicalAge: lastBiologicalAge,
      status: BiologicalAgeStatus.pending.rawValue,
      resultJson: nil,
      errorMessage: nil
    )

    let userIdValue = userId.value

    // Always store in fallback as a mirror
    fallbackJobs[userIdValue] = job

    // Try to store in Redis if it's healthy
    if shouldTryRedis() {
      do {
        let key = RedisKey.biologicalAgeJob(userId: userIdValue)
        let jobData = try encoder.encode(job)
        _ = try await redis.set(key, to: jobData).get()
        _ = try await redis.expire(key, after: .seconds(jobTTL)).get()
        markRedisHealthy()
      } catch {
        markRedisUnhealthy(error)
      }
    }
  }

  /// Gets a biological age job by user ID
  func getJob(userId: UserIdentifier) async throws -> BiologicalAgeJob? {
    let userIdValue = userId.value

    // Test and restore Redis connection if needed, then try Redis
    if await testAndRestoreRedisConnection() {
      do {
        let key = RedisKey.biologicalAgeJob(userId: userIdValue)
        guard let jobData = try await redis.get(key).get().data else {
          // Fall back to in-memory storage
          return fallbackJobs[userIdValue]
        }
        let job = try decoder.decode(BiologicalAgeJob.self, from: jobData)
        markRedisHealthy()
        return job
      } catch {
        markRedisUnhealthy(error)
      }
    }

    // Fall back to in-memory storage
    return fallbackJobs[userIdValue]
  }

  /// Updates the status of a biological age job
  func updateJobStatus(
    userId: UserIdentifier,
    status: String,
    resultJson: String? = nil,
    errorMessage: String? = nil
  ) async throws {
    let userIdValue = userId.value

    // Get existing job
    guard var job = try await getJob(userId: userId) else {
      logger.warning("Attempted to update non-existent job for user: \(userIdValue)")
      return
    }

    // Update job fields
    job.status = status
    if let resultJson = resultJson {
      job.resultJson = resultJson
    }
    if let errorMessage = errorMessage {
      job.errorMessage = errorMessage
    }

    // Always update in fallback
    fallbackJobs[userIdValue] = job

    // Try to update in Redis if it's healthy
    if shouldTryRedis() {
      do {
        let key = RedisKey.biologicalAgeJob(userId: userIdValue)
        let jobData = try encoder.encode(job)
        _ = try await redis.set(key, to: jobData).get()
        _ = try await redis.expire(key, after: .seconds(jobTTL)).get()
        markRedisHealthy()
      } catch {
        markRedisUnhealthy(error)
      }
    }
  }

  /// Processes a biological age calculation job in the background
  func processJob(
    userId: UserIdentifier,
    healthReportService: HealthReportService,
    db: Database,
    application: Application
  ) async {
    do {
      // Get the job
      guard let job = try await getJob(userId: userId) else {
        logger.error("Job not found for processing for user: \(userId)")
        return
      }

      // Update status to processing
      try await updateJobStatus(
        userId: userId,
        status: BiologicalAgeStatus.processing.rawValue
      )

      // Calculate biological age using HealthReportService
      let result = try await healthReportService.calculateBiologicalAge(
        healthContext: job.healthContext,
        currentAge: job.currentAge,
        lastBiologicalAge: job.lastBiologicalAge,
        userID: userId
      )

      // Convert result to JSON
      let resultData = try encoder.encode(result)
      let resultJson = String(data: resultData, encoding: .utf8)

      // Update job status to completed
      try await updateJobStatus(
        userId: userId,
        status: BiologicalAgeStatus.completed.rawValue,
        resultJson: resultJson
      )

      // Send push notification
      await sendPushNotification(
        userId: userId,
        db: db,
        application: application
      )

      logger.info("Successfully processed biological age job for user: \(userId)")

    } catch {
      logger.error("Error processing biological age job for user \(userId): \(error)")

      // Update job status to failed
      try? await updateJobStatus(
        userId: userId,
        status: BiologicalAgeStatus.failed.rawValue,
        errorMessage: error.localizedDescription
      )

      // Send push notification about failure
      await sendPushNotification(
        userId: userId,
        db: db,
        application: application
      )
    }
  }

  /// Sends a silent push notification for biological age calculation completion
  private func sendPushNotification(
    userId: UserIdentifier,
    db: Database,
    application: Application
  ) async {
    do {
      // Query user to get device token
      guard let user = try await User.find(userId, on: db),
            let deviceToken = user.apnsDeviceToken else {
        logger.warning("No device token found for user \(userId)")
        return
      }

      let expirationTime = Int(Date().addingTimeInterval(3600).timeIntervalSince1970)
      let expiration = APNSNotificationExpiration.timeIntervalSince1970InSeconds(expirationTime)
      let priority = APNSPriority.immediately
      let topic = application.bloomAppBundleID

      // Create payload for biological age completion
      let payload = BiologicalAgeCompleteTrigger()

      let silentNotification = APNSBackgroundNotification(
        expiration: expiration,
        topic: topic,
        payload: payload
      )

      let result = try await application.apns.client.send(
        APNSRequest(
          message: silentNotification,
          deviceToken: deviceToken,
          pushType: .background,
          expiration: expiration,
          priority: priority,
          apnsID: nil,
          topic: topic,
          collapseID: nil
        )
      )

      if let apnsUniqueID = result.apnsUniqueID {
        logger.debug("Sent biological age notification to user \(userId): \(apnsUniqueID)")
      }
    } catch {
      logger.error("Failed to send biological age push notification: \(error)")
    }
  }
}

private extension RedisKey {

  static func biologicalAgeJob(userId: String) -> RedisKey {
    RedisKey("biological_age:\(userId)")
  }
}
