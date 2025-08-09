//
//  StorageAnalyzer.swift
//  Bloom
//
//  Created by Claude on 2025-08-08.
//

import Foundation
import SwiftUI
import SwiftData
import DataContainer

struct StorageCategory {
  let name: String
  let size: Int64
  let itemCount: Int
  let details: String?
}

@MainActor
final class StorageAnalyzer: ObservableObject {
  @Published var categories: [StorageCategory] = []
  @Published var isAnalyzing = false
  @Published var totalStorageSize: Int64 = 0

  func analyzeStorage() async {
    isAnalyzing = true
    defer { isAnalyzing = false }

    var results: [StorageCategory] = []

    // Analyze SwiftData models
    let modelContext = ModelContext(ContainerHolder.shared.container)

    // Analyze FoodItemLog images
    if let foodLogCategory = await analyzeFoodItemLogs(modelContext: modelContext) {
      results.append(foodLogCategory)
    }

    // Analyze MealRecord images
    if let mealCategory = await analyzeMealRecords(modelContext: modelContext) {
      results.append(mealCategory)
    }

    // Analyze ChatMessage images
    if let chatCategory = await analyzeChatMessages(modelContext: modelContext) {
      results.append(chatCategory)
    }

    // Analyze FoodItemRecord data
    if let foodItemCategory = await analyzeFoodItemRecords(modelContext: modelContext) {
      results.append(foodItemCategory)
    }

    // Analyze Workout data
    if let workoutCategory = await analyzeWorkoutData(modelContext: modelContext) {
      results.append(workoutCategory)
    }

    // Analyze file system
    if let dbCategory = analyzeSwiftDataFiles() {
      results.append(dbCategory)
    }

    if let cacheCategory = analyzeCacheDirectory() {
      results.append(cacheCategory)
    }

    if let documentsCategory = analyzeDocumentsDirectory() {
      results.append(documentsCategory)
    }

    if let tempCategory = analyzeTemporaryDirectory() {
      results.append(tempCategory)
    }

    // Sort by size descending
    results.sort { $0.size > $1.size }

    self.categories = results
    self.totalStorageSize = results.reduce(0) { $0 + $1.size }
  }

  private func analyzeFoodItemLogs(modelContext: ModelContext) async -> StorageCategory? {
    do {
      let descriptor = FetchDescriptor<FoodItemLog>()
      let logs = try modelContext.fetch(descriptor)

      var totalSize: Int64 = 0
      var imagesWithData = 0
      var totalImages = 0
      var maxImageSize: Int64 = 0

      for log in logs {
        if let imageData = log.imageData {
          let imageSize = Int64(imageData.count)
          totalSize += imageSize
          imagesWithData += 1
          maxImageSize = max(maxImageSize, imageSize)
        }
        totalImages += 1
      }

      let avgSizeKB = imagesWithData > 0 ? (totalSize / Int64(imagesWithData)) / 1024 : 0
      let maxSizeKB = maxImageSize / 1024

      return StorageCategory(
        name: "Food Log Images",
        size: totalSize,
        itemCount: totalImages,
        details: "\(imagesWithData) images, avg \(avgSizeKB)KB, max \(maxSizeKB)KB"
      )
    } catch {
      print("Error analyzing food logs: \(error)")
      return nil
    }
  }

  private func analyzeMealRecords(modelContext: ModelContext) async -> StorageCategory? {
    do {
      let descriptor = FetchDescriptor<MealRecord>()
      let meals = try modelContext.fetch(descriptor)

      var totalSize: Int64 = 0
      var imagesWithData = 0
      var totalMeals = 0
      var maxImageSize: Int64 = 0

      for meal in meals {
        if let imageData = meal.imageData {
          let imageSize = Int64(imageData.count)
          totalSize += imageSize
          imagesWithData += 1
          maxImageSize = max(maxImageSize, imageSize)
        }
        totalMeals += 1
      }

      let avgSizeKB = imagesWithData > 0 ? (totalSize / Int64(imagesWithData)) / 1024 : 0
      let maxSizeKB = maxImageSize / 1024

      return StorageCategory(
        name: "Meal Images",
        size: totalSize,
        itemCount: totalMeals,
        details: "\(imagesWithData) images, avg \(avgSizeKB)KB, max \(maxSizeKB)KB"
      )
    } catch {
      print("Error analyzing meals: \(error)")
      return nil
    }
  }

  private func analyzeChatMessages(modelContext: ModelContext) async -> StorageCategory? {
    do {
      let descriptor = FetchDescriptor<ChatMessage>()
      let messages = try modelContext.fetch(descriptor)

      var totalImageSize: Int64 = 0
      var totalTextSize: Int64 = 0
      var imagesWithData = 0
      var totalMessages = messages.count
      var maxImageSize: Int64 = 0

      for message in messages {
        if let imageData = message.imageData {
          let imageSize = Int64(imageData.count)
          totalImageSize += imageSize
          imagesWithData += 1
          maxImageSize = max(maxImageSize, imageSize)
        }
        // Estimate text size (rough approximation)
        totalTextSize += Int64(message.message?.count ?? 0) * 2 // 2 bytes per character
      }

      let totalSize = totalImageSize + totalTextSize
      let avgImageSizeKB = imagesWithData > 0 ? (totalImageSize / Int64(imagesWithData)) / 1024 : 0
      let maxImageSizeKB = maxImageSize / 1024

      return StorageCategory(
        name: "Chat Messages",
        size: totalSize,
        itemCount: totalMessages,
        details: "\(imagesWithData) images, avg \(avgImageSizeKB)KB, max \(maxImageSizeKB)KB"
      )
    } catch {
      print("Error analyzing chat messages: \(error)")
      return nil
    }
  }

  private func analyzeFoodItemRecords(modelContext: ModelContext) async -> StorageCategory? {
    do {
      let descriptor = FetchDescriptor<FoodItemRecord>()
      let items = try modelContext.fetch(descriptor)

      // Estimate average size per food item (nutrition data, strings, etc.)
      let estimatedSizePerItem: Int64 = 2048 // 2KB per item (rough estimate)
      let totalSize = Int64(items.count) * estimatedSizePerItem

      return StorageCategory(
        name: "Food Database",
        size: totalSize,
        itemCount: items.count,
        details: "\(items.count) food items"
      )
    } catch {
      print("Error analyzing food items: \(error)")
      return nil
    }
  }

  private func analyzeWorkoutData(modelContext: ModelContext) async -> StorageCategory? {
    do {
      let planDescriptor = FetchDescriptor<WorkoutPlan>()
      let plans = try modelContext.fetch(planDescriptor)

      let exerciseDescriptor = FetchDescriptor<WorkoutExercise>()
      let exercises = try modelContext.fetch(exerciseDescriptor)

      let setDescriptor = FetchDescriptor<WorkoutSet>()
      let sets = try modelContext.fetch(setDescriptor)

      // Rough estimates for data size
      let plansSize = Int64(plans.count) * 1024 // 1KB per plan
      let exercisesSize = Int64(exercises.count) * 512 // 512B per exercise
      let setsSize = Int64(sets.count) * 256 // 256B per set

      let totalSize = plansSize + exercisesSize + setsSize
      let totalCount = plans.count + exercises.count + sets.count

      return StorageCategory(
        name: "Workout Data",
        size: totalSize,
        itemCount: totalCount,
        details: "\(plans.count) plans, \(exercises.count) exercises, \(sets.count) sets"
      )
    } catch {
      print("Error analyzing workout data: \(error)")
      return nil
    }
  }

  private func analyzeSwiftDataFiles() -> StorageCategory? {
    guard let containerURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else {
      return nil
    }

    let dataURL = containerURL.appendingPathComponent("Application Support")
    let size = directorySize(at: dataURL)

    return StorageCategory(
      name: "Database Files",
      size: size,
      itemCount: 0,
      details: "SwiftData/CoreData storage"
    )
  }

  private func analyzeCacheDirectory() -> StorageCategory? {
    guard let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
      return nil
    }

    let size = directorySize(at: cacheURL)

    return StorageCategory(
      name: "Cache",
      size: size,
      itemCount: 0,
      details: "Temporary cached data"
    )
  }

  private func analyzeDocumentsDirectory() -> StorageCategory? {
    guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      return nil
    }

    let size = directorySize(at: documentsURL)

    return StorageCategory(
      name: "Documents",
      size: size,
      itemCount: 0,
      details: "User documents"
    )
  }

  private func analyzeTemporaryDirectory() -> StorageCategory? {
    let tempURL = FileManager.default.temporaryDirectory
    let size = directorySize(at: tempURL)

    return StorageCategory(
      name: "Temporary Files",
      size: size,
      itemCount: 0,
      details: "Temporary data"
    )
  }

  private func directorySize(at url: URL) -> Int64 {
    var size: Int64 = 0

    let fileManager = FileManager.default
    let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey])

    while let fileURL = enumerator?.nextObject() as? URL {
      do {
        let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
        size += Int64(resourceValues.fileSize ?? 0)
      } catch {
        continue
      }
    }

    return size
  }
}

extension StorageCategory {
  var sizeFormatted: String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: size)
  }

  func percentage(of totalSize: Int64) -> Double {
    guard totalSize > 0 else { return 0 }
    return Double(size) / Double(totalSize) * 100
  }
}
