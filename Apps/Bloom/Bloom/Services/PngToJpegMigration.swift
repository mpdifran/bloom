//
//  PngToJpegMigration.swift
//  Bloom
//
//  Created by Claude on 2025-11-07.
//

import Foundation
import SwiftUI
import SwiftData
import DataContainer
import BloomFoundation

final class PngToJpegMigration {
  static let shared = PngToJpegMigration()

  private let jpegQuality: CGFloat = 0.75
  private let batchSize = 10

  @Storage(key: "pngToJpegMigrationCompleted", defaultValue: false)
  private var migrationCompleted: Bool

  @Storage(key: "pngToJpeg_lastCompletedFoodLogTimestamp", defaultValue: 0.0)
  private var lastCompletedFoodLogTimestamp: TimeInterval

  @Storage(key: "pngToJpeg_lastCompletedChatMessageTimestamp", defaultValue: 0.0)
  private var lastCompletedChatMessageTimestamp: TimeInterval

  private var lastCompletedFoodLogDate: Date? {
    get {
      lastCompletedFoodLogTimestamp == 0.0 ? nil : Date(timeIntervalSince1970: lastCompletedFoodLogTimestamp)
    }
    set {
      Task { @MainActor in
        lastCompletedFoodLogTimestamp = newValue?.timeIntervalSince1970 ?? 0.0
      }
    }
  }

  private var lastCompletedChatMessageDate: Date? {
    get {
      lastCompletedChatMessageTimestamp == 0.0 ? nil : Date(timeIntervalSince1970: lastCompletedChatMessageTimestamp)
    }
    set {
      Task { @MainActor in
        lastCompletedChatMessageTimestamp = newValue?.timeIntervalSince1970 ?? 0.0
      }
    }
  }

  private init() {}

  @MainActor
  func runMigrationIfNeeded() {
    print("PngToJpegMigration: runMigrationIfNeeded called - migrationCompleted: \(migrationCompleted)")
    guard !migrationCompleted else {
      print("PngToJpegMigration: Skipping - already completed")
      return
    }

    Task.detached { [weak self] in
      await self?.performMigration()
    }
  }

  @MainActor
  func resetMigration() {
    print("PngToJpegMigration: Resetting migration flag and cursors")
    migrationCompleted = false
    lastCompletedFoodLogTimestamp = 0.0
    lastCompletedChatMessageTimestamp = 0.0
  }

  func forceMigration() async {
    print("PngToJpegMigration: Force migration triggered")
    await performMigration()
  }

  nonisolated private func performMigration() async {
    print("PngToJpegMigration: Starting migration - processing all types in parallel")
    let modelContext = ModelContext(ContainerHolder.shared.container)

    do {
      // Process all three types concurrently using async let
      async let foodLogResult = processFoodItemLogs(modelContext: modelContext)
      async let mealResult = processMealRecords(modelContext: modelContext)
      async let chatResult = processChatMessages(modelContext: modelContext)

      // Wait for all three to complete
      let ((foodLogHasMore, foodLogConverted), (mealHasMore, mealConverted), (chatHasMore, chatConverted)) = try await (foodLogResult, mealResult, chatResult)

      // Log results
      let totalImagesConverted = foodLogConverted + mealConverted + chatConverted
      print("PngToJpegMigration: Batch complete - FoodLog: \(foodLogConverted), Meal: \(mealConverted), Chat: \(chatConverted)")
      print("PngToJpegMigration: Total images converted in this run: \(totalImagesConverted)")

      // Migration is complete when all three types have no more work
      let allTypesExhausted = !foodLogHasMore && !mealHasMore && !chatHasMore

      // Update completion flag on main thread
      await MainActor.run {
        if allTypesExhausted {
          migrationCompleted = true
          print("PngToJpegMigration: COMPLETED - All image types fully converted")
        } else {
          print("PngToJpegMigration: More work remains - will continue on next run")
        }
      }
    } catch {
      print("PngToJpegMigration: ERROR - \(error)")
    }
  }


  private func processFoodItemLogs(modelContext: ModelContext) async throws -> (hasMore: Bool, imagesConverted: Int) {
    let startDate = lastCompletedFoodLogDate ?? Date(timeIntervalSince1970: 0)
    print("PngToJpegMigration: FoodLog - fetching from date: \(startDate)")

    let descriptor = FetchDescriptor<FoodItemLog>(
      predicate: #Predicate { log in
        log.imageData != nil && log.date > startDate
      },
      sortBy: [SortDescriptor(\.date)]
    )

    var fetchDescriptor = descriptor
    fetchDescriptor.fetchLimit = batchSize

    let logs = try modelContext.fetch(fetchDescriptor)
    var imagesConverted = 0

    print("PngToJpegMigration: FoodLog - processing \(logs.count) logs")

    for log in logs {
      // Yield control periodically to prevent blocking
      await Task.yield()

      guard let imageData = log.imageData,
            let image = UIImage(data: imageData) else {
        print("PngToJpegMigration: FoodLog - no image data or failed to create UIImage")
        continue
      }

      // Try converting to JPEG - if it's smaller, it was likely PNG
      if let jpegData = image.jpegData(compressionQuality: jpegQuality),
         jpegData.count < imageData.count {
        let originalSize = imageData.count
        let newSize = jpegData.count
        let savingsPercent = Int((1.0 - Double(newSize) / Double(originalSize)) * 100)

        // Only convert if we save at least 10% - avoids re-compressing JPEGs
        if savingsPercent >= 10 {
          print("PngToJpegMigration: FoodLog - converted from \(originalSize) bytes to \(newSize) bytes (\(savingsPercent)% smaller)")

          log.imageData = jpegData
          imagesConverted += 1

          // Yield after heavy image processing
          await Task.yield()
        } else {
          print("PngToJpegMigration: FoodLog - image already JPEG - skipping (only \(savingsPercent)% savings)")
        }
      } else {
        print("PngToJpegMigration: FoodLog - image already JPEG or conversion not beneficial")
      }
    }

    // Save if we made changes
    if imagesConverted > 0 {
      print("PngToJpegMigration: FoodLog - saving \(imagesConverted) converted images")
      try modelContext.save()
    }

    // Update cursor to the latest complete date
    await updateFoodLogCursor(processedLogs: logs, modelContext: modelContext)

    // Return true if there might be more logs to process
    let hasMore = logs.count == batchSize
    print("PngToJpegMigration: FoodLog - batch complete. HasMore: \(hasMore), ImagesConverted: \(imagesConverted)")
    return (hasMore, imagesConverted)
  }

  private func processMealRecords(modelContext: ModelContext) async throws -> (hasMore: Bool, imagesConverted: Int) {
    // MealRecords are saved meal templates (not individual food logs), so there are typically
    // only a handful. We process all of them in one pass since there's no date field for cursors.
    let descriptor = FetchDescriptor<MealRecord>(
      predicate: #Predicate { meal in
        meal.imageData != nil
      },
      sortBy: [SortDescriptor(\.name)]
    )

    let meals = try modelContext.fetch(descriptor)
    var imagesConverted = 0

    print("PngToJpegMigration: Meal - processing \(meals.count) saved meals")

    for meal in meals {
      // Yield control periodically to prevent blocking
      await Task.yield()

      guard let imageData = meal.imageData,
            let image = UIImage(data: imageData) else { continue }

      // Try converting to JPEG - if it's smaller, it was likely PNG
      if let jpegData = image.jpegData(compressionQuality: jpegQuality),
         jpegData.count < imageData.count {
        let originalSize = imageData.count
        let newSize = jpegData.count
        let savingsPercent = Int((1.0 - Double(newSize) / Double(originalSize)) * 100)

        // Only convert if we save at least 10% - avoids re-compressing JPEGs
        if savingsPercent >= 10 {
          print("PngToJpegMigration: Meal - converted from \(originalSize) bytes to \(newSize) bytes (\(savingsPercent)% smaller)")

          meal.imageData = jpegData
          imagesConverted += 1

          // Yield after heavy image processing
          await Task.yield()
        } else {
          print("PngToJpegMigration: Meal - image already JPEG - skipping (only \(savingsPercent)% savings)")
        }
      }
    }

    // Save if we made changes
    if imagesConverted > 0 {
      print("PngToJpegMigration: Meal - saving \(imagesConverted) converted images")
      try modelContext.save()
    }

    // All saved meals processed in one pass - no more work remains
    print("PngToJpegMigration: Meal - complete. ImagesConverted: \(imagesConverted)")
    return (false, imagesConverted)
  }

  private func processChatMessages(modelContext: ModelContext) async throws -> (hasMore: Bool, imagesConverted: Int) {
    let startDate = lastCompletedChatMessageDate ?? Date(timeIntervalSince1970: 0)
    print("PngToJpegMigration: ChatMessage - fetching from date: \(startDate)")

    let descriptor = FetchDescriptor<ChatMessage>(
      predicate: #Predicate { message in
        message.imageData != nil && message.date > startDate
      },
      sortBy: [SortDescriptor(\.date)]
    )

    var fetchDescriptor = descriptor
    fetchDescriptor.fetchLimit = batchSize

    let messages = try modelContext.fetch(fetchDescriptor)
    var imagesConverted = 0

    print("PngToJpegMigration: ChatMessage - processing \(messages.count) messages")

    for message in messages {
      // Yield control periodically to prevent blocking
      await Task.yield()

      guard let imageData = message.imageData,
            let image = UIImage(data: imageData) else {
        print("PngToJpegMigration: ChatMessage - no image data or failed to create UIImage")
        continue
      }

      // Try converting to JPEG - if it's smaller, it was likely PNG
      if let jpegData = image.jpegData(compressionQuality: jpegQuality),
         jpegData.count < imageData.count {
        let originalSize = imageData.count
        let newSize = jpegData.count
        let savingsPercent = Int((1.0 - Double(newSize) / Double(originalSize)) * 100)

        // Only convert if we save at least 10% - avoids re-compressing JPEGs
        if savingsPercent >= 10 {
          print("PngToJpegMigration: ChatMessage - converted from \(originalSize) bytes to \(newSize) bytes (\(savingsPercent)% smaller)")

          message.imageData = jpegData
          imagesConverted += 1

          // Yield after heavy image processing
          await Task.yield()
        } else {
          print("PngToJpegMigration: ChatMessage - image already JPEG - skipping (only \(savingsPercent)% savings)")
        }
      } else {
        print("PngToJpegMigration: ChatMessage - image already JPEG or conversion not beneficial")
      }
    }

    // Save if we made changes
    if imagesConverted > 0 {
      print("PngToJpegMigration: ChatMessage - saving \(imagesConverted) converted images")
      try modelContext.save()
    }

    // Update cursor to the latest complete date
    await updateChatMessageCursor(processedMessages: messages, modelContext: modelContext)

    // Return true if there might be more messages to process
    let hasMore = messages.count == batchSize
    print("PngToJpegMigration: ChatMessage - batch complete. HasMore: \(hasMore), ImagesConverted: \(imagesConverted)")
    return (hasMore, imagesConverted)
  }

  // MARK: - Cursor Management

  private func updateFoodLogCursor(processedLogs: [FoodItemLog], modelContext: ModelContext) async {
    guard !processedLogs.isEmpty else { return }

    // Find all unique dates in processed logs
    let processedDates = Set(processedLogs.map { Calendar.current.startOfDay(for: $0.date) })
    let sortedDates = processedDates.sorted()

    // For each date, check if we've processed ALL logs for that day
    for date in sortedDates {
      let remainingLogsForDate = try? await countRemainingFoodLogsForDate(date: date, modelContext: modelContext)

      if let remaining = remainingLogsForDate, remaining == 0 {
        // All logs for this date are processed, safe to advance cursor
        lastCompletedFoodLogDate = date
        print("PngToJpegMigration: FoodLog cursor advanced to \(date)")
      } else {
        // Still logs remaining for this date, don't advance past it
        let remainingCount = remainingLogsForDate ?? -1
        print("PngToJpegMigration: FoodLog cursor NOT advanced - \(remainingCount) logs remain for \(date)")
        break
      }
    }
  }

  private func countRemainingFoodLogsForDate(date: Date, modelContext: ModelContext) async throws -> Int {
    let startOfDay = Calendar.current.startOfDay(for: date)
    let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

    let descriptor = FetchDescriptor<FoodItemLog>(
      predicate: #Predicate { log in
        log.imageData != nil && log.date >= startOfDay && log.date < endOfDay
      }
    )

    let logsForDate = try modelContext.fetch(descriptor)

    // Count images that would benefit from PNG to JPEG conversion (≥10% savings)
    var pngImageCount = 0
    for log in logsForDate {
      guard let imageData = log.imageData,
            let image = UIImage(data: imageData),
            let jpegData = image.jpegData(compressionQuality: jpegQuality) else { continue }

      let originalSize = Double(imageData.count)
      let newSize = Double(jpegData.count)
      let savingsPercent = Int((1.0 - newSize / originalSize) * 100)

      if savingsPercent >= 10 {
        pngImageCount += 1
      }
    }

    return pngImageCount
  }

  private func updateChatMessageCursor(processedMessages: [ChatMessage], modelContext: ModelContext) async {
    guard !processedMessages.isEmpty else { return }

    // Find all unique dates in processed messages
    let processedDates = Set(processedMessages.map { Calendar.current.startOfDay(for: $0.date) })
    let sortedDates = processedDates.sorted()

    // For each date, check if we've processed ALL messages for that day
    for date in sortedDates {
      let remainingMessagesForDate = try? await countRemainingChatMessagesForDate(date: date, modelContext: modelContext)

      if let remaining = remainingMessagesForDate, remaining == 0 {
        // All messages for this date are processed, safe to advance cursor
        lastCompletedChatMessageDate = date
        print("PngToJpegMigration: ChatMessage cursor advanced to \(date)")
      } else {
        // Still messages remaining for this date, don't advance past it
        let remainingCount = remainingMessagesForDate ?? -1
        print("PngToJpegMigration: ChatMessage cursor NOT advanced - \(remainingCount) messages remain for \(date)")
        break
      }
    }
  }

  private func countRemainingChatMessagesForDate(date: Date, modelContext: ModelContext) async throws -> Int {
    let startOfDay = Calendar.current.startOfDay(for: date)
    let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

    let descriptor = FetchDescriptor<ChatMessage>(
      predicate: #Predicate { message in
        message.imageData != nil && message.date >= startOfDay && message.date < endOfDay
      }
    )

    let messagesForDate = try modelContext.fetch(descriptor)

    // Count images that would benefit from PNG to JPEG conversion (≥10% savings)
    var pngImageCount = 0
    for message in messagesForDate {
      guard let imageData = message.imageData,
            let image = UIImage(data: imageData),
            let jpegData = image.jpegData(compressionQuality: jpegQuality) else { continue }

      let originalSize = Double(imageData.count)
      let newSize = Double(jpegData.count)
      let savingsPercent = Int((1.0 - newSize / originalSize) * 100)

      if savingsPercent >= 10 {
        pngImageCount += 1
      }
    }

    return pngImageCount
  }
}
