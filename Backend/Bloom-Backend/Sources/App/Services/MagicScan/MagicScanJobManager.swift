//
//  MagicScanJobManager.swift
//  Bloom-Backend
//
//  Created by Claude on 2025-10-25.
//

import Foundation
import Vapor
import BloomModel
@preconcurrency import Redis
import Fluent
import APNS
import VaporAPNS
import APNSCore

struct MagicScanJob: Codable, Sendable {
  let userId: UserIdentifier
  let imageFileName: String?
  let contextText: String?
  let country: String?
  var status: String // "pending", "processing", "completed", "failed"
  var servingsJson: String?
  var errorMessage: String?
}

final actor MagicScanJobManager {

  init(redis: RedisClient, logger: Logger) {
    self.redis = redis
    self.logger = logger
  }

  private let redis: RedisClient
  private let logger: Logger
  private let encoder = JSONEncoder.bloomModel
  private let decoder = JSONDecoder.bloomModel

  // In-memory fallback storage
  private var fallbackJobs: [String: MagicScanJob] = [:]

  // Redis health tracking
  private var redisIsHealthy = true
  private var lastRedisFailure: Date?
  private let redisRetryInterval: TimeInterval = 30 // Retry Redis after 30 seconds

  // 48 hour TTL for jobs in Redis
  private let jobTTL: Int64 = 172800 // 48 hours in seconds
}

extension MagicScanJobManager {

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
      logger.info("Redis ping successful, syncing magic scan jobs before restoring connection...")
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
    logger.info("Syncing fallback magic scan jobs to Redis after connection restoration")

    for (processingIdentifier, job) in fallbackJobs {
      do {
        let key = RedisKey.magicScanJob(processingIdentifier: processingIdentifier)
        let jobData = try encoder.encode(job)
        _ = try await redis.set(key, to: jobData).get()
        _ = try await redis.expire(key, after: .seconds(jobTTL)).get()
      } catch {
        logger.error("Failed to sync magic scan job \(processingIdentifier): \(error)")
      }
    }

    logger.info("Completed syncing fallback magic scan jobs to Redis")
  }
}

extension MagicScanJobManager {

  // MARK: - Public Interface

  /// Creates a new magic scan job
  func createJob(
    processingIdentifier: AIFoodProcessingIdentifier,
    userId: UserIdentifier,
    imageFileName: String?,
    contextText: String?,
    country: String?
  ) async throws {
    let job = MagicScanJob(
      userId: userId,
      imageFileName: imageFileName,
      contextText: contextText,
      country: country,
      status: MagicScanStatus.pending.rawValue,
      servingsJson: nil,
      errorMessage: nil
    )

    let identifierValue = processingIdentifier.value

    // Always store in fallback as a mirror
    fallbackJobs[identifierValue] = job

    // Try to store in Redis if it's healthy
    if shouldTryRedis() {
      do {
        let key = RedisKey.magicScanJob(processingIdentifier: identifierValue)
        let jobData = try encoder.encode(job)
        _ = try await redis.set(key, to: jobData).get()
        _ = try await redis.expire(key, after: .seconds(jobTTL)).get()
        markRedisHealthy()
      } catch {
        markRedisUnhealthy(error)
      }
    }
  }

  /// Gets a magic scan job by processing identifier
  func getJob(
    processingIdentifier: AIFoodProcessingIdentifier
  ) async throws -> MagicScanJob? {
    let identifierValue = processingIdentifier.value

    // Test and restore Redis connection if needed, then try Redis
    if await testAndRestoreRedisConnection() {
      do {
        let key = RedisKey.magicScanJob(processingIdentifier: identifierValue)
        guard let jobData = try await redis.get(key).get().data else {
          // Fall back to in-memory storage
          return fallbackJobs[identifierValue]
        }
        let job = try decoder.decode(MagicScanJob.self, from: jobData)
        markRedisHealthy()
        return job
      } catch {
        markRedisUnhealthy(error)
      }
    }

    // Fall back to in-memory storage
    return fallbackJobs[identifierValue]
  }

  /// Cancels a magic scan job
  func cancelJob(
    processingIdentifier: AIFoodProcessingIdentifier
  ) async throws {
    try await updateJobStatus(
      processingIdentifier: processingIdentifier,
      status: MagicScanStatus.cancelled.rawValue
    )
  }

  /// Updates the status of a magic scan job
  func updateJobStatus(
    processingIdentifier: AIFoodProcessingIdentifier,
    status: String,
    servingsJson: String? = nil,
    errorMessage: String? = nil
  ) async throws {
    let identifierValue = processingIdentifier.value

    // Get existing job
    guard var job = try await getJob(processingIdentifier: processingIdentifier) else {
      logger.warning("Attempted to update non-existent job: \(identifierValue)")
      return
    }

    // Update job fields
    job.status = status
    if let servingsJson = servingsJson {
      job.servingsJson = servingsJson
    }
    if let errorMessage = errorMessage {
      job.errorMessage = errorMessage
    }

    // Always update in fallback
    fallbackJobs[identifierValue] = job

    // Try to update in Redis if it's healthy
    if shouldTryRedis() {
      do {
        let key = RedisKey.magicScanJob(processingIdentifier: identifierValue)
        let jobData = try encoder.encode(job)
        _ = try await redis.set(key, to: jobData).get()
        _ = try await redis.expire(key, after: .seconds(jobTTL)).get()
        markRedisHealthy()
      } catch {
        markRedisUnhealthy(error)
      }
    }
  }

  /// Processes a magic scan job in the background
  func processJob(
    processingIdentifier: AIFoodProcessingIdentifier,
    imageStorage: ImageStorage,
    openAIService: OpenAIService,
    foodDatabaseService: FoodDatabaseService,
    openFoodFactsService: OpenFoodFactsService,
    db: Database,
    application: Application
  ) async {
    do {
      // Get the job
      guard let job = try await getJob(processingIdentifier: processingIdentifier) else {
        logger.error("Job not found for processing: \(processingIdentifier.value)")
        return
      }

      // Check if job was cancelled before we start processing
      if job.status == MagicScanStatus.cancelled.rawValue {
        logger.info("Job was cancelled, skipping processing: \(processingIdentifier.value)")
        return
      }

      // Update status to processing
      try await updateJobStatus(
        processingIdentifier: processingIdentifier,
        status: MagicScanStatus.processing.rawValue
      )

      // Retrieve image from S3 if available
      let imageData: Data?
      if let imageFileName = job.imageFileName {
        guard let imageFile = try await imageStorage.retrieveImage(
          fileName: imageFileName,
          path: .magicScanner
        ) else {
          logger.error("Failed to retrieve image from S3: \(imageFileName)")
          try await updateJobStatus(
            processingIdentifier: processingIdentifier,
            status: MagicScanStatus.failed.rawValue,
            errorMessage: "Failed to retrieve image"
          )
          await sendPushNotification(
            processingIdentifier: processingIdentifier,
            userId: job.userId,
            db: db,
            application: application
          )
          return
        }
        imageData = imageFile.data
      } else {
        imageData = nil
      }

      // Check again if job was cancelled before expensive OpenAI call
      if let currentJob = try await getJob(processingIdentifier: processingIdentifier),
         currentJob.status == MagicScanStatus.cancelled.rawValue {
        logger.info("Job was cancelled, skipping OpenAI processing: \(processingIdentifier.value)")
        return
      }

      // PASS 1: Detect foods (names, brands, serving counts)
      let detection = try await openAIService.detectFoodsMagicScan(
        image: imageData,
        contextText: job.contextText
      )

      // Use country from request, or default to "usa"
      let preferredCountry = job.country ?? "usa"

      // DATABASE LOOKUP PHASE: Search for matches and attempt OpenFoodFacts imports
      var databaseMatches: [(food: OpenAIDetectFoodsResponse.DetectedFood, match: FoodItem)] = []
      var unknownFoods: [OpenAIDetectFoodsResponse.DetectedFood] = []

      for detectedFood in detection.foodItems {
        // Search database for this food
        let matches = try await foodDatabaseService.searchFoodsForMagicScan(
          query: detectedFood.name,
          brand: detectedFood.brandName,
          preferredCountry: preferredCountry
        )

        if let bestMatch = matches.first {
          logger.info("Found database match for '\(detectedFood.name)': \(bestMatch.foodItem.name)")
          databaseMatches.append((detectedFood, bestMatch.foodItem))
        } else if detectedFood.brandName != nil {
          // Try importing from OpenFoodFacts for brand-name products
          logger.info("Attempting OpenFoodFacts import for '\(detectedFood.name)' brand '\(detectedFood.brandName ?? "")'")
          let imported = try await openFoodFactsService.searchAndImportProduct(
            name: detectedFood.name,
            brand: detectedFood.brandName
          )

          if let importedItem = imported.first {
            logger.info("Successfully imported from OpenFoodFacts: \(importedItem.name)")
            databaseMatches.append((detectedFood, importedItem))
          } else {
            unknownFoods.append(detectedFood)
          }
        } else {
          unknownFoods.append(detectedFood)
        }
      }

      // PASS 2: Estimate nutrition only for unknowns
      var allServings: [MagicScanStatusResponse.Serving] = []

      // Add database matches as servings
      for (detectedFood, matchedItem) in databaseMatches {
        allServings.append(
          MagicScanStatusResponse.Serving(
            servings: detectedFood.servingCount,
            item: matchedItem
          )
        )
      }

      // Estimate nutrition for unknowns
      if !unknownFoods.isEmpty {
        logger.info("Estimating nutrition for \(unknownFoods.count) unknown foods")
        let estimatedServings = try await openAIService.estimateNutritionForUnknownFoods(
          image: imageData,
          contextText: job.contextText,
          unknownFoods: unknownFoods,
          databaseMatches: databaseMatches
        )
        allServings.append(contentsOf: estimatedServings)
      }

      logger.info("Magic scan results: \(databaseMatches.count) from database, \(unknownFoods.count) AI estimated")

      // Validate nutrition data
      let validator = MagicScanValidator(logger: logger)
      let validationWarnings = validator.validate(servings: allServings)
      if !validationWarnings.isEmpty {
        logger.warning("Validation found \(validationWarnings.count) potential issues with magic scan results")
      }

      // Convert servings to JSON
      let servingsData = try encoder.encode(allServings)
      let servingsJson = String(data: servingsData, encoding: .utf8)

      // Update job status to completed
      try await updateJobStatus(
        processingIdentifier: processingIdentifier,
        status: MagicScanStatus.completed.rawValue,
        servingsJson: servingsJson
      )

      // Send push notification
      await sendPushNotification(
        processingIdentifier: processingIdentifier,
        userId: job.userId,
        db: db,
        application: application
      )

      logger.info("Successfully processed magic scan job: \(processingIdentifier.value)")

    } catch {
      logger.error("Error processing magic scan job \(processingIdentifier.value): \(error)")

      // Update job status to failed
      try? await updateJobStatus(
        processingIdentifier: processingIdentifier,
        status: MagicScanStatus.failed.rawValue,
        errorMessage: error.localizedDescription
      )

      // Send push notification about failure
      if let job = try? await getJob(processingIdentifier: processingIdentifier) {
        await sendPushNotification(
          processingIdentifier: processingIdentifier,
          userId: job.userId,
          db: db,
          application: application
        )
      }
    }
  }

  /// Sends a silent push notification for magic scan completion
  private func sendPushNotification(
    processingIdentifier: AIFoodProcessingIdentifier,
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

      // Create payload for magic scan completion
      let payload = MagicScanCompleteTrigger(
        processingIdentifier: processingIdentifier.value
      )

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
        logger.debug("Sent magic scan notification to user \(userId): \(apnsUniqueID)")
      }
    } catch {
      logger.error("Failed to send magic scan push notification: \(error)")
    }
  }
}

private extension RedisKey {

  static func magicScanJob(processingIdentifier: String) -> RedisKey {
    RedisKey("magic_scan:\(processingIdentifier)")
  }
}
