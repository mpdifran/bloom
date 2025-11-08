//
//  ImageResizeMigration.swift
//  Bloom
//
//  Created by Claude on 2025-08-08.
//

import Foundation
import SwiftUI
import SwiftData
import DataContainer
import BloomFoundation

final class ImageResizeMigration {
  static let shared = ImageResizeMigration()

  private let targetWidth: CGFloat = 300
  private let batchSize = 10
  private let maxBatchesPerRun = 2

  @Storage(key: "imageResizeMigrationCompleted", defaultValue: false)
  private var migrationCompleted: Bool
  
  @Storage(key: "lastCompletedFoodLogTimestamp", defaultValue: 0.0)
  private var lastCompletedFoodLogTimestamp: TimeInterval
  
  @Storage(key: "lastCompletedMealTimestamp", defaultValue: 0.0) 
  private var lastCompletedMealTimestamp: TimeInterval
  
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
  
  private var lastCompletedMealDate: Date? {
    get { 
      lastCompletedMealTimestamp == 0.0 ? nil : Date(timeIntervalSince1970: lastCompletedMealTimestamp)
    }
    set { 
      Task { @MainActor in
        lastCompletedMealTimestamp = newValue?.timeIntervalSince1970 ?? 0.0
      }
    }
  }

  private init() {}

  @MainActor
  func runMigrationIfNeeded() {
    print("ImageResizeMigration: runMigrationIfNeeded called - migrationCompleted: \(migrationCompleted)")
    guard !migrationCompleted else { 
      print("ImageResizeMigration: Skipping - already completed")
      return 
    }

    Task.detached { [weak self] in
      await self?.performMigration()
    }
  }
  
  @MainActor
  func resetMigration() {
    print("ImageResizeMigration: Resetting migration flag and cursors")
    migrationCompleted = false
    lastCompletedFoodLogTimestamp = 0.0
    lastCompletedMealTimestamp = 0.0
  }
  
  func forceMigration() async {
    print("ImageResizeMigration: Force migration triggered")
    await performMigration()
  }

  nonisolated private func performMigration() async {
    print("ImageResizeMigration: Starting migration")
    let modelContext = ModelContext(ContainerHolder.shared.container)

    do {
      var totalImagesResized = 0
      
      // Process FoodItemLog records first
      print("ImageResizeMigration: Processing FoodItemLog records")
      var foodLogBatchCount = 0
      while foodLogBatchCount < maxBatchesPerRun {
        let (hasMore, imagesResized) = try await processFoodItemLogs(modelContext: modelContext)
        totalImagesResized += imagesResized
        foodLogBatchCount += 1
        
        print("ImageResizeMigration: FoodLog batch \(foodLogBatchCount) - resized \(imagesResized) images")
        
        if !hasMore {
          print("ImageResizeMigration: No more FoodItemLogs to process")
          break
        }
      }
      
      // Process MealRecord records
      print("ImageResizeMigration: Processing MealRecord records")
      var mealBatchCount = 0
      let remainingBatches = maxBatchesPerRun - foodLogBatchCount
      while mealBatchCount < remainingBatches {
        let (hasMore, imagesResized) = try await processMealRecords(modelContext: modelContext)
        totalImagesResized += imagesResized
        mealBatchCount += 1
        
        print("ImageResizeMigration: Meal batch \(mealBatchCount) - resized \(imagesResized) images")
        
        if !hasMore {
          print("ImageResizeMigration: No more MealRecords to process")
          break
        }
      }

      // Log total progress
      print("ImageResizeMigration: Total images resized in this run: \(totalImagesResized)")

      // Simple completion logic: if both food logs and meals returned empty batches, we're done
      let foodLogsExhausted = foodLogBatchCount > 0 && foodLogBatchCount < maxBatchesPerRun
      let mealsExhausted = mealBatchCount >= 0 // meals might finish quickly since there are fewer
      let noMoreWork = foodLogsExhausted && totalImagesResized == 0
      
      // Update completion flag on main thread
      await MainActor.run {
        if noMoreWork {
          migrationCompleted = true
          print("ImageResizeMigration: COMPLETED - No images found to resize")
        } else {
          print("ImageResizeMigration: More work may remain - will continue on next run")
        }
      }
    } catch {
      print("ImageResizeMigration: ERROR - \(error)")
    }
  }
  

  private func processFoodItemLogs(modelContext: ModelContext) async throws -> (hasMore: Bool, imagesResized: Int) {
    let startDate = lastCompletedFoodLogDate ?? Date(timeIntervalSince1970: 0)
    print("ImageResizeMigration: FoodLog - fetching from date: \(startDate)")
    
    let descriptor = FetchDescriptor<FoodItemLog>(
      predicate: #Predicate { log in
        log.imageData != nil && log.date > startDate
      },
      sortBy: [SortDescriptor(\.date)]
    )

    var fetchDescriptor = descriptor
    fetchDescriptor.fetchLimit = batchSize

    let logs = try modelContext.fetch(fetchDescriptor)
    var imagesResized = 0
    
    print("ImageResizeMigration: FoodLog - processing \(logs.count) logs")

    for log in logs {
      // Yield control periodically to prevent blocking
      await Task.yield()
      
      guard let imageData = log.imageData,
            let image = UIImage(data: imageData) else { 
        print("ImageResizeMigration: FoodLog - no image data or failed to create UIImage")
        continue 
      }

      print("ImageResizeMigration: FoodLog - image size: \(image.size.width) x \(image.size.height)")
      
      // Check if image needs resizing
      if image.size.width > targetWidth {
        print("ImageResizeMigration: FoodLog - resizing image from \(image.size.width)px to \(targetWidth)px")
        
        // Resize the image (heavy work)
        if let resizedImage = image.resized(toWidth: targetWidth),
           let resizedData = resizedImage.jpegData(compressionQuality: 0.75) {
          let originalSize = imageData.count
          let newSize = resizedData.count
          print("ImageResizeMigration: FoodLog - resized from \(originalSize) bytes to \(newSize) bytes")
          
          log.imageData = resizedData
          imagesResized += 1
          
          // Yield after heavy image processing
          await Task.yield()
        } else {
          print("ImageResizeMigration: FoodLog - FAILED to resize image")
        }
      } else {
        print("ImageResizeMigration: FoodLog - image already small enough (\(image.size.width)px)")
      }
    }

    // Save if we made changes
    if imagesResized > 0 {
      print("ImageResizeMigration: FoodLog - saving \(imagesResized) resized images")
      try modelContext.save()
    }
    
    // Update cursor to the latest complete date
    await updateFoodLogCursor(processedLogs: logs, modelContext: modelContext)

    // Return true if there might be more logs to process
    let hasMore = logs.count == batchSize
    print("ImageResizeMigration: FoodLog - batch complete. HasMore: \(hasMore), ImagesResized: \(imagesResized)")
    return (hasMore, imagesResized)
  }

  private func processMealRecords(modelContext: ModelContext) async throws -> (hasMore: Bool, imagesResized: Int) {
    let startDate = lastCompletedMealDate ?? Date(timeIntervalSince1970: 0)
    print("ImageResizeMigration: Meal - fetching from date: \(startDate)")
    
    // Note: MealRecords don't have date property, so we'll use creation order via name for now
    // This is not ideal but meals are typically fewer in number
    let descriptor = FetchDescriptor<MealRecord>(
      predicate: #Predicate { meal in
        meal.imageData != nil
      },
      sortBy: [SortDescriptor(\.name)]
    )

    var fetchDescriptor = descriptor
    fetchDescriptor.fetchLimit = batchSize

    let meals = try modelContext.fetch(fetchDescriptor)
    var imagesResized = 0

    for meal in meals {
      // Yield control periodically to prevent blocking
      await Task.yield()
      
      guard let imageData = meal.imageData,
            let image = UIImage(data: imageData) else { continue }

      // Check if image needs resizing
      if image.size.width > targetWidth {
        // Resize the image (heavy work)
        if let resizedImage = image.resized(toWidth: targetWidth),
           let resizedData = resizedImage.jpegData(compressionQuality: 0.75) {
          meal.imageData = resizedData
          imagesResized += 1
          
          // Yield after heavy image processing
          await Task.yield()
        }
      }
    }

    // Save if we made changes
    if imagesResized > 0 {
      try modelContext.save()
    }

    // Return true if there might be more meals to process
    return (meals.count == batchSize, imagesResized)
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
        print("ImageResizeMigration: FoodLog cursor advanced to \(date)")
      } else {
        // Still logs remaining for this date, don't advance past it
        let remainingCount = remainingLogsForDate ?? -1
        print("ImageResizeMigration: FoodLog cursor NOT advanced - \(remainingCount) logs remain for \(date)")
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
    let largeImages = logsForDate.filter { log in
      guard let imageData = log.imageData,
            let image = UIImage(data: imageData) else { return false }
      return image.size.width > targetWidth
    }
    
    return largeImages.count
  }
}
